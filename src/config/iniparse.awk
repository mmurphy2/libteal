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


BEGIN {
    have_error = 0
    section = ""
    indent = 0
    last_key = ""
}

/^[ \t]*$/ {
    # Skip blank lines
    next
}

/^[ \t]*[#;]/ {
    # Skip line comments
    next
}

/[ \t]*\[.*\]/ {
    # Handle section markers, with whitespace stripped at both ends. INI file sections and keys
    # are typically case-insensitive, so we use lowercase here.
    sub(/^[ \t]*/, "", $0)
    section = tolower(substr($0, 2, length($0) - 2))
    sub(/^[ \t]*/, "", section)
    next
}

/.*=.*/ {
    # On every line that contains a name = value pair, start by splitting the line into an array.
    # We need to know the number of splits, since a value could have an embedded = sign in it.
    num_splits = split($0, pieces, "=")

    if (num_splits >= 2) {
        # Strip leading and trailing whitespace off the leftmost piece (the name). Also strip any
        # leading whitespace off the second piece (the value), but leave any trailing whitespace for
        # now, since a value might intentionally have trailing whitespace or an embedded = after
        # trailing whitespace on the second piece.
        sub(/^[ \t]*/, "", pieces[1])
        sub(/[ \t]*$/, "", pieces[1])
        sub(/^[ \t]*/, "", pieces[2])

        # INI format is customarily case-insensitive, so store all keys in lowercase
        pieces[1] = tolower(pieces[1])

        # Clean up keys consisting only of "." or ".." (these cause issues later)
        if (pieces[1] == ".") {
            pieces[1] = "_"
        }
        else if (pieces[1] == ".." ) {
            pieces[1] = "__"
        }

        if (pieces[1] != "") {
            # There might be embedded = signs, resulting in more than two pieces. Reassemble the right hand
            # side of the variable assignment.
            value = pieces[2]
            if (num_splits > 2) {
                for (i=3; i<=num_splits; i++) {
                    value = value "=" pieces[i]
                }
            }

            # Compute the symbol table key
            this_key = section "/" pieces[1]
            if (section == "") {
                this_key = pieces[1]
            }

            # Perform any symbol table substitutions for this value, replacing variables
            # with values.
            if (index(value, "${")) {
                for (entry in symbol_table) {
                    if (entry != "") {
                        # Process local variables first, so that they mask global (unsectioned)
                        # variables.
                        if (index(entry, section) == 1) {
                            remainder = substr(entry, length(section) + 1)
                            sub(/^\//, "", remainder)

                            # Only consider symbols in this section and at this level. Any additional
                            # slashes in the remainder indicate the entry belongs to a subsection.
                            if (remainder != "" && index(remainder, "/") == 0) {
                                gsub("\\$\\{" remainder "\\}", symbol_table[entry], value)
                            }
                        }

                        # Take care of fully-qualified and global variables. A global variable
                        # has no leading section name, while a fully-qualified variable gives
                        # the path to the key in the form ${section/key}.
                        gsub("\\$\\{" entry "\\}", symbol_table[entry], value)
                    }
                }

                # If there are any leftover unmatched variables in the input, prune them.
                gsub(/\$\{.*\}/, "", value)
            }

            # Strip any trailing whitespace off the final value
            sub(/[ \t]*$/, "", value)

            # Add this value to the symbol table for later substitutions
            symbol_table[this_key] = value

            # Save the indent amount and current key (as last_key), in case we have a multiline value.
            # With such values, we want the indentation to line up with the first nonblank character
            # to the right of the "=" sign, or to the right of the = sign if blank
            indent = index($0, "=") + 1
            extra = match(substr($0, indent), /[^ \t]/)
            if (extra > 1) {
                indent += extra - 1
            }
            last_key = this_key
        }
        else {
            print FILENAME ": Syntax error at line " NR > "/dev/stderr"
            print "    > " $0 > "/dev/stderr"
            have_error = 1
        }
    }
    else {
        print FILENAME ": Syntax error at line " NR > "/dev/stderr"
        print "    > " $0 > "/dev/stderr"
        have_error = 1
    }

    next
}


{
    first_char = match($0, /[^ \t]/)
    if (indent > 0 && first_char >= indent && last_key != "") {
        # Multiline value: append it to the last saved result, but preserve internal indentation
        value = symbol_table[last_key] "\n" substr($0, indent)
        sub(/[ \t]*$/, value)
        symbol_table[last_key] = value
    }
    else {
        # Catch all: if none of the patterns match, we have a syntax error in the configuration
        # file. Note the location of the error. NB: /dev/stderr is defined for both gawk and
        # BusyBox awk.
        print FILENAME ": Syntax error at line " NR > "/dev/stderr"
        print "    > " $0 > "/dev/stderr"
        have_error = 1
    }
}
