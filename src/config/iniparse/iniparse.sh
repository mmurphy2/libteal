#!/bin/sh
#
# Configuration file handler that supports a dialect of INI format.
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


usage() {
    cat << EOF
$0 [options] [[ini_file] ...]

Options:
    -c <string> | --comments <string>
    -d <string> | --delimiters <string>
    -H | --long-help
    -h | --help
    -i | --no-interpolation
    -m <string> | --parameterized-sections <string>
    -o <directory> | --output <directory>
    -s <char> | --replace-slashes <char>
    -t | --dotted-output
    -u | --no-underscores
    -v | --verbose
    -x | --index

For more information, run $0 -H
EOF
}


details() {
    cat << EOF
SYNOPSIS
--------
    $0 [options] [[ini_file] ...]


DESCRIPTION
-----------
This program parses an INI file and writes the results into an output
directory. Unless the -o option is given, a temporary directory is created.
The path to the output directory is printed on standard output. Input to this
command is taken from a list of INI files specified on the command line. If
no INI files are specified, then the configuration is read from standard
input. Any specified INI files are read in order from left to right, and
configuration settings in subsequent INI files override the values from
previous ones.

Within the output directory, files of the form k_<string> correspond to INI
configuration keys of the form <string> inside the configuration files. If
sections are used, then the output will be organized into a hierarchy of the
form s_<section>/k_<key>. A single level of output files in the form
s_<section>.k_<key> may be obtained by using the -t option. Section and key
names are mangled to remove slashes, which are substituted with dashes (or an
alternate character specified with the -s option).

Using default settings, this configuration parser will handle the majority of
INI files, complete with variable interpolation and support for environment
variables. Customization details and examples are provided below.


OPTIONS
-------
    -c <string> | --comments <string>
        Use custom comment symbols. By default, INI files support the # and ;
        characters to begin line comments. Custom single-character comment
        symbols may be used by specifying this option. Note that only line
        comments are supported, as inline comments in INI files quickly
        become messy when parsing.
    -d <string> | --delimiters <string>
        Use custom delimiters between keys and values. By default, the
        delimiter setting is "=:", which allows equals signs and colons to be
        used. However, custom single-character delimiters can be used instead
        by setting this option to a custom value.
    -H | --long-help
        Show this help message using a pager, then exit.
    -h | --help
        Show a quick summary of options.
    -i | --no-interpolation
        Disable variable interpolation.
    -m <string> | --parameterized-sections <string>
        Enable section parameterization. Section parameterization facilitates
        the use of sections of the form [base param], with a space or tab
        character separating the base from the param. With parameterization
        enabled, the resulting output section will separate the base and
        param components with the specified <string>.
    -o <directory> | --output <directory>
        Use <directory> for output instead of creating one with mktemp(1).
        NOTE: The <directory> must already exist.
    -s <string> | --replace-slashes <string>
        Replace slashes in section and key names with <string>. Default: "-"
    -t | --dotted-output
        Instead of producing a hierarchical output, in which each section is
        a directory, produce a flat output with individual files named using
        sections and keys separated by dots.
    -u | --no-underscores
        Do not convert spaces to underscores in section and key names when
        producing the output files and directories.
    -v | --verbose
        Produce debugging output on standard error.
    -x | --index
        Write index files beginning with the prefix i_. These files contain
        two lines. The first line is the original section name, while the
        second line is the original key. Index files allow for the future
        possibility of recreating the INI file from the output.


INI FILE FORMAT
---------------
The supported dialect of INI supports full-line comments but not inline ones.
Line comments start with either # or ; by default. The comment symbols may
be adjusted with the -c option. Values must NOT be quoted but may contain
spaces. Multi-line values are supported if subsequent lines are indented at
least to the level of the start of the value in the first line (or one
position after the = if the first line is blank).

Custom comment characters can be specified using the -c option. If delimiters
other than = or : are used in a particular file, the -d option allows these
to be set.


VARIABLES
---------
Variable interpolation within the configuration system is supported using the
syntax \${key}, where key is another key in the configuration to be replaced
by a value wherever \${key} is used in a value. A key from another section
may be requested using the format \${section:key}. Otherwise, the key will
refer to another key within the same section as the variable; if no matching
key is present in that section, then a global (unsectioned) key will be used
if available. Unmatched variables are replaced with empty strings. Example:

---
global = This is a key outside a section

[a]
foo = 123
bar = \${foo}
; bar will have the value 123

[b]
baz = \${a:foo}
; baz will have the value 123
blah = \${global}
; blah will have the value "This is a key outside a section"
---

Although its practical utility is limited, indirect key lookups are also
supported. Thus, if a configuration contains:

---
[section]
foo = bar
baz = foo
also_bar = \${\${baz}}
---

then also_bar will contain the value "bar", which it reads from foo
indirectly by way of baz. Note that all interpolation can be disabled by
giving the -i option.

Environment variables may be referenced in the configuration by enclosing
the variable name in square brackets, like so:

---
home = ${[HOME]}
user = ${[USER]}
---

Support for variable interpolation may be disabled with the -i option.


SCRIPTING FEATURES
------------------
By default, spaces in section and key names are replaced with underscores.
This behavior can be disabled with the -u option. For some types of INI
file, sections of the form [base param] might be used with the intent of
parameterizing certain configuration values. Such sections will typically
have the output format s_base_param, which the space converted to an
underscore. However, the -m option enables a different character or string to
be substituted for the space. Note that underscore conversion and slash
replacement occurs after this substitution, so a different character needs to
be used to make this option effective.

Some scripts may want to recreate the INI file from the produced output. In
order to make the original (unmangled) section and key names available, index
files may be enabled with the -x option. For each key in the output directory,
there will be a corresponding file beginning with i_ (instead of k_). This
file will contain two lines: the first line will be the unmangled section
name, while the second line will be the original key name.


ENDNOTE
-------
Finally, it is worth noting the advantages of using an INI configuration
file as opposed to sourcing a configuration file made of shell code. First, a
configuration expressed in shell code that is sourced by the main script
becomes a potentially executable configuration, which does not enforce a
separation of mechanism and policy. Second, the INI format is a little
easier for most humans and read and write. This benefit is enhanced on Linux
systems, since many editors ship with syntax highlighting support for the INI
format already. With this script, one can produce a friendly user-facing INI
file, then process it into a directory hierarchy that is simple to use with
shell scripts.
EOF
}


