#!/bin/sh

if [ $# -ne 2 ]; then
    echo usage: $0 plist-file build-number
    exit 1
fi

plist="$1"
dir="$(dirname "$plist")"
buildnum=$2

/usr/libexec/Plistbuddy -c "Set CFBundleVersion $buildnum" "$plist"
echo "Incremented build number to $buildnum"
