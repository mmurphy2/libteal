#!/bin/sh
#
# Converts between integer byte sizes and human-readable sizes. Only shell
# integer arithmetic is used, so the sizes are merely ballpark approximations.
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

usage() {
    cat << EOF
$0 <size_expression>

Converts between rough integer sizes and human-readable sizes. Only shell
integer arithmetic is used, so the sizes are ballpark approximations.

If the incoming size expression contains a recognized unit, the output will
be plain number of bytes without a unit. If the input is a plain number, the
output will be a human-readable value with a unit. Powers of two are used for
the conversions.

Recognized units are B, o, k, K, KB, KiB, Ko, Kio, m, M, MB, MiB, g, G, GB,
GiB, Go, Gio, t, T, TB, TiB, To, and Tio. Output units are B, KiB, MiB, GiB,
and TiB.
EOF
}


if [ $# -ne 1 ]; then
    echo "Usage: $0 <size_expression>"
    exit 2
fi

case "$1" in
    -h|--help)
        usage
        exit 0
    ;;
esac


unit_part=$(echo "$1" | sed 's/[0-9]*//g' | sed 's/ //g')

status=0

if [ -z "${unit_part}" ]; then
    number_part=$(echo "$1" | sed 's/ //g')
    if [ ${number_part} -lt 1024 ]; then
        echo "${number_part} B"
    elif [ ${number_part} -lt 1048576 ]; then
        echo "$(( number_part / 1024 )) KiB"
    elif [ ${number_part} -lt 1073741824 ]; then
        echo "$(( number_part / 1048576 )) MiB"
    elif [ ${number_part} -lt 1099511627776 ]; then
        echo "$(( number_part / 1073741824 )) GiB"
    else
        echo "$(( number_part / 1099511627776 )) TiB"
    fi
else
    number_part=$(echo "$1" | sed "s|${unit_part}||" | sed 's/ //g')
    case "${unit_part}" in
        B|o)
            echo ${number_part}
        ;;
        k|K|KB|KiB|Ko|Kio)
            echo $(( 1024 * number_part ))
        ;;
        m|M|MB|MiB|Mo|Mio)
            echo $(( 1048576 * number_part ))
        ;;
        g|G|GB|GiB|Go|Gio)
            echo $(( 1073741824 * number_part ))
        ;;
        t|T|TB|TiB|To|Tio)
            echo $(( 1099511627776 * number_part ))
        ;;
        *)
            echo "Unknown unit: ${unit_part}" >&2
            status=1
        ;;
    esac
fi
