#!/bin/sh

uplist=$(flatpak --system remote-ls --updates --columns application,version,branch flathub)
echo "${uplist}" | awk '(NR > 1) { print $1 " " $2 "-" $3 }'
