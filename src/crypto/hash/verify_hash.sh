#!/bin/sh
#
# Verifies the checksum of a file.
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
$0 [options] <file> <checksum>

Options:
    -h | --help
        Show this help message and exit.

Verifies the specified <file> using the given <checksum>. The format of the
<checksum> is as follows:

<algorithm>:<hash_value>

Supported algorithms are md5, sha1, sha256, sha512, blake2-256 and blake2-512.

Exits with a status of 0 if verification is successful. If verification fails
for any reason other than improper arguments, the exit status will be 4.
EOF
}


while [ $# -gt 0 ]; do
    case "$1" in
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
    echo "Usage: $0 [options] <file> <checksum>" >&2
    exit 2
fi


# Resolve the algorithm part of the hash value to the specific program that will be used to check the file.
algorithm=$(echo "$2" | awk -F ':' '{print tolower($1)}')
case "${algorithm}" in
    md5)
        hash_prog="md5sum"
        hash_name="MD5"
    ;;
    sha1)
        hash_prog="sha1sum"
        hash_name="SHA1"
    ;;
    sha256)
        hash_prog="sha256sum"
        hash_name="SHA256"
    ;;
    sha512)
        hash_prog="sha512sum"
        hash_name="SHA512"
    ;;
    blake2-256|b2-256)
        hash_prog="b2sum -l 256"
        hash_name="BLAKE2-256"
    ;;
    blake2-512|b2-512)
        hash_prog="b2sum -l 512"
        hash_name="BLAKE2-512"
    ;;
    *)
        echo "Unsupported hash algorithm: ${algorithm}" >&2
        exit 2
    ;;
esac


# Since we have to do a string comparison, ensure the hash value is lowercase.
check_hash=$(echo "$2" | awk -F ':' '{print tolower($2)}')
if [ -z "${check_hash}" ]; then
    echo "Missing hash digest" >&2
    exit 2
fi


# Run the hash algorithm, obtain a lowercase version of the hash by itself, then compare
# to the one supplied as a command-line argument.
the_hash=$(${hash_prog} "$1")
the_hash=$(echo "${the_hash}" | awk '{print tolower($1)}')
if [ "x${check_hash}" != "x${the_hash}" ]; then
    echo "Hash verification failed: $1" >&2
    exit 4
fi


# Successful: print a friendly message to stderr
base_name=$(basename "$1")
echo "OK: ${base_name} (${hash_name})" >&2
exit 0
