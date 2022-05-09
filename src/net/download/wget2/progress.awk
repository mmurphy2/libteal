#!/usr/bin/awk
#
# wget2 progress line parser
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


(NF == 5) {
    sub("%", "", $1)
    percent = $1
    transferred = to_bytes($4)
    speed = to_bytes($5)

    # We have to calculate the total and estimate time remaining, since wget2 doesn't provide this output
    if (percent + 0 < 1) {
        # We just have a rough guess at the start of the process
        if (transferred + 0 > 0) {
            total = 100 * transferred
        }
    }
    else {
        # At 100%, don't update the total. We will get the definitive transfer total from the statistics file
        # in the download wrapper.
        if (percent + 0 < 100) {
            total = transferred / (percent / 100)
        }
    }

    # Transfer time, assuming we have a total, can be calculated
    if (total + 0 > transferred + 0 && speed + 0 > 0) {
        remain = (total - transferred) / speed
    }
}
