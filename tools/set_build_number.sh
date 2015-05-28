#!/bin/sh

usage ()
{
   echo "Usage: $0 <info.plist> buildNumber (<settings.plist> value-path)"
   echo "     <info.plist> : Location of the app's Info.plist file containing CFBundleVersion key"
   echo "     build number : A string value to set the CFBundleVersion to"
   echo "   optional parameters:"
   echo "     <settings.plist> : If specified, also set the version in a plist file within the Settings.bundle"
   echo "     value-path : MUST be supplied if specifying <settings.plist> and be PlistBuddy <Entry> format, e.g. PreferenceSpecifiers:1:DefaultValue"
   echo
   exit 1
}

if [[ $# -ne 2 && $# -ne 4 ]]; then
   usage
fi

buildNumber=$2

echo "Setting build number in all project targets to $buildNumber"
agvtool new-version -all $buildNumber

if [[ $# -eq 4 ]]; then
   PlistBuddy="/usr/libexec/PlistBuddy"
   infoPlist="$1"
   rootPlist="$3"
   valuePath="$4"

   # Read the marketing version from the info.plist file
   cfShortVersion=`$PlistBuddy -c "Print CFBundleShortVersionString" "$infoPlist"`

   echo "Setting version number in $rootPlist to: \"$cfShortVersion ($buildNumber)\""
   $PlistBuddy -c "Set $valuePath $cfShortVersion ($buildNumber)" "$rootPlist"
fi
