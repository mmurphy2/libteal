#!/bin/sh
#
# Style table loading tool for cprintf and topline styles.
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
$0 [options] <style_file>

Options:
    -h | --help
        Show this help message and exit.
    -t | --template
        Display a style file template and exit.

This program simplifies color and font effect management for terminal programs
by providing a means to parse a simple style file that maps style names to
colors and font effects.

The intended way to incorporate this program into a script is:

STYLES=\$(style /path/to/stylefile)
export STYLES

This set of commands will parse the style file and load the resulting style
map into the STYLES environment variable. Programs that use the STYLES
environment variable will then be able to apply color and font effects
using human-readable style names.

To create a custom style file, use the -t option and redirect the output into
a file.
EOF
}

example_style() {
    cat << EOF
# Color name to code mapping. This default map provides names for 16 colors,
# but additional colors can be added for terminals with wider color support.
# See: https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
#
# The color "default" is reserved and indicates that no color change should
# be made.
#
############################################################################
# color-name                                                           value
############################################################################
black                                                                      0
red                                                                        1
green                                                                      2
yellow                                                                     3
blue                                                                       4
magenta                                                                    5
cyan                                                                       6
white                                                                      7
gray                                                                       8
grey                                                                       8
bright-red                                                                 9
bright-green                                                              10
bright-yellow                                                             11
bright-blue                                                               12
bright-magenta                                                            13
bright-cyan                                                               14
bright-white                                                              15


# Font map to tput arguments. See tput(1) and infocmp(1M). The effect
# named "default" is reserved and indicates that no change should be made
# to the font.
############################################################################
# font-effect                                                  tput sequence
############################################################################
bold                                                                    bold
dim                                                                      dim
faint                                                                    dim
standout                                                                smso
underline                                                               smul
blink                                                                  blink
reverse                                                                  rev
conceal                                                                invis


# Style names are mapped to colors by name and to fonts by a comma-separated
# list of font effects.
############################################################################
# name              fg                  bg                    font
############################################################################
header              bright-white        default               bold,underline
error               bright-red          default               bold
warning             bright-yellow       default               bold
notice              bright-white        default               default
highlight           black               yellow                default
EOF
}


self=$(readlink -e "$0")
whereami=$(dirname "${self}")


# Handle options
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
        ;;
        -t|--style-template)
            example_style
            exit 0
        ;;
        *)
            break
        ;;
    esac
done


if [ $# -ne 1 ]; then
    echo "Usage: $0 [options] <style_file>" >&2
    exit 2
fi

cat "$1" | awk -f "${whereami}/style.awk"
