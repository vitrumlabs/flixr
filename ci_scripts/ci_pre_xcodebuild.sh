#!/bin/sh
# Sync GIDClientID in Info.plist from the active GoogleService-Info.plist.
# ci_post_clone.sh writes the correct plist for the environment before this runs.

PLIST="$CI_PRIMARY_REPOSITORY_PATH/flixr/GoogleService-Info.plist"
INFO_PLIST="$CI_PRIMARY_REPOSITORY_PATH/flixr/Info.plist"

CLIENT_ID=$(/usr/libexec/PlistBuddy -c "Print :CLIENT_ID" "$PLIST" 2>/dev/null || true)

if [ -n "$CLIENT_ID" ]; then
    # Try Set first (key already exists); fall back to Add if it doesn't.
    # Both commands are made non-fatal — GIDClientID is already baked into
    # Info.plist for dev, so a failure here only affects prod-scheme builds.
    if /usr/libexec/PlistBuddy -c "Set :GIDClientID ${CLIENT_ID}" "$INFO_PLIST" 2>/dev/null; then
        echo "ci_pre_xcodebuild: set GIDClientID to $CLIENT_ID"
    elif /usr/libexec/PlistBuddy -c "Add :GIDClientID string ${CLIENT_ID}" "$INFO_PLIST" 2>/dev/null; then
        echo "ci_pre_xcodebuild: added GIDClientID $CLIENT_ID"
    else
        echo "ci_pre_xcodebuild: WARNING — could not write GIDClientID ($CLIENT_ID) to Info.plist"
    fi
else
    echo "ci_pre_xcodebuild: CLIENT_ID not found in $PLIST, skipping GIDClientID update"
fi
