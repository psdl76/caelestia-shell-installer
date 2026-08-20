#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail(){ echo "FAIL: $*" >&2; exit 1; }

grep -Fq '"$ROOT_DIR/repair.sh" --preflight --quiet' "$ROOT_DIR/manager.sh" || fail "manager preflight missing"
grep -Fq '[[ "$last_repaired" == "$CURRENT_VERSION" ]] || preflight_needed=true' "$ROOT_DIR/repair.sh" || fail "package version check missing"
grep -Fq '[[ "$(installed_version_for "$id")" == "$CURRENT_VERSION" ]] || preflight_needed=true' "$ROOT_DIR/repair.sh" || fail "installed version check missing"
grep -Fq '[[ -x "$HOME/.local/bin/caelestia-webapp-$id" ]] || preflight_needed=true' "$ROOT_DIR/repair.sh" || fail "launcher check missing"
grep -Fq '[[ -x "$HOME/.local/bin/caelestia-webapp-$id-setup" ]] || preflight_needed=true' "$ROOT_DIR/repair.sh" || fail "setup launcher check missing"
grep -Fq 'Der Manager wurde nicht gestartet' "$ROOT_DIR/manager.sh" || fail "fail-closed behavior missing"
bash -n "$ROOT_DIR/manager.sh"
bash -n "$ROOT_DIR/repair.sh"
echo "PASS: manager preflight self-heals stale generated state before GUI startup"
