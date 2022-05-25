#!/usr/bin/awk
#
# AWK implementation for loading configuration files in INI format.
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


# Recursive resolver for variable interpolation. Supports both direct and indirect variable
# lookups (${foo} and ${${foo}}).
#
# Called using: resolve_symbols(value, this_section)
#
# where value is the right hand side of an assignment, while this_section is the name of
# the section in which the key=value assignment occurs. When resolving variables, unqualified
# variable names (those that do not contain a /) are first resolved using other keys from the
# same section. Global (unsectioned) keys are checked if no matching key exists in this section.
# An unresolved variable is replaced by an empty string.
#
function resolve_symbols(value, this_section,  _check, _endex, _index, _infix, _prefix, _result, _suffix) {
    _index = index(value, "${")

    if (_index) {
        # The prefix is everything to the left of the ${. Eventually, the infix will be the contents
        # of the variable, while the suffix will be everything to the right of the closing }. The
        # endex is the index of the next } (hence the pun).
        _prefix = substr(value, 1, _index - 1)
        _infix = substr(value, _index + 2)
        _endex = index(_infix, "}")

        # It is possible (though probably not that useful) for variables to be nested, allowing for
        # indirect references within the INI file. In this case, we need to make a recursive call to
        # process the nested variable. The endex needs to be recomputed once the infix has been
        # updated by the recursive call.
        _check = index(_infix, "${")
        if (_check > 0 && _check < _endex) {
            _infix = resolve_symbols(_infix)
            _endex = index(_infix, "}")
        }

        if (_endex) {
            # Separate the suffix from the infix using the position of the }
            _suffix = substr(_infix, _endex + 1)
            _infix = substr(_infix, 1, _endex - 1)

            # If the infix, which is now the variable name, contains a slash, we assume that it is
            # a fully-qualified reference to a key in a section. Look up and substitute directly. If
            # there is no match, replace the variable with an empty string.
            if (index(_infix, "/")) {
                if (_infix in symbol_table) {
                    _infix = symbol_table[_infix]
                }
                else {
                    _infix = ""
                }
            }
            else {
                # For a variable name that does not contain a slash, first look in the current
                # section to see if we have a key with the same name. If so, use that key. Otherwise,
                # see if a matching key exists at the global (unsectioned) level. Failing both lookups,
                # replace the variable with an empty string.
                if (this_section "/" _infix in symbol_table) {
                    _infix = symbol_table[this_section "/" _infix]
                }
                else {
                    if (_infix in symbol_table) {
                        _infix = symbol_table[_infix]
                    }
                    else {
                        _infix = ""
                    }
                }
            }

            # Recursively resolve any remaining variables in the suffix portion of the value. The
            # final result is then the prefix, infix, and suffix concatenated.
            _suffix = resolve_symbols(_suffix)
            _result = _prefix _infix _suffix
        }
        else {
            # endex was zero: no closing }. All we can do is try to save the prefix.
            print FILENAME ": Unterminated variable at line " NR > "/dev/stderr"
            _result = prefix
        }
    }
    else {
        # No variables, so return the original value unchanged
        _result = value
    }

    return _result
}


BEGIN {
    have_error = 0
    section = ""
    indent = 0
    last_key = ""

    # Permit custom comment symbols to be set. Only line comments are supported. For efficiency
    # later, we need the comment symbols to be the keys of the comment_array. However, the split
    # function will make them into the elements of the array instead. Thus, we split the comments
    # string into an intermediate array, from which we can then build the comment_array.
    if (comments == "") {
        comments = "#;"
    }
    split(comments, comment_intermediate, "")
    for (c in comment_intermediate) {
        comment_array[comment_intermediate[c]] = 1
    }

    # Custom delimiters (apart from = and :) may also be set.
    if (delimiters == "") {
        delimiters = "=:"
    }
    split(delimiters, delim_array, "")

    # Interpolation is on by default but can be disabled.
    if (interpolation == "") {
        interpolation = 1
    }
}

/^[ \t]*$/ {
    # Skip blank lines
    next
}

/[ \t]*\[.*\]/ {
    # Handle section markers, with whitespace stripped at both ends. INI file sections and keys
    # are typically case-insensitive, so we use lowercase here.
    sub(/^[ \t]*/, "", $0)
    section = tolower(substr($0, 2, length($0) - 2))
    sub(/^[ \t]*/, "", section)
    sub(/[ \t]*$/, "", section)

    # If section parameterization is enabled, replace the first space or tab in the section name
    # (if any) with a slash. This feature enables different sections to be grouped under a single
    # hierarchy in the output.
    if (parameterized_sections) {
        sub(/[ \t]/, "/", section)
    }

    next
}


# Everything else has enough edge cases to require manual handling
{
    first_char = match($0, /[^ \t]/)
    if (indent > 0 && first_char >= indent && last_key != "") {
        # Multiline value: append it to the last saved result, but preserve internal indentation
        value = symbol_table[last_key] "\n" substr($0, indent)
        sub(/[ \t]*$/, value)
        symbol_table[last_key] = value
    }
    else if (substr($0, first_char, 1) in comment_array) {
        next
    }
    else {
        # The key and value may be separated by any delimiter.
        for (d in delim_array) {
            division = index($0, delim_array[d])
            if (division > 0) {
                break
            }
        }

        if (division > 0) {
            # Split the key and value
            key = substr($0, 1, division - 1)
            value = substr($0, division + 1)

            # Strip leading and trailing whitespace off the key and value
            sub(/^[ \t]*/, "", key)
            sub(/[ \t]*$/, "", key)
            sub(/^[ \t]*/, "", value)
            sub(/[ \t\r\n]*$/, "", value)

            # INI format is customarily case-insensitive, so store all keys in lowercase
            key = tolower(key)

            # Clean up keys consisting only of "." or ".." (these cause issues later)
            if (key == ".") {
                key = "_"
            }
            else if (key == ".." ) {
                key = "__"
            }

            if (key != "") {
                # Prepend the section name, if it is set AND the key doesn't contain a slash. Strip any
                # leading slashes to make lookups consistent later.
                if (section != "" && index(key, "/") == 0) {
                    key = section "/" key
                }
                sub(/^\/+/, "", key)

                # It is possible for a key to contain slashes (and therefore define sections). For variable
                # substitution purposes, we need to get the effective section from the key itself.
                effective_section = key
                sub(/\/[^\/]*$/, "", effective_section)

                # Perform any symbol table substitutions for the value, replacing variables with the contents
                # of corresponding keys. This behavior can be disabled by setting interpolation to zero.
                if (interpolation) {
                    value = resolve_symbols(value, effective_section)
                }

                # Add this value to the symbol table for later substitutions
                symbol_table[key] = value

                # Save the indent amount and current key (as last_key), in case we have a multiline value.
                # With such values, we want the indentation to line up with the first nonblank character
                # to the right of the "=" sign, or to the right of the = sign if blank
                indent = division + 1
                extra = match(substr($0, indent), /[^ \t]/)
                if (extra > 1) {
                    indent += extra - 1
                }
                last_key = key
            }
            else {
                print FILENAME ": Syntax error: missing key at line " NR > "/dev/stderr"
                print "    > " $0 > "/dev/stderr"
                have_error = 1
            }
        }
        else {
            print FILENAME ": Syntax error at line " NR > "/dev/stderr"
            print "    > " $0 > "/dev/stderr"
            have_error = 1
        }
    }

    next
}
