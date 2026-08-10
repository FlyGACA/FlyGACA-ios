#!/bin/bash
set -euo pipefail

# sync-content.sh — refresh this repo's committed per-app Content/ + icons from a
# local FlyGACA-app monorepo clone, which remains the source of truth for the
# corpus (public/data/) and the pack catalog (src/lib/prepCatalog.ts).
#
#   bash scripts/sync-content.sh                  # monorepo at ../FlyGACA-app
#   bash scripts/sync-content.sh ~/code/FlyGACA-app
#
# This repo OWNS its Swift code and Xcode config (FlyGACAKit, project.yml,
# apple/Scripts, ARCHITECTURE.md, README.md) — they are hand-edited here, NOT
# synced. Only Content/ + Assets.xcassets come from the monorepo, and it now
# generates them straight into this repo (the monorepo's own apple/ mirror was
# retired 2026-08). The generators write per app into <appsDir>/<App>/…, so we
# point them at this repo's apple/Apps.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MONO="${1:-$REPO_ROOT/../FlyGACA-app}"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1" >&2; }

if [ ! -f "$MONO/scripts/build-ios-content.mjs" ]; then
  log_error "FlyGACA-app clone not found at: $MONO"
  echo "  Usage: bash scripts/sync-content.sh [path-to-FlyGACA-app]" >&2
  exit 1
fi

APPS_DIR="$REPO_ROOT/apple/Apps"

log_info "Generating per-app content in the monorepo → $APPS_DIR …"
(cd "$MONO" && node scripts/build-ios-content.mjs --out "$APPS_DIR")

log_info "Generating per-app icons in the monorepo → $APPS_DIR …"
(cd "$MONO" && node scripts/native/gen-app-icons.mjs --out "$APPS_DIR")

log_success "Done — Content/ + Assets.xcassets refreshed for the shipping apps."
echo "  Review with: git status && git diff"
echo "  (The licence-exam apps PPL/CPL/IR/ATPL are paused — see ROADMAP.md. Swift"
echo "   code and project.yml are owned here and are NOT touched by this script.)"
