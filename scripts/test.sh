#!/bin/sh
# Runs the unit tests on the first available iPhone simulator.
set -e
cd "$(dirname "$0")/.."
SIM=$(xcrun simctl list devices available | grep -m1 -oE 'iPhone[^(]*\(([0-9A-F-]{36})\)' | grep -oE '[0-9A-F-]{36}')
if [ -z "$SIM" ]; then echo "No iPhone simulator found. Install one in Xcode > Settings > Components."; exit 1; fi
xcodebuild test -project AutoServiceTracker.xcodeproj -scheme AutoServiceTracker -destination "id=$SIM" | { command -v xcpretty >/dev/null && xcpretty || cat; }
