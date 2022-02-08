#!/usr/bin/awk
#
# AWK implementation for loading configuration files in INI format. Produces
# a hierarchical output directory containing the same information as the INI
# file. If the underscores variable is set to a true value (passed with -v
# on the command line), spaces are converted to underscores in produced
# directory and file names.
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
# filename
# VAR1=section/friendly name
# VAR2=section/friendly name
# (other preload lines)
# ---
# (verbatim configuration file data)


BEGIN {
    # Track the filename and the base line of the input data on which the configuration file
    # actually starts. This way, we can display useful error messages for configuration file issues.
    region = "preload"
    have_error = "no"
    filename = ""
    base_line = 0
    valid_section = 1
    section = ""
    indent = 0
    last_key = ""
}

(NR==1) {
    # Handle the filename line. We use the filename only for error messages.
    filename = $0

    if (filename == "-") {
        filename = "(stdin)"
    }

    next
}

/^[ \t]*$/ {
    # Skip blank lines
    next
}

/^[ \t]*[#;]/ {
    # Skip line comments
    next
}

/^---$/ {
    # Handle the region separator. Fall through if we aren't in the preload section to throw a syntax
    # error later.
    if (region == "preload") {
        region = "config"
        base_line = NR
        next
    }
}

/[ \t]*\[.*\]/ {
    # Handle section markers, with whitespace stripped at both ends. INI file sections and keys
    # are typically case-insensitive, so we use lowercase here.
    sub(/^[ \t]*/, "", $0)
    section = tolower(substr($0, 2, length($0) - 2))
    sub(/^[ \t]*/, "", section)
    sub(/[ \t]*/, "", section)

    # Sections with embedded slashes allow for a hierarchy to be created. However, we must take care
    # to ensure that the resulting path can't escape the output directory. Disallow ".." as a path
    # component for this reason, and convert absolute paths to relative.
    count = split(section, pathparts, "/")
    section = ""

    # Assemble a sanitized section string. At the end of the process, we should have a section that
    # contains no .. entries.
    valid_section = 1
    for (i=1; i<=count; i++) {
        if (pathparts[i] == "..") {
            print filename ": Illegal section name component (..) at line " (NR - base_line) > "/dev/stderr"
            print "    > " $0 > "/dev/stderr"
            have_error = "yes"
            section = ""
            valid_section = 0
            break
        }
        else if (pathparts[i] != "" && pathparts[i] != ".") {
            if (section == "") {
                section = pathparts[i]
            }
            else {
                section = section "/" pathparts[i]
            }
        }
    }

    last_key = ""
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

    # Check for illegal names, since these could create security issues
    if (pieces[1] == "..") {
        print filename ": Invalid key at line " (NR - base_line) > "/dev/stderr"
        print "    > " $0 > "/dev/stderr"
        have_error = "yes"
        last_key = ""
        next
    }

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
        # Add the preloaded value to the symbol table. These are stored mostly verbatim, but
        # disallow leading slashes.
        if (match(pieces[1], /^\//)) {
            print "Ignoring preload for key: " pieces[1] > "/dev/stderr"
            print "    Preload keys cannot begin with /" > "/dev/stderr"
            have_error = "yes"
        }
        else {
            symbol_table[pieces[1]] = value
        }
    }
    else {
        # Outside the preload region, keys cannot have slashes in them
        if (index(pieces[1], "/") > 0) {
            print filename ": Invalid key at line " (NR - base_line) > "/dev/stderr"
            print "    > " $0 > "/dev/stderr"
            have_error = "yes"
            last_key = ""
            next
        }
        if (valid_section) {
            this_key = section "/" pieces[1]
            if (section == "") {
                this_key = pieces[1]
            }

            # Perform any symbol table substitutions for this value, replacing variables
            # values.
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

            # Strip any trailing whitespace off the final value
            sub(/[ \t]*$/, "", value)

            # Add this value to the symbol table for later substitutions
            symbol_table[this_key] = value

            # Save the indent amount and last output file, in case we have a multiline value.
            # With such values, we want the indentation to line up with the first nonblank character
            # to the right of the "=" sign, or to the right of the = sign if blank
            indent = index($0, "=") + 1
            extra = match(substr($0, indent), /[^ \t]/)
            if (extra > 1) {
                indent += extra - 1
            }
            last_key = this_key
        }
    }
    next
}

{
    first_char = match($0, /[^ \t]/)
    if (section != "" && indent > 0 && first_char >= indent && last_key != "") {
        # Multiline value: append it to the last saved result, but preserve internal indentation
        value = symbol_table[last_key] "\n" substr($0, indent)
        sub(/[ \t]*$/, value)
        symbol_table[last_key] = value
    }
    else {
        # Catch all: if none of the patterns match, we have a syntax error in the configuration
        # file. Note the location of the error. NB: /dev/stderr is defined for both gawk and
        # BusyBox awk.
        print filename ": Syntax error at line " (NR - base_line) > "/dev/stderr"
        print "    > " $0 > "/dev/stderr"
        have_error = "yes"
    }
}

END {
    # Now we need to dump the symbol table out to a directory hierarchy in the current working
    # directory. This requires splitting the directory and file names from the qualified key names.
    for (entry in symbol_table) {
        num_cpts = split(entry, cpts, "/")

        basename = cpts[num_cpts]
        dirname = cpts[1]
        for (i=2; i<num_cpts; i++) {
            dirname = dirname "/" cpts[i]
        }

        if (underscores) {
            gsub(/[ \t]/, "_", basename)
            gsub(/[ \t]/, "_", dirname)
        }

        dest = basename
        if (num_cpts > 1) {
            # Ensure the output directory exists
            system("mkdir -p '" dirname "'")
            dest = dirname "/" basename
        }

        # Finally, write the file:
        print symbol_table[entry] > dest
    }

    # Set failure exit code whenever an error is detected in the configuration file
    if (have_error == "yes") {
        exit 1
    }
}
