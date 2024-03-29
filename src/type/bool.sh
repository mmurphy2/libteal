#!/bin/sh
#
# Determines if a string represents a true or false value by comparing the
# string to keys used for "true" (including true, yes, on, enable, and 1).
# Optionally performs basic aggregation of multiple strings using and/or
# logic. Exits with a status of 0 for true, 1 for false.
#
# By default, "and" logic is used in the aggregation. However, this can be
# changed to "or" logic by passing the -o flag at the point where the
# change is requested. The -a flag changes the aggregation back to "and".
# Note that -a given as the first argument always produces a false result.
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

result=1
aggregate="and"

while [ $# -gt 0 ]; do
    value=$(echo "$1" | awk '{print tolower($0)}')
    shift

    case "${value}" in
        true|yes|on|enable|1)
            result=0
        ;;
        -a)
            aggregate="and"
            if [ ${result} -ne 0 ]; then
                # The other side of the explicit "and" is already false, so short-circuit
                break
            fi
        ;;
        -o)
            aggregate="or"
            if [ ${result} -eq 0 ]; then
                # The other side of the "or" is already true, so we're done here
                break
            fi
        ;;
        *)
            result=1
        ;;
    esac
done

exit ${result}
