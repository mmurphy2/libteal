#!/usr/bin/awk
#
# Style table parser.
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
# IN THE SOFTWARE


# Skip comment lines
/^[ \t]*#/ {
    next
}


# Skip blank lines
/^[ \t]*$/ {
    next
}


{
    # If the line has 2 fields, it is either a color definition or a font effect definition.
    # Color definitions map names to numbers, while font effect definitions map names to
    # non-numeric strings.
    if (NF == 2) {
        if (match($2, /^[0-9]+$/)) {
            color_table[$1] = $2
        }
        else {
            font_table[$1] = $2
        }
    }

    # Lines with 4 fields are style definitions.
    else if (NF == 4) {
        fg_table[$1] = $2
        bg_table[$1] = $3
        effect_table[$1] = $4
    }
}


# Since the various sections of the style file can occur in any order, we have to read the whole
# file first, so that the color and font maps will be populated when we do the conversion from
# styles. The output of the conversion has the outer format: <definition>;[definition;][...]
# Each definition has the format <style-name> <fgcolor> <bgcolor> <font1>[,<font2>[,...[fontN]]].
END {
    for (style in fg_table) {
        fgcolor = color_table[fg_table[style]]
        if (fgcolor == "" || fg_color == "default") {
            fgcolor = "-"
        }

        bgcolor = color_table[bg_table[style]]
        if (bgcolor == "" || bg_color == "default") {
            bgcolor = "-"
        }

        # Each font effect has to be translated one at a time.
        num_effects = split(effect_table[style], effects, ",")
        for (i=1; i<=num_effects; i++) {
            this_effect = font_table[effects[i]]
            if (this_effect == "" || this_effect == "default") {
                fontset[i] = "-"
            }
            else {
                fontset[i] = this_effect
            }
        }

        # Rebuild the list of font effects using the terminal control commands.
        fonts = ""
        for (i=1; i<=num_effects; i++) {
            if (fonts == "") {
                fonts = fontset[i]
            }
            else {
                fonts = fonts "," fontset[i]
            }
        }

        printf "%s %s %s %s;", style, fgcolor, bgcolor, fonts
    }
    printf "\n"
}
