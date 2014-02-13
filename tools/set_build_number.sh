#!/bin/sh

underline=`tput smul`
nounderline=`tput rmul`
bold=`tput bold`
normal=`tput sgr0`

usage ()
{
   echo "Usage: $0 ${underline}info.plist${nounderline} ${bold}build number${normal} (${underline}settings.plist${nounderline} ${bold}value-path${normal})"
   echo
   echo "Mandatory:"
   echo "     ${underline}info.plist${nounderline} : Location of the app's Info.plist file containing CFBundleVersion key"
   echo "     ${bold}build number${normal} : A string value to set the CFBundleVersion to"
   echo
   echo "Optional:"
   echo "     ${underline}settings.plist${nounderline} : If specified, also set the version in a plist file within the Settings.bundle"
   echo "     ${bold}value-path${normal} : MUST be supplied if specifying ${underline}settings.plist${nounderline} and be PlistBuddy <Entry> format, e.g. PreferenceSpecifiers:1:DefaultValue"
   echo
   exit 1
}

if [[ $# -ne 2 && $# -ne 4 ]]; then
   usage
fi

PlistBuddy="/usr/libexec/PlistBuddy"
infoPlist="$1"
buildNumber=$2

$PlistBuddy -c "Set CFBundleVersion $buildNumber" "$infoPlist"
echo "Incremented build number to $buildNumber"

if [[ $# -eq 4 ]]; then
   # Update the version number in the Settings.bundle/Root.plist file
   rootPlist="$3"
   valuePath="$4"

   cfShortVersion=`$PlistBuddy -c "Print CFBundleShortVersionString" "$infoPlist"`
   $PlistBuddy -c "Set $valuePath $cfShortVersion ($buildNumber)" "$rootPlist"
   echo "Set version number in Settings.bundle to $cfShortVersion ($buildNumber)"
fi
