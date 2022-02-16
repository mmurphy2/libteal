#!/usr/bin/awk
#
# Parser for command output from curl(1) and wget(1). This parser must be
# invoked with 4 variables set from the command line (with the -v option):
#
#     mode              One of: curl wget
#     percent           Path to percentage output file
#     remain            Path to time remaining output file
#     response          Path to response code output file
#
# The percentage output file will contain lines with an integer percentage
# completion value. As the download progresses, new lines are appended to
# the bottom of the file. The time remaining output file follows a similar
# format using integer numbers of seconds remaining. Finally, the response
# code output file contains the response code(s) associated with the
# request. In the case of directs, multiple response codes may be present.
#
# To retrieve the response code from a curl(1) request, add:
#
#    -w "RESPONSE: %{response_code}\n"
#
# to the curl command line.
#
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


# parse_time(timestr)
#
# Parses the curl/wget time string and returns the number of seconds represented by
# the time.
#
function parse_time(timestr,    count, pieces, seconds)
{
    if (mode == "wget") {
        # Remove the trailing "s" to avoid having an empty piece at the end
        sub(/s$/, "", timestr)
        count = split(timestr, pieces, /[hm]/)
    }
    else {
        count = split(timestr, pieces, ":")
    }

    seconds = pieces[count]
    if (count >= 2) {
        seconds += 60 * pieces[count - 1]
        if (count >= 3) {
            seconds += 3600 * pieces[count - 2]
        }
    }

    return seconds
}


BEGIN {
    # Check that all required externally set variables have been set.

    if (mode == "") {
        print "FATAL: Variable 'mode' was not set with -v" > "/dev/stderr"
        exit 2
    }

    if (percent == "") {
        print "FATAL: Variable 'percent' was not set with -v" > "/dev/stderr"
        exit 2
    }

    if (remain == "") {
        print "FATAL: Variable 'remain' was not set with -v" > "/dev/stderr"
        exit 2
    }

    if (response == "") {
        print "FATAL: Variable 'response' was not set with -v" > "/dev/stderr"
        exit 2
    }
}


/^HTTP request sent, awaiting response/ {
    if (mode == "wget") {
        print $6 > response
    }
}


/^RESPONSE: / {
    # By default, curl(1) doesn't display a response code. However, one can easily be added to
    # the output with the command line option: -w "RESPONSE: %{response_code}\n"
    if (mode == "curl") {
        print $2 > response
    }
}


/^[ \t]*[0-9]/ {
    if (mode == "curl") {
        print $3 > percent
        print parse_time($11) > remain
    }
}


/%/ {
    if (mode == "wget") {
        # The field containing the percentage value may vary, depending on how many dots were
        # printed on the line.
        for (i=1; i<=NF; i++) {
            if ($i ~ /%$/) {
                sub(/%$/, "", $i)
                print $i > percent
                print parse_time($(i + 2)) > remain
            }
        }
    }
}
