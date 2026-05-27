#!/bin/sh
set -e

# Install CocoaPods dependencies after Xcode Cloud clones the repo.
# CI_PRIMARY_REPOSITORY_PATH is set by Xcode Cloud to the repo root.

cd "$CI_PRIMARY_REPOSITORY_PATH"

if ! command -v pod >/dev/null 2>&1; then
    echo "CocoaPods not found — installing via gem"
    sudo gem install cocoapods --no-document
fi

pod install --repo-update
