#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_RUNTIME_DIR="$TMP/run"
export CAELESTIA_WEBAPPS_LOCK_TIMEOUT_SECONDS=2
mkdir -p "$HOME" "$XDG_RUNTIME_DIR/caelestia-webapps"
LOCK="$XDG_RUNTIME_DIR/caelestia-webapps/mutation.lock"
(
  exec 8>"$LOCK"
  flock -x 8
  echo ready >"$TMP/ready"
  sleep 0.5
) &
holder=$!
for _ in {1..50}; do [[ -f "$TMP/ready" ]] && break; sleep 0.02; done
start=$(python3 - <<'PY'
import time
print(time.monotonic())
PY
)
"$ROOT/bin/caelestia-webapps" list >"$TMP/list.json"
end=$(python3 - <<'PY'
import time
print(time.monotonic())
PY
)
wait "$holder"
python3 - "$TMP/list.json" "$start" "$end" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
elapsed=float(sys.argv[3])-float(sys.argv[2])
assert p['ok'] is True
assert elapsed >= 0.35, elapsed
PY
echo "PASS: catalog read waits for writer and never crosses the mutation boundary"
