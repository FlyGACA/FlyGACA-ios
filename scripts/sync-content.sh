#!/bin/bash
set -euo pipefail

# sync-content.sh — refresh this repo's committed per-app content (and icons)
# from a local FlyGACA-app monorepo clone, which remains the source of truth
# for the corpus (public/data/) and the pack catalog (src/lib/prepCatalog.ts).
#
#   bash scripts/sync-content.sh                  # monorepo at ../FlyGACA-app
#   bash scripts/sync-content.sh ~/code/FlyGACA-app
#   bash scripts/sync-content.sh ~/code/FlyGACA-app --all   # also sync the kit,
#                                                 # shared shell, spec and docs
#
# Default sync: apple/Apps/<App>/Content/ + Assets.xcassets (app icons) for the
# six apps. --all additionally syncs FlyGACAKit/, Apps/Shared/, project.yml,
# ARCHITECTURE.md, apple/README.md, AppleTests/ and apple/Scripts/ so the whole
# apple/ tree tracks the monorepo. Review the diff before committing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MONO="${1:-$REPO_ROOT/../FlyGACA-app}"
MODE="${2:-content}"
[ "${1:-}" = "--all" ] && { MONO="$REPO_ROOT/../FlyGACA-app"; MODE="--all"; }

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}ℹ${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1" >&2; }

if [ ! -f "$MONO/scripts/build-ios-content.mjs" ]; then
  log_error "FlyGACA-app clone not found at: $MONO"
  echo "  Usage: bash scripts/sync-content.sh [path-to-FlyGACA-app] [--all]" >&2
  exit 1
fi

# copy_dir <src> <dest> — mirror a directory (delete-and-copy; no rsync dependency).
copy_dir() {
  local src="$1" dest="$2"
  [ -d "$src" ] || { log_error "missing in monorepo: $src"; exit 1; }
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -R "$src" "$dest"
}

log_info "Regenerating per-app content in the monorepo…"
(cd "$MONO" && node scripts/build-ios-content.mjs)

APPS=(PPL ELPT AIP CPL IR ATPL)
for app in "${APPS[@]}"; do
  copy_dir "$MONO/apple/Apps/$app/Content" "$REPO_ROOT/apple/Apps/$app/Content"
  copy_dir "$MONO/apple/Apps/$app/Assets.xcassets" "$REPO_ROOT/apple/Apps/$app/Assets.xcassets"
  log_success "Synced $app content + assets"
done

if [ "$MODE" = "--all" ]; then
  log_info "Syncing the full apple/ tree (kit, shared shell, spec, docs)…"
  copy_dir "$MONO/apple/FlyGACAKit/Sources" "$REPO_ROOT/apple/FlyGACAKit/Sources"
  copy_dir "$MONO/apple/FlyGACAKit/Tests"   "$REPO_ROOT/apple/FlyGACAKit/Tests"
  cp "$MONO/apple/FlyGACAKit/Package.swift" "$REPO_ROOT/apple/FlyGACAKit/Package.swift"
  copy_dir "$MONO/apple/Apps/Shared" "$REPO_ROOT/apple/Apps/Shared"
  for app in "${APPS[@]}"; do
    cp "$MONO/apple/Apps/$app/$app.xcconfig" "$REPO_ROOT/apple/Apps/$app/$app.xcconfig"
  done
  copy_dir "$MONO/apple/AppleTests" "$REPO_ROOT/apple/AppleTests"
  copy_dir "$MONO/apple/Scripts"   "$REPO_ROOT/apple/Scripts"
  cp "$MONO/apple/project.yml"     "$REPO_ROOT/apple/project.yml"
  cp "$MONO/apple/ARCHITECTURE.md" "$REPO_ROOT/apple/ARCHITECTURE.md"
  cp "$MONO/apple/README.md"       "$REPO_ROOT/apple/README.md"
  log_success "Full apple/ tree synced"
fi

log_success "Done — review with: git status && git diff"
