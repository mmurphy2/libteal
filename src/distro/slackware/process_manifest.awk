#!/usr/bin/awk
#
# AWK script to process the contents of a Slackware MANIFEST.bz2 file. Data
# from this file is appended to the individual package data files produced
# by the process_package_list.awk script.
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


# Begin by setting an output file control variable to the empty string
BEGIN {
    outfile = ""
}

# The entries in the MANIFEST.bz2 file are grouped by section. Section names begin with || followed by some
# whitespace, followed by Package:, followed by the relative path to the package file. Our output files are
# named according to the bare package name, so the first thing we need to do is strip off any leading path
# components. After that, we remove the file extension and set the output file control variable accordingly.
# Following the general convention used in the package database (/var/lib/pkgtools/packages), we list the
# filenames after a FILE LIST: header.
/^\|\| *Package:/ {
    sub(/.*\//, "", $3)
    sub(/\.t[a-z]z$/, "", $3)
    outfile = $3
    print "FILE LIST:" > outfile
}

# Entries in the manifest are separated by blank lines, so turn off the output file when seeing one.
/^$/ {
    outfile = ""
}

# There is some extra cruft around the manifest header. All file entries begin with the permissions in
# the format produced by ls -l, so matching lines that start with a letter or - should work. Again,
# following the package database convention, only the filenames are included in the output (field 6 of
# each file entry line).
/^([a-z]|-)/ {
    if (outfile != "") {
        print $6 > outfile
    }
}
