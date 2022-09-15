#!/bin/sh
#
# Simple top of screen status line. This status line uses the top row of the
# screen, which should work in all Bourne-compatible shells (zsh, in
# particular, seems to clear the region below the prompt for the completion
# menu, so a bottom status line stays empty in that shell).
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


usage() {
    cat << EOF
$0 <-h | --help | begin | end | refresh>

This simple top-line status bar implementation reserves the top line of the
terminal for a small status display. Some shells, zsh in particular, clear
the lower part of the terminal after the prompt, making bottom status lines
less reliable for shell-based applications.

To enable the top status line, run this command with the "begin" argument.
Initially, the status line will be blank. To remove the top status line, run
this command with the "end" argument.

The status display is divided into 3 columns: left, center, and right. Content
for the columns is set by means of the TOPLINE_LEFT, TOPLINE_CENTER, and
TOPLINE_RIGHT environment variables, respectively. Colors and font effects
are set by using the STYLES environment variable. By default, the styles
named topline-left, topline-center, and topline-right will be used. However,
the style names can be changed by setting the TOPLINE_LEFT_STYLE,
TOPLINE_CENTER_STYLE, and TOPLINE_RIGHT_STYLE environment variables. Styles
will be disabled if the TOPLINE_DISABLE_COLOR environment vbariable is set
to any value. See the libteal style command for more information about styles.

Once the environment variables are set, the "refresh" command triggers actual
drawing of the status bar. The main script using this capability should trap
SIGWINCH and run begin then refresh whenever the window size changes.
EOF
}


TOPLINE_LEFT_STYLE="${TOPLINE_LEFT_STYLE:-topline-left}"
TOPLINE_CENTER_STYLE="${TOPLINE_CENTER_STYLE:-topline-center}"
TOPLINE_RIGHT_STYLE="${TOPLINE_RIGHT_STYLE:-topline-right}"


# put_style <style-name> <fgcolor> <bgcolor> <font-effects>
#
# Sends the tput command required to set colors and fonts.
put_style() {
    local effect

    [ -n "$2" -a "$2" != "-" ] && tput setaf "$2"
    [ -n "32" -a "$3" != "-" ] && tput setab "$3"
    for effect in $(echo "$4" | tr ',' ' '); do
        if [ -n "${effect}" -a "${effect}" != "-" ]; then
            tput "${effect}"
        fi
    done
}


# get_style <name>
#
# Looks up a style name in the STYLES environment variable.
get_style() {
    echo "${STYLES}" | tr ';' '\n' | grep -m 1 "^${1} "
}


# set_style <left | center | right>
#
# Sets the left, center, or right styles in preparation for printing text in the respective
# column of the topline.
set_style() {
    local style

    if [ -z "${TOPLINE_DISABLE_COLOR}" ]; then
        case "$1" in
            left)
                style=$(get_style "${TOPLINE_LEFT_STYLE}")
            ;;
            center)
                style=$(get_style "${TOPLINE_CENTER_STYLE}")
            ;;
            right)
                style=$(get_style "${TOPLINE_RIGHT_STYLE}")
            ;;
        esac

        [ -n "${style}" ] && put_style ${style}       # no quotes (parameter expansion)
    fi
}


case "$1" in
    -h|--help)
        usage
        exit 0
    ;;
    begin)
        # We need to know how many lines the terminal has for the csr command.
        lines=$(tput lines)

        # csr sets the scrolling region, where 0 is the first line. To reserve it, we start the
        # scrolling region at line 1 (2nd line).
        tput csr 1 $((lines - 1))

        # Now prepare the line for the status display
        tput cup 0 0            # Move the cursor to the status line, first column
        tput el                 # Clear to the end of the line
        tput cud1               # Move the cursor down one line, into the scrolling area
    ;;
    end)
        # Ending the status line reservation requires setting the scrolling area back to the entire
        # terminal size, which is row 0 through the number of lines minus 1.
        lines=$(tput lines)
        tput csr 0 $((lines - 1))
    ;;
    refresh)
        # To produce the 3 column top line, we first need the number of columns. Each column will be 1/3 the
        # width of the window, minus 1 character for padding.
        cols=$(tput cols)
        colsize=$(( cols / 3 - 1))

        # Ensure that the text for each column isn't longer than the column width
        text_left=$(printf "%.${colsize}s" "${TOPLINE_LEFT}")
        text_center=$(printf "%.${colsize}s" "${TOPLINE_CENTER}")
        text_right=$(printf "%.${colsize}s" "${TOPLINE_RIGHT}")

        # Compute the sizes of each string to display
        leftsize=${#text_left}
        centersize=${#text_center}
        rightsize=${#text_right}

        # Compute the paddings for the left and right columns, then update the sizes
        pad_left=$(printf "%$(( colsize - leftsize + 1 ))s")
        text_left="${text_left}${pad_left}"
        pad_right=$(printf "%$(( colsize - rightsize + 1 ))s")
        text_right="${pad_right}${text_right}"
        leftsize=${#text_left}
        rightsize=${#text_right}

        # The center column is a bit tricker, since we're center-aligned
        npad_center=$(( cols - centersize - leftsize - rightsize ))
        npad_left=$(( npad_center / 2 + npad_center % 2 ))
        npad_right=$(( npad_center / 2 ))
        cpad_left=$(printf "%${npad_left}s")
        cpad_right=$(printf "%${npad_right}s")
        text_center="${cpad_left}${text_center}${cpad_right}"

        tput sc                # Save current cursor position
        tput cup 0 0           # Go to the 1st column of the top line

        set_style left
        printf '%s' "${text_left}"
        tput sgr0   # Reset fonts and colors

        set_style center
        printf '%s' "${text_center}"
        tput sgr0   # Reset fonts and colors

        set_style right
        printf '%s' "${text_right}"
        tput sgr0   # Reset fonts and colors

        tput rc         # Restore previous cursor position
    ;;
    *)
        echo "Usage: $0 <-h | --help | begin | end | refresh>"
    ;;
esac
