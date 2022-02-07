#!/usr/bin/awk
#
# Splits Slackware package file stems into their component parts (package
# name, version, architecture, and tag). Produces output in a format
# suitable for use with a shell "eval" expression.
#
# Note: the stem is the basename of a package file with the .t?z removed.
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


# The field separator for package names is '-'
BEGIN {
    FS = "-"
}

/.*-.*-.*-.*/ {
    # The package name is everything except for the final 3 fields. The name
    # may contain dashes, so these need to be replaced between the fields that
    # comprise the name.
    name = ""
    sub(/.*\//, "", $1)   # strip off any leading path components from the name
    for (i=1; i<=NF-3; i++) {
        name = name $i
        if (i < NF-3) {
            name = name "-"
        }
    }

    sub(/\.t[a-z]z$/, "", $(NF))
    print name " " $(NF-2) " " $(NF-1) " " $(NF)
}