self=$(readlink -e "$0")
whereami=$(dirname "${self}")
libteal_top=$(dirname "${whereami}")


output=
comments="#;"
delimiters="=:"
dotted=0
interpolation=1
parameterize=
slash_replace="-"
underscores=1
verbose=0
write_index=0

while [ $# -ne 0 ]; do
    case "$1" in
        -c|--comments)
            comments="$2"
            shift 2
        ;;
        -d|--delimiters)
            delimiters="$2"
            shift 2
        ;;
        -H|--long-help)
            details | "${PAGER:-less}"
            exit 0
        ;;
        -h|--help)
            usage
            exit 0
        ;;
        -i|--no-interpolation)
            interpolation=0
            shift
        ;;
        -m|--parameterized-sections)
            parameterize="$2"
            shift 2
        ;;
        -o|--output)
            output="$2"
            shift 2
        ;;
        -s|--slash-replace)
            slash_replace="$2"
            shift 2
        ;;
        -t|--dotted-output)
            dotted=1
            shift
        ;;
        -u|--no-underscores)
            underscores=0
            shift
        ;;
        -v|--verbose)
            verbose=1
            shift
        ;;
        -x|--index)
            write_index=1
            shift
        ;;
        *)
            break
        ;;
    esac
done


# Resolve the output location
if [ -n "${output}" ]; then
    if [ ! -d "${output}" ]; then
        echo "Output directory does not exist: ${output}" >&2
        exit 1
    fi
else
    output=$(mktemp -d)
fi

echo "${output}"


# Awk does the heavy lifting here
awk \
    -v comments="${comments}" \
    -v delimiters="${delimiters}" \
    -v dotted_output=${dotted} \
    -v interpolation=${interpolation} \
    -v parameterized_sections="${parameterize}" \
    -v underscores=${underscores} \
    -v output_directory="${output}" \
    -v slash_replace="${slash_replace}" \
    -v verbose=${verbose} \
    -v write_index=${write_index} \
    -f "${libteal_top}/path/cleanpath.awk" \
    -f "${whereami}/iniparse.awk" \
    -f "${whereami}/iniparse-output.awk" \
    "$@"
#
status=$?

rm -f "${preload_file}"

exit ${status}
