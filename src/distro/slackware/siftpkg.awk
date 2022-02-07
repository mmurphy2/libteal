#!/usr/bin/awk
#
# Sifts through the package database and a totally priority-ordered list of
# package information directories to determine which packages are installed,
# available, and upgradable.
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
    # The installed packages are processed first and are indicated with an empty section string
    section = ""
}

/^=> / {
    # Listings for the different input directories are prefixed with => by the outer shell script. Set the
    # section name to the path to the repository data directory, and skip to the next record so we don't
    # try to process the => line.
    section = $2
    next
}

{
    if (section == "") {
        # The section variable is empty, so we're in the listing of the package database (installed packages).
        # The entry format is name -> version arch build
        pkgbase[$1] = $2 " " $3 " " $4
    }
    else {
        # We implement priorities using a simple approach: if we've already seen a package with the same name,
        # it is masked from further processing. This way, a package seen in the first repository masks a package
        # of the same name in all subsequent repositories.
        if (seen[$1] == "") {
            seen[$1] = "yes"

            # Referencing pkgbase[$1] causes it to come into existence here (with an empty string value)
            # if it does not already exist
            current_version = pkgbase[$1]

            if (current_version != "") {
                # If pkgbase[$1] (aka current_version) was previously set to a non-empty value, then a package
                # with the same name is already installed. Build a version string in the installed packages
                # format to check against the installed one, to see if we have an upgrade.
                this_version = $2 " " $3 " " $4

                if (this_version != current_version) {
                    # The repository version differs from the installed version, so we have an upgrade (which can
                    # technically be a downgrade, but that's how Slackware rolls). The format of upgrade entries is:
                    # name -> version arch build repository_path
                    upgrade[$1] = $2 " " $3 " " $4 " " section
                }
                else {
                    # We have this same version of this package installed locally: note the repository.
                    pkgbase[$1] = current_version " " section
                }
            }
            else {
                # current_version is empty, so pkgbase[$1] is unset. Therefore, the package is not installed, so
                # add it to the list of available packages. The format is name -> version arch build repository_path
                available[$1] = $2 " " $3 " " $4 " " section
            }
        }
    }
}

END {
    # All that remains is to print the contents of each of the arrays.

    for (ipkg in pkgbase) {
        # See note above regarding the creation of empty pkgbase entries
        if (pkgbase[ipkg] != "") {
            print "installed " ipkg " " pkgbase[ipkg]
        }
    }

    for (upkg in upgrade) {
        print "upgrade " upkg " " upgrade[upkg]
    }

    for (apkg in available) {
        print "available " apkg " " available[apkg]
    }
}
