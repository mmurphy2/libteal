#!/bin/sh
#
# Color printf, which supports background colors, foreground colors, and
# font effects using styles. Color and font support is disabled whenever the
# environment variable CPRINTF_DISABLE_COLOR is set.
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
$0 [options] <format> [[value] ...]
$0 [options] -e [[string] ...]

Options:
    -e | --echo
        Changes from printf mode to echo mode. Any arguments are displayed,
        followed by a newline.
    -h | --help
        Show this help message and exit.
    -s <style> | --style <style>
        Apply the given <style> to the output. If this option is omitted, the
        output will not have color or font effects.

This application prints text using color using the printf(1) or echo(1)
commands to produce the resulting output. Without the -e option, printf is
used; the -e option changes the backend to echo. Note that both printf and
echo are shell builtins, and those will normally be used.

To change the output color and font, a style must be specified with the -s
option. If the specified style name can be found in the STYLES environment
variable, the corresponding color and font effects will be applied.
Otherwise, no effects will be applied. All effects can be disabled by
setting CPRINTF_DISABLE_COLOR to any nonempty value. For information about
styles, see the libteal style command.
EOF
}


style=
use_echo=no


# Handle options
while [ $# -gt 0 ]; do
    case "$1" in
        -e|--echo)
            use_echo="yes"
            shift
        ;;
        -h|--help)
            usage
            exit 0
        ;;
        -s|--style)
            style="$2"
            shift 2
        ;;
        *)
            break
        ;;
    esac
done


# If color is enabled, set the colors and font
if [ -z "${CPRINTF_DISABLE_COLOR}" -a -n "${style}" -a -n "${STYLES}" ]; then
    # Look up the style
    line=$(echo "${STYLES}" | tr ';' '\n' | grep -m 1 "^${style} ")
    if [ -n "${line}" ]; then
        fg_color=$(echo "${line}" | awk '{print $2}')
        bg_color=$(echo "${line}" | awk '{print $3}')
        font=$(echo "${line}" | awk '{print $4}' | tr ',' ' ')

        tput op
        [ -n "${fg_color}" -a "${fg_color}" != "-" ] && tput setaf "${fg_color}"
        [ -n "${bg_color}" -a "${bg_color}" != "-" ] && tput setab "${bg_color}"
        for elt in ${font}; do
            if [ -n "${elt}" -a "${elt}" != "-" ]; then
                tput "${elt}"
            fi
        done
    else
        # Undefined style requested: do nothing
        style=
    fi
fi


if [ $# -gt 0 -a "${use_echo}" != "yes" ]; then
    printf "$@"
else
    echo "$@"
fi


# Clean up and reset the font and colors to defaults, to avoid surprises later
if [ -z "${CPRINTF_DISABLE_COLOR}" -a -n "${style}" -a -n "${STYLES}" ]; then
    tput op
    tput sgr0
fi
