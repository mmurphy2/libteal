#!/bin/sh
#
# Loads the non-commented lines of a list file, preserving the order of the
# list. Multiple list files may be concatenated.
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
$0 [options] <list_file> [[list_file] ...]

Options:
    -d <char> | --delimiter <char>
        Change the output delimiter from a newline to <char>. Note that
        <char> must be a single character or escape sequence that is
        valid as an argument to the tr(1) command.
    -h | --help
        Show this help message and exit.

This program loads a list of data from one or more list files. If multiple
list files are specified, they are read in order. The order of data within
each list file is also preserved.

List files may contain line comments that begin with #. Inline comments are
not supported. The resulting list read by this program will contain all
non-blank, non-comment lines, with leading and trailing whitespace removed.
EOF
}


self=$(readlink -e "$0")
whereami=$(dirname "${self}")


delim=

while [ $# -gt 0 ]; do
    case "$1" in
        -d|--delimiter)
            delim="$2"
            shift 2
        ;;
        -h|--help)
            usage
            exit 0
        ;;
        *)
            break
        ;;
    esac
done

if [ $# -lt 1 ]; then
    echo "Usage: $0 [options] <list_file> [[list_file] ...]"
    exit 2
fi

data=$(cat "$@" | awk -f "${whereami}/load_list.awk")
if [ -n "${delim}" ]; then
    data=$(echo "${data}" | tr '\n' "${delim}")
fi

[ -n "${data}" ] && echo "${data}"
