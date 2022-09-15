#!/bin/sh

data=$(flatpak --system list --columns origin,application,version,branch)
echo "${data}" | awk '(NR > 1) { print $1 "/" $2 " " $3 "-" $4 }'
