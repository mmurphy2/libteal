#!/usr/bin/awk
#
# AWK code to split a Slackware PACKAGES.TXT file into a set of files in an
# output directory. Each output file contains the lines of PACKAGES.TXT
# that correspond to the given package.
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


# This code is quite simple: begin by initializing an output file control variable to an empty string
BEGIN {
    pkgfile = ""
}

# Entries in PACKAGES.TXT begin with PACKAGE NAME: followed by a few spaces. When we see this line:
# 1. Remove the file extension (.t?z) from the end of the third field (the package filename).
# 2. Set the output file control variable to this value.
/^PACKAGE NAME: / {
    sub(/\.t[a-z]z/, "", $3)
    pkgfile = $3
}

# We may need to strip components from the PACKAGE LOCATION: entry. These components have to be stripped
# from the *front* of the path, so we can't just use dirname in the shell for this. The strip_prefix
# variable is set using the -v option when invoking awk with this script.
/^PACKAGE LOCATION: / {
    count = split($3, pieces, "/")
    final_path = ""
    for (i=strip_prefix + 1; i<=count; i++) {
        if (i == strip_prefix + 1) {
            final_path = pieces[i]
        }
        else {
            final_path = final_path "/" pieces[i]
        }
    }
    print "PACKAGE LOCATION: " final_path
    next
}

# Blank lines form the separator between package entries, so reset the output file control variable to empty.
/^$/ {
    pkgfile = ""
}

# AWK matches 3 the patterns in order. We didn't print the PACKAGE NAME: line in the first match block, but
# it will be printed by this block. Only send the line to the output file if the output control variable
# isn't empty. This check will preclude writing header data or blank lines to the output.
{
    if (pkgfile != "") {
        print $0 > pkgfile
    }
}
