#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_RUNTIME_DIR="$TMP/run"
export CAELESTIA_WEBAPPS_LOCK_TIMEOUT_SECONDS=0.2
mkdir -p "$HOME" "$XDG_RUNTIME_DIR/caelestia-webapps"
LOCK="$XDG_RUNTIME_DIR/caelestia-webapps/mutation.lock"
(
  exec 8>"$LOCK"
  flock -x 8
  echo ready >"$TMP/ready"
  sleep 2
) &
holder=$!
for _ in {1..50}; do [[ -f "$TMP/ready" ]] && break; sleep 0.02; done
set +e
"$ROOT/install.sh" chatgpt >"$TMP/out" 2>"$TMP/err"
rc=$?
set -e
kill "$holder" 2>/dev/null || true
wait "$holder" 2>/dev/null || true
[[ $rc -eq 75 ]] || { echo "expected direct install exit 75, got $rc" >&2; cat "$TMP/err" >&2; exit 1; }
grep -Fq 'CAELESTIA_WEBAPPS_LOCK_BUSY' "$TMP/err"
[[ ! -e "$HOME/.local/share/caelestia-webapps/apps/chatgpt/installed.conf" ]]
echo "PASS: direct engine scripts share the same cross-process mutation lock"
