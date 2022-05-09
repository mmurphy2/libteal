#!/usr/bin/awk
#
# wget progress line parser
#
# Depends on functions from update_progress.awk.
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


/^Length:/ {
    total = $2
    next
}

(NF == 3) {
    sub("%", "", $2)
    transferred = to_bytes($1)
    percent = $2
    count = split($3, pieces, "=")
    if (count == 2) {
        time = to_seconds(pieces[2])
        if (total > 0) {
            speed = total / time
        }
    }
}

(NF == 4) {
    sub("%", "", $2)
    transferred = to_bytes($1)
    percent = $2
    # wget log output displays speeds with base units of bits
    speed = to_bytes($3 / 8)
    remain = to_seconds($4)
}
