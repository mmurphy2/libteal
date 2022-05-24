#!/usr/bin/awk
#
# Normalizes and cleans path components. Unlike realpath(1) and readlink(1),
# this code can handle initial special path components (such as ..), or
# traverse back to the first component, without inadvertently introducing the
# content of the local file system. All resulting paths are sanitized to make
# them relative to a hypothetical working directory.
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


# cleanpath(path)
#
# Normalizes and cleans the given input path, returning a *relative* path from a hypothetical
# starting directory, with leading and trailing slashes, and all internal . and .. path
# components, removed.
function cleanpath(path,  _build, _i, _idx, _count, _pieces, _result) {
    _count = split(path, _pieces, "/")
    _idx = 0

    # Any leading piece that isn't "." or ".." is kept as the first part of the path. If an
    # absolute path was given, then the leading piece is empty and is dropped.
    if (_pieces[1] != "" && _pieces[1] != "." && _pieces[1] != "..") {
        _result[1] = _pieces[1]
        _idx = 1
    }

    for (_i=2; _i<=_count; _i++) {
        if (_pieces[_i] == "..") {
            # To go "up" a directory with .., delete the element at the current index
            delete _result[_idx]
            _idx--
            if (_idx < 0) {
                _idx = 0
            }
        }
        # Just ignore . (since it adds nothing to the final path) and any duplicate slashes in the
        # middle of the path. A duplicate / causes the current piece to be an empty string.
        else if (_pieces[_i] != "" && _pieces[_i] != ".") {
            # Increment the current position counter and store this component.
            _idx = _idx + 1
            _result[_idx] = _pieces[_i]
        }
    }

    # Now that we've processed all the path components, build the resulting path as a string.
    _build = ""
    for (_i=1; _i<=_idx; _i++) {
        if (_i == 1) {
            # At _result[1], do not put either a leading or trailing slash
            _build = _result[1]
        }
        else {
            _build = _build "/" _result[_i]
        }
    }

    return _build
}
