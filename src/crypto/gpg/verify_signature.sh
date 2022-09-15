#!/bin/sh
#
# Verifies a file using a detached GPG signature file.
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
$0 [options] <file> <detached_signature_file>

Options:
    -G <directory> | --gpg-home <directory>
        Path to the GPG home directory for signature verification. By default,
        the --homedir option is not passed to gpg2 unless this option is
        given.
    -h | --help
        Show this help message and exit.

Performs GPG verification of a file with a detached signature, using the gpg2
command. The location of the GPG home directory may be specified with the -G
option (defaults to ~/.gnupg).

Yields an exit status of 0 for successful verification and 3 if verification
fails.
EOF
}

gpghome="${HOME}/.gnupg"

while [ $# -gt 0 ]; do
    case "$1" in
        -G|--gpg-home)
            gpghome="$2"
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
    echo "Usage: $0 [options] <file> <detached_signature_file>" >&2
    exit 2
fi


# Perform the verification using gpg2
gpg2 --homedir "${gpghome}" --verify "${sigfile}" "${have_file}" >&2
result=$?


[ ${result} -ne 0 ] && result=3
exit ${result}
