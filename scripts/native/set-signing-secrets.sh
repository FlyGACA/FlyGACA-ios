#!/bin/bash
set -euo pipefail

# set-signing-secrets.sh — base64-encode the Apple signing assets and push them
# to the GitHub repo as Actions secrets, so the `ios-testflight` job in
# .github/workflows/ios.yml can sign + upload the shipping apps (ELPT, AIP).
#
# See docs/RUNBOOK-ios-signing-CHECKLIST.md. You still create the certs, profiles,
# app records and API key in Apple's portals — this only uploads them as secrets.
#
# Usage:
#   export APPLE_TEAM_ID=XXXXXXXXXX \
#          APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX \
#          APP_STORE_CONNECT_API_ISSUER_ID=xxxxxxxx-xxxx-... \
#          P12_PASSWORD='your-p12-password'          # KEYCHAIN_PASSWORD optional (auto-random)
#   bash scripts/native/set-signing-secrets.sh \
#       Distribution.p12 \
#       FlyGACA_ELPT_AppStore.mobileprovision \
#       FlyGACA_AIP_AppStore.mobileprovision \
#       AuthKey_XXXXXXXXXX.p8
#
# Target repo defaults to ay2m/FlyGACA (where the iOS workflow lives); override with REPO=owner/name.

REPO="${REPO:-ay2m/FlyGACA}"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
info() { echo -e "${BLUE}ℹ${NC} $1"; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
die()  { echo -e "${RED}✗${NC} $1" >&2; exit 1; }

command -v gh >/dev/null 2>&1 || die "gh CLI not found. Install: https://cli.github.com"
gh auth status >/dev/null 2>&1 || die "gh not authenticated. Run: gh auth login"

[ "$#" -eq 4 ] || die "Expected 4 files: <p12> <elpt.mobileprovision> <aip.mobileprovision> <asc.p8>"
P12="$1"; PROF_ELPT="$2"; PROF_AIP="$3"; P8="$4"
for f in "$P12" "$PROF_ELPT" "$PROF_AIP" "$P8"; do
  [ -f "$f" ] || die "File not found: $f"
done

: "${APPLE_TEAM_ID:?set APPLE_TEAM_ID}"
: "${APP_STORE_CONNECT_API_KEY_ID:?set APP_STORE_CONNECT_API_KEY_ID}"
: "${APP_STORE_CONNECT_API_ISSUER_ID:?set APP_STORE_CONNECT_API_ISSUER_ID}"
: "${P12_PASSWORD:?set P12_PASSWORD}"
# A random temp-keychain password is fine if you didn't set one.
KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 24)}"

# Portable base64 (no line wrap) — Linux uses -w0, macOS has no such flag.
b64() { if base64 --help 2>&1 | grep -q -- '-w'; then base64 -w0 "$1"; else base64 "$1" | tr -d '\n'; fi; }

setp() { info "set $1"; gh secret set "$1" --repo "$REPO" --body "$2" >/dev/null && ok "$1"; }
setf() { info "set $1 (from $2)"; b64 "$2" | gh secret set "$1" --repo "$REPO" >/dev/null && ok "$1"; }

info "Target repo: $REPO"
setp APPLE_TEAM_ID "$APPLE_TEAM_ID"
setp P12_PASSWORD "$P12_PASSWORD"
setp KEYCHAIN_PASSWORD "$KEYCHAIN_PASSWORD"
setp APP_STORE_CONNECT_API_KEY_ID "$APP_STORE_CONNECT_API_KEY_ID"
setp APP_STORE_CONNECT_API_ISSUER_ID "$APP_STORE_CONNECT_API_ISSUER_ID"
setf BUILD_CERTIFICATE_BASE64 "$P12"
setf PROVISIONING_PROFILE_ELPT_BASE64 "$PROF_ELPT"
setf PROVISIONING_PROFILE_AIP_BASE64 "$PROF_AIP"
setf APP_STORE_CONNECT_API_KEY_BASE64 "$P8"

echo
ok "All 9 signing secrets set on $REPO."
echo "  Push to main (or re-run the iOS workflow) — ios-testflight now runs for elpt/aip."
