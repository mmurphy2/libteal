#!/bin/sh
#
# Utility for importing and trusting a public GPG key, as well as verifying
# the public key against a fingerprint.
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
$0 [options] <keyfile> <fingerprint>

Options:
    -G <dir> | --homedir <dir>
        Sets the --homedir option for gpg2 (defaults to ~/.gnupg).
    -h | --help
        Show this message and exit.

Normally, this command will be used with -G to specify a GPG home directory
for the key to be imported and checked. When run, this program first checks
the GPG home directory to see if the public key with <fingerprint> is already
imported. If not, the public key is imported from <keyfile> and marked as
ultimately trusted.
EOF
}


homedir="${HOME}/.gnupg"
while [ $# -gt 0 ]; do
    case "$1" in
        -G|--homedir)
            homedir="$2"
            shift 2
        ;;
        -h|--help)
            usage
            exit 0
        ;;
        *)
            break
        ;;
    esac
done


if [ $# -ne 2 ]; then
    echo "Usage: $0 [options] <keyfile> <fingerprint>"
    exit 2
fi


fingerprint=$(echo "$2" | sed 's/://g')

check_fp=$(gpg2 --homedir "${homedir}" --list-keys --with-colons | grep -A 1 '^pub:' | grep '^fpr:' | \
           sed s/fpr// | sed 's/://g')
#

have_key=no
for fp in ${check_fp}; do
    if [ "x${fp}" = "x${fingerprint}" ]; then
        have_key=yes
    fi
done

if [ "${have_key}" = "no" ]; then
    gpg2 --homedir "${homedir}" --trusted-key "${fingerprint}" --import "$1" || exit 1
fi

exit 0
