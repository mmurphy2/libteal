#!/usr/bin/awk
#
# Normalizes path components. Unlike realpath(1) and readlink(1), this code
# can handle initial special path components (such as ..), or traverse back
# to the first component, without inadvertently introducing the content of
# the local file system.
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

{
    # We're run with FS="/" (-F '/'), so $i refers to path component i. Start from 1.
    idx = 1
    result[1] = $1

    if ($1 == "") {
        # We had an absolute path rooted at /, so put / in as our first component
        result[1] = "/"
    }

    # Now for the rest of the components ($2 through $(NF)):
    for (i=2; i<=NF; i++) {
        if ($i == "..") {
            # To go "up" a directory with .., first determine if we're past the first element
            if (idx > 1) {
                # Beyond the first element, just delete the current result element and back up one
                result[idx] = ""
                idx = idx - 1
            }
            else {
                # At the first element, only delete the element if we didn't have an absolute path
                # rooted at /. In the file system, .. at / simply loops back to /
                if (result[1] != "/") {
                    result[1] = ""
                }
            }
        }
        # Just ignore . (since it adds nothing to the final path) and any duplicate slashes in the
        # middle of the path. A duplicate / causes $i to be an empty string.
        else if ($i != "" && $i != ".") {
            # Increment the current position counter and store this component.
            idx = idx + 1
            result[idx] = $i
        }
    }

    # Now that we've processed all the path components, build the resulting path as a string.
    build = ""
    for (i=1; i<=idx; i++) {
        if (i == 1) {
            # At result[1], do not put either a leading or trailing slash
            build = result[1]
        }
        else {
            if (build != "/") {
                # Join the existing string and the current result with a slash
                build = build "/" result[i]
            }
            else {
                # In the special case where we have an absolute path rooted at /, the second
                # element should not be joined with an extra slash, since two slashes (//) would
                # result. A normalized path shouldn't have double slashes in it.
                build = build result[i]
            }
        }
    }

    print build
}
