#!/usr/bin/awk
#
# Parses a time expression
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

BEGIN {
    FS = ":"
}

{
    last = 0
    total = 0
    for (i=1; i<=NF; i++) {
        cmp = tolower($i)
        if (cmp == "y") {
            total += (365 * 86400 * last)
            last = 0
        }
        else if (cmp == "b") {
            total += (30 * 86400 * last)
            last = 0
        }
        else if (cmp == "f") {
            total += (14 * 86400 * last)
            last = 0
        }
        else if (cmp == "w") {
            total += (7 * 86400 * last)
            last = 0
        }
        else if (cmp== "d") {
            total += 86400 * last
            last = 0
        }
        else if (cmp == "h") {
            total += 3600 * last
            last = 0
        }
        else if (cmp == "m") {
            total += 60 * last
            last = 0
        }
        else if (cmp == "s") {
            total += last
            last = 0
        }
        else {
            last = $i
        }
    }
    total += last
    print total
}
