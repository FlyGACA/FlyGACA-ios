#!/bin/bash
set -euo pipefail

# sign-corpus.sh — Ed25519 signing for the remote quiz corpus
# (https://flygaca.com/data/quiz.json). ContentRefresher (ContentKit) refuses
# any refresh whose exact bytes don't verify against the FGCorpusPublicKey
# pinned in each app's Info.plist, so every publish of quiz.json must also
# upload the quiz.json.sig produced here, next to it in the same directory.
#
#   bash scripts/sign-corpus.sh genkey [secrets-dir]
#       Generate an Ed25519 keypair (corpus-ed25519-private.pem and
#       corpus-ed25519-public.pem, default ./secrets) and print the base64 raw
#       public key to set as INFOPLIST_KEY_FGCorpusPublicKey in
#       apple/Apps/Shared/App-Shared.xcconfig.
#
#   bash scripts/sign-corpus.sh sign <private-key.pem> <path/to/quiz.json>
#       Write <path/to/quiz.json.sig> (single-line base64 Ed25519 signature
#       over the exact quiz.json bytes) next to quiz.json, and print the
#       base64 public key so you can confirm it matches what the apps ship.
#
# The private key is a deploy secret — keep it OUT of this repo (secrets/ is
# for local use; store the key in your deploy secret manager). Key rotation
# means shipping a new FGCorpusPublicKey in an app update BEFORE publishing
# corpora signed with the new key, since old builds fail closed.
#
# Requires OpenSSL 1.1.1+ (pkeyutl -rawin). LibreSSL 3.3+ also works.

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()    { echo -e "${BLUE}i${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_error()   { echo -e "${RED}✗${NC} $1" >&2; }

usage() {
  echo "Usage:" >&2
  echo "  bash scripts/sign-corpus.sh genkey [secrets-dir]" >&2
  echo "  bash scripts/sign-corpus.sh sign <private-key.pem> <path/to/quiz.json>" >&2
}

# base64 of the raw 32-byte Ed25519 public key (last 32 bytes of the
# SubjectPublicKeyInfo DER) — the exact format CryptoKit's
# Curve25519.Signing.PublicKey(rawRepresentation:) expects.
print_public_key_base64() {
  openssl pkey -pubin -in "$1" -outform DER 2>/dev/null | tail -c 32 | base64 | tr -d '\n'
}

CMD="${1:-}"
case "$CMD" in
  genkey)
    DIR="${2:-./secrets}"
    PRIV="$DIR/corpus-ed25519-private.pem"
    PUB="$DIR/corpus-ed25519-public.pem"
    if [ -e "$PRIV" ]; then
      log_error "refusing to overwrite existing key: $PRIV"
      exit 1
    fi
    mkdir -p "$DIR"
    chmod 700 "$DIR"
    openssl genpkey -algorithm ed25519 -out "$PRIV"
    chmod 600 "$PRIV"
    openssl pkey -in "$PRIV" -pubout -out "$PUB"
    log_success "Wrote $PRIV (KEEP SECRET — never commit) and $PUB"
    echo ""
    echo "FGCorpusPublicKey — paste into apple/Apps/Shared/App-Shared.xcconfig:"
    echo ""
    echo "  INFOPLIST_KEY_FGCorpusPublicKey = $(print_public_key_base64 "$PUB")"
    ;;
  sign)
    PRIV="${2:-}"
    CORPUS="${3:-}"
    if [ -z "$PRIV" ] || [ -z "$CORPUS" ]; then
      usage
      exit 1
    fi
    [ -f "$PRIV" ]   || { log_error "private key not found: $PRIV"; exit 1; }
    [ -f "$CORPUS" ] || { log_error "corpus not found: $CORPUS"; exit 1; }
    SIG="$CORPUS.sig"
    RAW="$SIG.raw"
    trap 'rm -f "$RAW"' EXIT
    # Ed25519 signs the message directly (no pre-hash) — -rawin is required.
    openssl pkeyutl -sign -inkey "$PRIV" -rawin -in "$CORPUS" -out "$RAW"
    # Single-line base64 + trailing newline; ContentRefresher decodes with
    # .ignoreUnknownCharacters, so either way is fine.
    base64 < "$RAW" | tr -d '\n' > "$SIG"
    echo "" >> "$SIG"
    log_success "Wrote $SIG — upload it next to $(basename "$CORPUS") (same directory, same deploy)"
    log_info "Public key the apps must ship (FGCorpusPublicKey):"
    PUB_TMP="$(mktemp)"
    trap 'rm -f "$RAW" "$PUB_TMP"' EXIT
    openssl pkey -in "$PRIV" -pubout -out "$PUB_TMP"
    echo "  $(print_public_key_base64 "$PUB_TMP")"
    ;;
  *)
    usage
    exit 1
    ;;
esac
