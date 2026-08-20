#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail(){ echo "FAIL: $*" >&2; exit 1; }
PREP="$ROOT_DIR/scripts/prepare_store_icons.sh"
GEN="$ROOT_DIR/scripts/generate_catalog.py"
VAL="$ROOT_DIR/scripts/validate_store_icons.py"

bash -n "$PREP" || fail "prepare_store_icons syntax"
python3 -m py_compile "$VAL" || fail "icon validator syntax"
grep -q 'store-icons-v6' "$PREP" || fail "v6 cache missing"
grep -q 'ICON_ID' "$PREP" || fail "explicit icon id contract missing"
grep -q 'raw.githubusercontent.com/homarr-labs/dashboard-icons/main/svg/${icon_id}.svg' "$PREP" || fail "Dashboard SVG lookup missing"
grep -q 'raw.githubusercontent.com/homarr-labs/dashboard-icons/main/png/${icon_id}.png' "$PREP" || fail "Dashboard PNG lookup missing"
grep -q 'google.com/s2/favicons' "$PREP" || fail "website favicon fallback missing"
grep -q 'webapp-generic.svg' "$PREP" || fail "generic poison guard missing"
grep -q 'icon-pipeline.log' "$PREP" || fail "diagnostic log missing"
grep -q 'unresolved' "$PREP" || fail "strict unresolved counter missing"
grep -q 'store-icons-v6' "$GEN" || fail "catalog generator does not use v6 cache"
grep -q 'resolved == 79' "$VAL" || fail "validator does not require 79 resolved icons"
grep -q 'store_webp' "$GEN" || fail "WEBP cache support missing"

apps=$(find "$ROOT_DIR/apps" -maxdepth 1 -name '*.conf' | wc -l)
[[ "$apps" -eq 79 ]] || fail "expected 79 apps, got $apps"
providers=$(grep -l '^ICON_PROVIDER=' "$ROOT_DIR"/apps/*.conf | wc -l)
[[ "$providers" -eq 79 ]] || fail "expected 79 provider mappings, got $providers"
ids=$(grep -l '^ICON_ID=' "$ROOT_DIR"/apps/*.conf | wc -l)
[[ "$ids" -eq 79 ]] || fail "expected 79 explicit icon IDs, got $ids"

grep -q 'ICON_ID="google-gemini"' "$ROOT_DIR/apps/gemini.conf" || fail "Gemini mapping regression"

echo "PASS: Phase16.1-fix2b strict icon resolution contract ($apps mappings)"
