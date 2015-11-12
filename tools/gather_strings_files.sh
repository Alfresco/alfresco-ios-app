#!/bin/sh

# Call this when there is an error. This does not return.
function die() {
  echo ""
  echo "FATAL: $*" >&2
  exit 1
}

#
# Gathers strings given source and destination folders
#
# Arguments:
#    1: source folder containing locale subfolders of the format "*.lproj"
#    2: destination folder to copy the *.lproj subfolders to
#
function gather_locales_from_folder() {
	dir_source="${1}"
	dir_destination="${2}"

	echo "Gathering strings from ${dir_source#$DIR_ROOT} into ${dir_destination#$DIR_ROOT}"

	test -d "$dir_source" \
	   || die "Could not find directory $dir_source"

	test -d "$dir_destination" \
	   || mkdir -p "$dir_destination" \
	   || die "Could not create directory $dir_destination"

	pushd "$dir_source" > /dev/null

	find . -type d -name '*.lproj' -maxdepth 1 | while read dir; do
		cp -R $dir $dir_destination
	done

	popd > /dev/null
}

# The directory containing this script
pushd "$(dirname "$BASH_SOURCE[0]")" >/dev/null
DIR_THIS_SCRIPT=$(pwd)
popd >/dev/null

# The application root folder
DIR_ROOT="$(dirname "$DIR_THIS_SCRIPT")"
cd "$DIR_ROOT"

# Where the strings will be gathered
DIR_OUTPUT=$DIR_ROOT/build/Strings

test -d "$DIR_OUTPUT" \
   || mkdir -p "$DIR_OUTPUT" \
   || die "Could not create directory $DIR_OUTPUT"

# Test the ourput path is a subfolder of the root path
if [[ $DIR_OUTPUT =~ $DIR_ROOT ]]; then
	rm -rf $DIR_OUTPUT/*
else
	die "$DIR_OUTPUT is not a subfolder of $DIR_ROOT"
fi


# AlfrescoApp
gather_locales_from_folder "$DIR_ROOT/AlfrescoApp/Supporting Files" "$DIR_OUTPUT/AlfrescoApp"

# AlfrescoAppSettings
gather_locales_from_folder "$DIR_ROOT/AlfrescoApp/Supporting Files/Settings.bundle" "$DIR_OUTPUT/AlfrescoAppSettings"

# AlfrescoDocumentPicker
gather_locales_from_folder "$DIR_ROOT/AlfrescoDocumentPicker" "$DIR_OUTPUT/AlfrescoDocumentPicker"

# AlfrescoKit
gather_locales_from_folder "$DIR_ROOT/AlfrescoSDK/AlfrescoKit/AlfrescoKit/Supporting Files" "$DIR_OUTPUT/AlfrescoKit"


