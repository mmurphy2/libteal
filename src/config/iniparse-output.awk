#!/usr/bin/awk
#
# Produces output directory from a parsed INI configuration file.
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
    # The default character for replacing "/" is "-"
    if (slash_replace == "") {
        slash_replace = "-"
    }
}


END {
    # Each entry in the symbol table needs to be written into the output_directory.
    for (entry in symbol_table) {
        # awk doesn't have real multidimensional arrays, so we have to separate the section and key
        # from the symbol table entry string.
        split(entry, st_parts, SUBSEP)
        raw_section = st_parts[1]
        raw_key = st_parts[2]

        # Make copies of the raw section and key, so that we can produce the index file later
        out_section = raw_section
        out_key = raw_key

        # If section parameterization is enabled, replace the first space or tab in the section name
        # (if any) with a custom string to make output parsing potentially easier.
        if (parameterized_sections) {
            sub(/[ \t]/, parameterized_sections, out_section)
        }

        # Replace spaces and tabs with underscores, if enabled
        if (underscores) {
            gsub(/[ \t]/, "_", out_section)
            gsub(/[ \t]/, "_", out_key)
        }

        # We must replace slashes to avoid a potential security risk resulting from path elements
        # in the section and key names.
        gsub("/", slash_replace, out_section)
        gsub("/", slash_replace, out_key)

        # To avoid a conflict between a key and a section that have the same name, prefix keys with k_
        # and sections with s_. Index files are prefixed with i_.
        dest = output_directory "/k_" out_key
        dest_index = output_directory "/i_" out_key
        if (out_section) {
            if (dotted_output) {
                dest = output_directory "/s_" out_section ".k_" out_key
                dest_index = output_directory "/s_" out_section ".i_" out_key
            }
            else {
                # When dotted output isn't used, we need to create the section directories inside
                # the output directory.
                system("mkdir -p '" output_directory "/s_" out_section "'")
                dest = output_directory "/s_" out_section "/k_" out_key
                dest_index = output_directory "/s_" out_section "/i_" out_key
            }
        }

        if (verbose) {
            print "Writing " raw_section ":" raw_key " to " dest > "/dev/stderr"
        }

        # Be sure that an empty value results in an empty file
        if (symbol_table[entry]) {
            print symbol_table[entry] > dest
        }
        else {
            printf "%s", "" > dest
        }

        # If requested, the index file contains the raw section and key names on separate lines; these
        # may be used by other code to recreate the original INI file.
        if (write_index) {
            printf "%s\n%s\n", raw_section, raw_key > dest_index
        }
    }

    # Set failure exit code whenever an error is detected in the configuration file
    if (have_error) {
        exit 1
    }
}
