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
    result = -1

    count = split(time, parts, ":")
    if (count == 3) {
        if (parts[1] == "--") {
            result = 0
        }
        else {
            result = 3600*parts[1] + 60*parts[2] + parts[3]
        }
    }

    return result
}


BEGIN {
    if (percent_file == "") {
        percent_file = "/tmp/percent"
    }
    if (remain_file == "") {
        remain_file = "/tmp/remain"
    }
    if (speed_file == "") {
        speed_file = "/tmp/speed"
    }
    if (total_file == "") {
        total_file = "/tmp/total"
    }
}


END {
    if (percent != "") {
        printf("%d\n", percent) > percent_file
    }
    if (remain != "") {
        printf("%d\n", remain) > remain_file
    }
    if (total != "") {
        printf("%d\n", total) > total_file
    }
    if (speed != "") {
        printf("%f\n", speed) > speed_file
    }
}
