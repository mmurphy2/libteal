#!/usr/bin/awk
#
# Produces an output directory hierarchy from a parsed INI configuration file.
#
# Depends on: path/cleanpath.awk
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

END {
    # Now we need to dump the symbol table out to a directory hierarchy in the current working
    # directory. This requires splitting the directory and file names from the qualified key names.
    # It also means sanitizing the output section and key names properly, so that we do not
    # produce any output outside the specified output_directory. Begin by producing a sanitized
    # symbol table and a list of directories that need to be created.
    for (entry in symbol_table) {
        clean_entry = cleanpath(entry)
        if (underscores) {
            gsub(/[ \t]/, "_", clean_entry)
        }

        num_cpts = split(clean_entry, cpts, "/")
        dirname = cpts[1]
        for (i=2; i<num_cpts; i++) {
            dirname = dirname "/" cpts[i]
        }

        if (num_cpts > 1) {
            create_directories[dirname] = 1
        }

        clean_table[clean_entry] = symbol_table[entry]
    }

    # Create the directory hierarchy first
    for (directory in create_directories) {
        system("mkdir -p '" output_directory "/" directory "'")
    }

    # Now write the values. Note that it is possible to have a conflict between a key name and a
    # section name inside the INI file. To work around this occurrence, we move the conflicting
    # key into the resulting section with the special name __value__.
    for (clean_entry in clean_table) {
        if (clean_entry in create_directories) {
            dest = output_directory "/" clean_entry "/__value__"
        }
        else {
            dest = output_directory "/" clean_entry
        }
        print clean_table[clean_entry] > dest
    }

    # Set failure exit code whenever an error is detected in the configuration file
    if (have_error == "yes") {
        exit 1
    }
}
