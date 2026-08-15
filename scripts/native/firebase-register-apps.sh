#!/bin/bash
set -euo pipefail

# firebase-register-apps.sh — register the Fly GACA iOS apps in the shared
# Firebase project and download each GoogleService-Info.plist.
#
# One Firebase project (flygaca-app) backs the whole family, so it needs one iOS
# app registration per bundle id — and each app's config plist dropped next
# to its target (apple/Apps/<APP>/GoogleService-Info.plist), where project.yml
# copies it into the bundle. This automates the console clicks in
# docs/RUNBOOK-ios-firebase.md; the Sign in with Apple provider + APNs auth key
# there are still manual (no API covers the Apple provider).
#
# Prereqs (run once, on your machine — not in this container):
#   npm i -g firebase-tools   &&   firebase login
#
# Usage:
#   bash scripts/native/firebase-register-apps.sh                 # project flygaca-app
#   FIREBASE_PROJECT=my-project bash scripts/native/firebase-register-apps.sh
#
# Idempotent: an app that already exists for a bundle id is reused, not duplicated.
# Never overwrites an existing plist unless FORCE=1.

PROJECT="${FIREBASE_PROJECT:-flygaca-app}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/apple"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info() { echo -e "${BLUE}ℹ${NC} $1"; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
die()  { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

command -v firebase >/dev/null 2>&1 || die "firebase CLI not found. Install: npm i -g firebase-tools"
command -v node >/dev/null 2>&1 || die "node not found (firebase-tools needs it)."
firebase projects:list >/dev/null 2>&1 || die "Not logged in. Run: firebase login"

# APP  DISPLAY_NAME  BUNDLE_ID  (order matches the App Store family)
APPS=(
  "ELPT|Fly GACA ELPT|com.flygaca.elpt"
  "AIP|Fly GACA AIP|com.flygaca.aip"
)

# Print the Firebase App ID for a given iOS bundle id, or empty if none exists.
app_id_for_bundle() {
  local bundle="$1"
  firebase apps:list IOS --project "$PROJECT" --json 2>/dev/null \
    | node -e '
        let s=""; process.stdin.on("data",d=>s+=d).on("end",()=>{
          try {
            const j = JSON.parse(s);
            const apps = (j.result || j.apps || []);
            const hit = apps.find(a => (a.bundleId||a.namespace) === process.argv[1]);
            if (hit) process.stdout.write(hit.appId || hit.appIdRaw || "");
          } catch (_) {}
        });
      ' "$bundle"
}

info "Project: $PROJECT"
for entry in "${APPS[@]}"; do
  app=""
  display=""
  bundle=""
  IFS='|' read -r app display bundle <<< "$entry"
  plist="$APPLE_DIR/Apps/$app/GoogleService-Info.plist"

  appId="$(app_id_for_bundle "$bundle")"
  if [ -z "$appId" ]; then
    info "Creating iOS app '$display' ($bundle)…"
    firebase apps:create IOS "$display" --bundle-id "$bundle" --project "$PROJECT" >/dev/null \
      || warn "create returned non-zero for $bundle (may already exist) — re-checking"
    appId="$(app_id_for_bundle "$bundle")"
    [ -n "$appId" ] || die "Could not resolve App ID for $bundle after create."
    ok "Registered $bundle → $appId"
  else
    ok "Exists: $bundle → $appId"
  fi

  if [ -f "$plist" ] && [ "${FORCE:-0}" != "1" ]; then
    warn "Keeping existing $app/GoogleService-Info.plist (set FORCE=1 to overwrite)"
    continue
  fi
  info "Downloading config for ${app}..."
  # sdkconfig prints the plist to stdout (with a log preamble); keep only the XML.
  firebase apps:sdkconfig IOS "$appId" --project "$PROJECT" 2>/dev/null \
    | awk '/<\?xml/,/<\/plist>/' > "$plist"
  [ -s "$plist" ] && grep -q "</plist>" "$plist" \
    || die "Downloaded plist for $app looks empty/invalid — check 'firebase apps:sdkconfig IOS $appId'."
  ok "Wrote apple/Apps/$app/GoogleService-Info.plist"
done

echo
ok "All iOS apps registered and configured."
echo "  These plists are git-ignored (secrets). Next: Sign in with Apple + APNs"
echo "  auth key are manual — see docs/RUNBOOK-ios-firebase.md."
