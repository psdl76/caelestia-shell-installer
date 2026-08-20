#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"

files=("$ROOT_DIR/install.sh" "$ROOT_DIR/lib/"*.sh "$ROOT_DIR/scripts/"*.py)
blob="$TEST_ROOT/hypr.txt"
cat "${files[@]}" > "$blob"

grep -Eq 'Caelestia WebApps' "$blob" || fail "Ownership-Marker fehlt"
grep -Eq 'SUPER[[:space:]]*\+[[:space:]]*Y|SUPER\+Y' "$blob" || fail "Streaming-Keybind SUPER+Y fehlt"
grep -Eq 'streaming_app_tag' "$blob" || fail "streaming_app_tag fehlt"
grep -Eq 'communication_app_tag' "$blob" || fail "communication_app_tag fehlt"
grep -Eq 'opaque_tag' "$blob" || fail "opaque_tag fehlt"
grep -Eq 'mktemp' "$blob" || fail "Transaktionale temporäre Bearbeitung fehlt"
pass "Hyprland Ownership-/Shared-Tag-/Transaktionsregression"
