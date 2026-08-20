#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail(){ echo "FAIL: $*" >&2; exit 1; }
[[ -x "$ROOT_DIR/scripts/prepare_store_icons.sh" ]] || fail "icon prep missing"
[[ -x "$ROOT_DIR/scripts/manager_preflight.sh" ]] || fail "manager preflight missing"
grep -q 'manager_preflight.sh' "$ROOT_DIR/manager/shell.qml" || fail "QML startup does not launch preflight"
grep -q 'prepare_store_icons.sh' "$ROOT_DIR/scripts/manager_preflight.sh" || fail "preflight does not prepare cache"
grep -q 'store-icons-v6' "$ROOT_DIR/scripts/prepare_store_icons.sh" || fail "cache v6 missing"
grep -q 'raw.githubusercontent.com/homarr-labs/dashboard-icons/main/svg/' "$ROOT_DIR/scripts/prepare_store_icons.sh" || fail "deterministic Dashboard SVG source missing"
! grep -q 'cp .*local_file.*svg_target' "$ROOT_DIR/scripts/prepare_store_icons.sh" || fail "generic fallback must not poison store cache"
grep -q 'ICON_ID="google-gemini"' "$ROOT_DIR/apps/gemini.conf" || fail "gemini mapping"
grep -q 'ICON_ID="perplexity"' "$ROOT_DIR/apps/perplexity.conf" || fail "perplexity mapping"
grep -q 'ICON_ID="atlassian-trello"' "$ROOT_DIR/apps/trello.conf" || fail "trello mapping"
grep -q 'ICON_ID="mega-nz"' "$ROOT_DIR/apps/mega.conf" || fail "mega mapping"
grep -q 'ICON_PROVIDER="dashboard-icons-external-lobehub"' "$ROOT_DIR/apps/replit.conf" || fail "replit provider"
count=$(grep -Rl '^ICON_PROVIDER=' "$ROOT_DIR/apps"/*.conf | wc -l)
apps=$(ls "$ROOT_DIR"/apps/*.conf | wc -l)
[[ "$count" -eq "$apps" ]] || fail "not every builtin app has provider metadata ($count/$apps)"
echo "PASS: Phase16.1-fix2b icon pipeline ($apps apps)"
