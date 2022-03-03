#!/usr/bin/awk
#
# Parser for log data from wget(1). This parser supports 3 variables set
# from the command line (with the -v option):
#
#     percent           Path to percentage output file
#     remain            Path to time remaining output file
#     response          Path to response code output file
#
# The percentage output file will contain lines with an integer percentage
# completion value. As the download progresses, new lines are appended to
# the bottom of the file. The time remaining output file follows a similar
# format using integer numbers of seconds remaining. Finally, the response
# code output file contains the response code(s) associated with the
# request. In the case of directs, multiple response codes may be present.
#
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


# parse_time(timestr)
#
# Parses the curl/wget time string and returns the number of seconds represented by
# the time.
#
function parse_time(timestr,    count, pieces, seconds)
{
    # Remove the trailing "s" to avoid having an empty piece at the end
    sub(/s$/, "", timestr)
    count = split(timestr, pieces, /[hm]/)

    seconds = pieces[count]
    if (count >= 2) {
        seconds += 60 * pieces[count - 1]
        if (count >= 3) {
            seconds += 3600 * pieces[count - 2]
        }
    }

    return seconds
}



/^HTTP request sent, awaiting response/ {
    print $6 > response
}


/%/ {
    # The field containing the percentage value may vary, depending on how many dots were
    # printed on the line.
    for (i=1; i<=NF; i++) {
        if ($i ~ /%$/) {
            sub(/%$/, "", $i)
            print $i > percent
            print parse_time($(i + 2)) > remain
        }
    }
}
