#!/bin/sh
#
# Parses a time expression, producing the equivalent number of seconds.
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
#

usage() {
    cat << EOF
$0 <-h | --help | timespec>

Converts an expression of time into a number of seconds. The time expression
can be a literal number of seconds, or it can use the following time unit
values within the string:

y : years (365 days)
b : 30-day months
f : 14 days (fortnights)
w : 7 days (weeks)
d : days
h : hours
m : minutes
s : seconds

Examples:

1y 3d 4h 5m
1f 2d
42 y
EOF
}

whatami=$(readlink -e "$0")
whereami=$(dirname "${whatami}")

if [ $# -lt 1 ]; then
    echo "Usage: $0 <-h | --help | timespec>"
    exit 2
fi

case "$1" in
    -h|--help)
        usage
        exit 0
    ;;
    *)
        echo "$@" | sed 's/ //g' | \
            sed 's/y/:y:/g' | \
            sed 's/b/:b:/g' | \
            sed 's/f/:f:/g' | \
            sed 's/w/:w:/g' | \
            sed 's/d/:d:/g' | \
            sed 's/h/:h:/g' | \
            sed 's/m/:m:/g' | \
            sed 's/s/:s:/g' | \
            awk -f "${whereami}/parse_time.awk"
    ;;
esac
