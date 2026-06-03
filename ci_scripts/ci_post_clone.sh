#!/bin/sh
set -e

# Install CocoaPods dependencies after Xcode Cloud clones the repo.
# CI_PRIMARY_REPOSITORY_PATH is set by Xcode Cloud to the repo root.

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Write dev GoogleService-Info.plist from secret env var.
# Set GOOGLE_SERVICE_INFO_DEV_BASE64 in the Xcode Cloud workflow environment.
if [ -n "$GOOGLE_SERVICE_INFO_DEV_BASE64" ]; then
    echo "$GOOGLE_SERVICE_INFO_DEV_BASE64" | base64 --decode > "$CI_PRIMARY_REPOSITORY_PATH/flixr/GoogleService-Info.plist"
fi

if ! command -v pod >/dev/null 2>&1; then
    gem install cocoapods --no-document
fi

pod install --repo-update
