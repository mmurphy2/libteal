#!/bin/sh
#
# Normalizes path components.
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
$0 <-h | --help>
$0 <path>
cmd | $0

Normalizes and cleans the path components, resolving . and .. to the extent
possible within the available path space. Note that this command works only
on virtual path data: no real file system paths are ever checked or used.
Thus, this command is suitable for use with path components of URLs.

Unlike realpath(1) or readlink(1), this command never makes any assumptions
about what lies before the first path component. Therefore, first path
components like .. can be safely used without introducing artifacts from the
local file system.

During the normalization process, the path is also cleaned to make it
relative to a hypothetical working directory. Any leading "/" from an
absolute path is removed, as are any trailing slashes. Internal "." and ".."
components are resolved to the extent possible in the given path space.
Leading "." or ".." components are simply removed. The resulting path is thus
designed so as not to be able to "escape" to a higher-level directory,
making it suitable for use with configuration parsers.

When cleaning a large number of paths, piping them into this command will
generally improve performance.
EOF
}


self=$(readlink -e "$0")
whereami=$(dirname "${self}")


case "$1" in
    -h|--help)
        usage
        exit 0
    ;;
esac


status=0

if [ $# -eq 0 ]; then
    cat | awk -f "${whereami}/cleanpath.awk" -e '{print cleanpath($0)}'
    status=$?
elif [ $# -eq 1 ]; then
    echo "$1" | awk -f "${whereami}/cleanpath.awk" -e '{print cleanpath($0)}'
    status=$?
else
    echo "Usage: $0 <-h | --help>"
    echo "       $0 <path>"
    echo "       cmd | $0"
    exit 2
fi
