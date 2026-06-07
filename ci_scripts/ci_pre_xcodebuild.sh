#!/bin/sh
set -e

# Sync GIDClientID in Info.plist from the active GoogleService-Info.plist.
# ci_post_clone.sh writes the correct plist for the current environment, so
# by the time this script runs the CLIENT_ID here is authoritative.

PLIST="$CI_PRIMARY_REPOSITORY_PATH/flixr/GoogleService-Info.plist"
INFO_PLIST="$CI_PRIMARY_REPOSITORY_PATH/flixr/Info.plist"

CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print :CLIENT_ID" "$PLIST" 2>/dev/null || true)

if [ -n "$CLIENT_ID" ]; then
    /usr/libexec/PlistBuddy -c "Set :GIDClientID $CLIENT_ID" "$INFO_PLIST"
    echo "ci_pre_xcodebuild: set GIDClientID to $CLIENT_ID"
else
    echo "ci_pre_xcodebuild: CLIENT_ID not found in $PLIST, skipping GIDClientID update"
fi
