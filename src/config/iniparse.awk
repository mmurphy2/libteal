#!/usr/bin/awk
#
# AWK implementation for loading configuration files in INI format. Produces
# variable-setting Bourne shell code that can be evaluated in scripts.
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

# The wrapper script sends data to this program in the following format
#
# options line
# filename
# section.SYM1=value
# section.SYM2=value
# ---
# VAR1=section.friendly name
# VAR2=section.friendly name
# ---
# (verbatim configuration file data)

# Following the options line is the filename, followed by data with which to preload
# the symbol table for internal variable interpolation. After the symbol table comes a
# list of environment variables mapped to friendly variable names within the configuration
# file. We need to reverse this mapping in order to map the environment variables to
# configuration *values*. The configuration data file appears below the variables region.

BEGIN {
    # The top region of the input is for preloading data, and its first line supplies
    # options. Set the default options here, and provide for a way to track the filename
    # and the base line of the input data on which the configuration file actually starts.
    # This way, we can display useful error messages for configuration file issues.
    region = "preload"
    export = "on"
    unknown_key = "ignore"
    have_error = "no"
    filename = ""
    base_line = 0
    section = ""
    indent = 0
    latest_index = ""
}

(NR==1) {
    # Handle the options line, which is line number 1. Options are whitespace-separated on this line.
    for (i=1; i<=NF; i++) {
        if ($i == "noexport") {
            export = "off"
        }
        else if ($i == "errunmapped") {
            unknown_key = "error"
        }
    }
    next
}

(NR==2) {
    # Handle the filename line. We use the filename only for error messages.
    filename = $0

    if (filename == "-") {
        filename = "(stdin)"
    }

    next
}

/^$/ {
    # Skip blank lines
    next
}

/^[ \t]*[#;]/ {
    # Skip line comments
    next
}

/^---$/ {
    # Handle the region separator
    if (region == "preload") {
        region = "variables"
    }
    else if (region == "variables") {
        region = "config"
        base_line = NR
    }
    next
}

/[ \t]*\[.*\]/ {
    # Handle section markers, with whitespace stripped at both ends. INI file sections and keys
    # are typically case-insensitive, so we use lowercase here.
    sub(/^[ \t]*/, "", $0)
    section = tolower(substr($0, 2, length($0) - 2))
    sub(/^[ \t]*/, "", section)
    sub(/[ \t]*/, "", section)
    next
}

/.*=.*/ {
    # On every line that contains a name = value pair, start by splitting the line into an array.
    # We need to know the number of splits, since a value could have an embedded = sign in it.
    num_splits = split($0, pieces, "=")

    # Strip leading and trailing whitespace off the leftmost piece (the name). Also strip any
    # leading whitespace off the second piece (the value), but leave any trailing whitespace for
    # now, since a value might intentionally have trailing whitespace or an embedded = after
    # trailing whitespace on the second piece.
    sub(/^[ \t]*/, "", pieces[1])
    sub(/[ \t]*$/, "", pieces[1])
    sub(/^[ \t]*/, "", pieces[2])

    if (region == "variables") {
        # In the variables region, there can only be two pieces. The outer shell script
        # "should" ensure this is the case, but wise to check anyway.
        if (num_splits == 2) {
            # Strip any trailing whitespace from the second piece, then store the entry in the
            # environment variables (evars) map. Notice that evars maps the friendly name to
            # the final environment variable name. We need the mapping to go in this direction
            # so that the configuration value can be mapped to the proper environment variable
            # later.
            sub(/[ \t]*$/, "", pieces[2])
            pieces[2] = tolower(pieces[2])
            evars[pieces[2]] = pieces[1]

            # If we have a preloaded value for this variable, go ahead and set it in result
            if (symbol_table[pieces[2]] != "") {
                result[pieces[1]] = symbol_table[pieces[2]]
            }
        }
        else {
            print "Invalid input at data line " NR > "/dev/stderr"
            print "> " $0 > "/dev/stderr"
            print "-- This is a bug in the wrapper script, not the configuration file!" > "/dev/stderr"
            have_error = "yes"
        }
    }
    else if (region == "preload" || region == "config") {
        # In the preload (top) and config (bottom) regions, there might be embedded = signs,
        # resulting in more pieces. Reassemble the right hand side of the variable assignment.
        pieces[1] = tolower(pieces[1])
        value = pieces[2]
        if (num_splits > 2) {
            for (i=3; i<=num_splits; i++) {
                value = value "=" pieces[i]
            }
        }

        if (region == "preload") {
            # Add the preloaded value to the symbol table.
            symbol_table[pieces[1]] = value
        }
        else {
            full_key = section "." pieces[1]
            if (evars[full_key] != "") {
                # Perform any symbol table substitutions for this value, replacing variables
                # values.
                for (entry in symbol_table) {
                    if (entry != "") {
                        gsub("\\$\\{" entry "\\}", symbol_table[entry], value)
                    }
                }

                # If there are any leftover unmatched variables in the input, prune them.
                gsub(/\$\{.*\}/, "", value)

                # Strip any trailing whitespace off the final value
                sub(/[ \t]*$/, "", value)

                # Add this value to the symbol table for later substitutions
                symbol_table[full_key] = value

                # Now store the value in the result array. Note that the keys of the result
                # array are the environment variables, which are obtained by looking up the
                # sectioned friendly name (full_key) in the evars array.
                result[evars[full_key]] = value

                # Save the indent amount and index (key) of the result array, in case we have a
                # multiline value. With such values, we want the indentation to line up with the
                # first nonblank character to the right of the "=" sign, or to the right of the
                # = sign if blank
                indent = index($0, "=") + 1
                extra = match(substr($0, indent), /[^ \t]/)
                if (extra > 1) {
                    indent += extra - 1
                }
                last_index = evars[full_key]
            }
            else {
                # By default, ignore configuration keys that are not mapped. An option may be set to
                # change this behavior and make them into an error.
                if (unknown_key == "error") {
                    print filename ": in section [" section "]:" > "/dev/stderr"
                    print "    Unknown key '" pieces[1] "' at line " (NR - base_line) > "/dev/stderr"
                    have_error = "yes"
                }
            }
        }
    }
    next
}

{
    first_char = match($0, /[^ \t]/)
    if (indent > 0 && first_char >= indent) {
        # Multiline value: append it to the last saved result, but preserve internal indentation
        value = substr($0, indent)
        sub(/[ \t]*$/, value)
        result[last_index] = result[last_index] "\n" value
    }
    else {
        # Catch all: if none of the patterns match, we have a syntax error in the configuration
        # file. Note the location of the error. NB: /dev/stderr is defined for both gawk and
        # BusyBox awk.
        print filename ": Syntax error at line " (NR - base_line) > "/dev/stderr"
        print "> " $0 > "/dev/stderr"
        have_error = "yes"
    }
}

END {
    # Output the environment variables in the format:
    #
    # VAR='value'; export VAR;
    #
    # The latter part (export VAR;) is omitted if exports are off.
    #
    for (evar in result) {
        # Don't produce results for empty variables: outer shell code should handle this.
        if (result[evar] != "") {
            value = result[evar]
            printf "%s='%s';", evar, value
            if (export == "on") {
                print " export " evar ";"
            }
            else {
                print ""
            }
        }
    }

    # Set failure exit code whenever an error is detected in the configuration file
    if (have_error == "yes") {
        exit 1
    }
}
