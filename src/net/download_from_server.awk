#!/usr/bin/awk
#
# curl download progress parser
#
# Copyright 2022 Coastal Carolina University
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the “Software”), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.


function to_bytes(size,  _result, _suffix) {
    _result = ""

    # A bare number without a suffix is just a number of bytes
    if (size ~ /^[0-9\.]+$/) {
        _result = size
    }
    else {
        # Separate the numeric portion from the suffix
        _suffix = size
        gsub(/[^0-9\.]/, "", size)
        sub(size, "", _suffix)

        if (_suffix in table) {
            _result = size * 2^table[_suffix]
        }
    }

    return _result
}


function to_seconds(time,  _count, _parts, _result) {
    _result = 0

    # curl provides its time output in H:MM:SS format, but we store the result in raw seconds,
    # since it is easier to do computations on seconds (and simple to convert back later if needed)
    _count = split(time, _parts, ":")
    if (_count == 3) {
        if (_parts[1] != "--") {
            _result = 3600*_parts[1] + 60*_parts[2] + _parts[3]
        }
    }

    return _result
}


function write_stats() {
    percent_file = status_root "/" saved_xfer_number "/percent"
    remain_file = status_root "/" saved_xfer_number "/remain"
    speed_file = status_root "/" saved_xfer_number "/speed"
    total_file = status_root "/" saved_xfer_number "/total"
    transferred_file = status_root "/" saved_xfer_number "/transferred"

    if (percent != "") {
        printf("%d\n", percent) > percent_file
    }
    if (remain != "") {
        printf("%d\n", remain) > remain_file
    }
    if (speed != "") {
        printf("%d\n", speed) > speed_file
    }
    if (total != "") {
        printf("%d\n", total) > total_file
    }
    if (transferred != "") {
        printf("%d\n", transferred) > transferred_file
    }
}


BEGIN {
    # Mapping of prefixes to corresponding powers of two
    table["K"] = 10
    table["M"] = 20
    table["G"] = 30
    table["T"] = 40
    table["P"] = 50

    # We will start the transfer counters at -1 and let them get incremented to zero with the first header.
    xfer_number = -1
    saved_xfer_number = -1

    # Saved transfer number location
    xfer_number_file = status_root "/current_transfer"
}


# Matches the curl status line, which has 12 fields. The curl progress output looks like this:
#
#   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
#                                  Dload  Upload   Total   Spent    Left  Speed
# 100   672  100   672    0     0   6549      0 --:--:-- --:--:-- --:--:--  6588
#
# The header is distinguished from the data line by checking to see if the first field is a '%' sign.
#
(NF == 12) {
    if ($1 == "%") {
        # This is a header line: increment the transfer number.
        xfer_number++

        # Now get the saved transfer number from the current_transfer file. Close the file after
        # reading, so that we can update it with immediate effect if necessary.
        result = getline saved_xfer_number < xfer_number_file
        close(xfer_number_file)

        if (result <= 0) {
            # Treat a failure to open the file as evidence of no prior saved transfer number
            printf("%d\n", xfer_number) > xfer_number_file
            close(xfer_number_file)
            saved_xfer_number = xfer_number
        }
        else if (xfer_number > saved_xfer_number) {
            # If the current transfer number is greater than the previous one, first write any statistics
            # data from the previous transfer to the respective files. Then, increment the saved transfer
            # number.
            write_stats()
            printf("%d\n", xfer_number) > xfer_number_file
            close(xfer_number_file)
            saved_xfer_number = xfer_number
        }

        # Reset the data variables, since the header line indicates the end of the previous transfer data
        percent = ""
        remain = ""
        speed = ""
        total = ""
        transferred = ""
    }
    else {
        # We have a data line, but only update the statistics variables if the transfer numbers match. This
        # way, we avoid rewriting status files for completed transfers that were handled in a previous run
        # of this script. Information is only written to the files whenever the data variables are non-empty,
        # and they are reset to empty at each header line.
        if (xfer_number == saved_xfer_number) {
            total = to_bytes($2)
            percent = $3
            transferred = to_bytes($4)
            remain = to_seconds($11)
            speed = to_bytes($12)
        }
    }
}


END {
    # Write any remaining statistics data before exiting
    write_stats()
}
