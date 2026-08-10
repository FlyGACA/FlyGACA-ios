#!/bin/bash
set -euo pipefail

# ci-firebase-placeholder.sh — write an inert placeholder GoogleService-Info.plist
# for any app target that lacks one, so the Xcode "Copy Resources" phase (which
# apple/project.yml declares per bundle id) succeeds in CI without the real
# Firebase config.
#
# The real plists are per-app Firebase secrets, downloaded manually from the
# console (docs/RUNBOOK-ios-firebase.md) and git-ignored — never committed.
# Firebase isn't linked yet (PlatformLive / Phase 4), so the plist is an inert
# bundle resource: for a build it only needs to exist and be a valid plist.
# An existing (real) plist is never overwritten.
#
# XcodeGen marks the plist reference `optional: true`, which only suppresses the
# generation-time missing-path check — a real xcodebuild still copies the file
# and fails if it is absent. This shim makes the offline debug/release builds
# green while keeping apple/project.yml identical to the FlyGACA-app monorepo.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/apple"

write_placeholder() {
  local app="$1" bundle="$2"
  local plist="$APPLE_DIR/Apps/$app/GoogleService-Info.plist"
  if [ -f "$plist" ]; then
    echo "keep existing $app/GoogleService-Info.plist"
    return 0
  fi
  cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>BUNDLE_ID</key>
	<string>${bundle}</string>
	<key>PROJECT_ID</key>
	<string>flygaca-app</string>
	<key>PLACEHOLDER</key>
	<true/>
</dict>
</plist>
PLIST
  echo "wrote placeholder $app/GoogleService-Info.plist"
}

write_placeholder ELPT com.flygaca.elpt
write_placeholder AIP  com.flygaca.aip
