#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_RUNTIME_DIR="$TMP/run"
export CAELESTIA_WEBAPPS_LOCK_TIMEOUT_SECONDS=0.2
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"

# Hold the exact global mutation lock in another process.
LOCK="$XDG_RUNTIME_DIR/caelestia-webapps/mutation.lock"
mkdir -p "$(dirname "$LOCK")"
(
  exec 8>"$LOCK"
  flock -x 8
  echo ready >"$TMP/ready"
  sleep 2
) &
holder=$!
for _ in {1..50}; do [[ -f "$TMP/ready" ]] && break; sleep 0.02; done

set +e
out="$($ROOT/bin/caelestia-webapps user-create '{"id":"lock-test","name":"Lock Test","url":"https://example.com","category":"ai","iconMode":"auto"}' 2>/dev/null)"
rc=$?
set -e
kill "$holder" 2>/dev/null || true
wait "$holder" 2>/dev/null || true

[[ $rc -eq 31 ]] || { echo "expected exit 31, got $rc" >&2; echo "$out" >&2; exit 1; }
python3 - "$out" <<'PY2'
import json,sys
p=json.loads(sys.argv[1])
assert p['ok'] is False
assert p['error']['code']=='action_busy'
PY2

echo "PASS: concurrent mutation returns stable action_busy JSON"
