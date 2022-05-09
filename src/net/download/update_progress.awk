#!/usr/bin/awk
#
# Common progress parser (used in conjunction with a backend parser)
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


function to_bytes(size) {
    table["K"] = 10
    table["M"] = 20
    table["G"] = 30
    table["T"] = 40
    result = ""

    if (size ~ /^[0-9\.]+$/) {
        result = size
    }
    else {
        suffix = size
        gsub(/[^0-9\.]/, "", size)
        sub(size, "", suffix)

        if (suffix in table) {
            result = size * 2^table[suffix]
        }
    }

    return result
}


function to_seconds(time) {
    result = 0

    count = split(time, parts, ":")
    if (count == 3) {
        # curl-style time
        if (parts[1] != "--") {
            result = 3600*parts[1] + 60*parts[2] + parts[3]
        }
    }
    else {
        # wget-style time
        num = ""

        split(time, pieces, //)
        for (key in pieces) {
            piece = pieces[key]
            if (match(piece, /[0-9]/)) {
                # Concatenate successive digits to rebuild numbers
                num = num piece
            }
            else {
                if (piece == "h") {
                    result += 3600 * num
                }
                else if (piece == "m") {
                    result += 60 * num
                }
                else if (piece == "s") {
                    result += num
                }
                num = ""
            }
        }

        if (num != "") {
            result += num
        }
    }

    return result
}


END {
    if (percent != "" && percent_file != "") {
        printf("%d\n", percent) > percent_file
    }
    if (remain != "" && remain_file != "") {
        printf("%d\n", remain) > remain_file
    }
    if (speed != "" && speed_file != "") {
        printf("%d\n", speed) > speed_file
    }
    if (total != "" && total_file != "") {
        printf("%d\n", total) > total_file
    }
    if (transferred != "" && transferred_file != "") {
        printf("%d\n", transferred) > transferred_file
    }
}
