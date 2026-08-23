#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_RUNTIME_DIR="$TMP/runtime"
export XDG_STATE_HOME="$TMP/custom-state"
export CAELESTIA_WEBAPPS_DISABLE_NETWORK=1
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" \
    "$XDG_RUNTIME_DIR" "$XDG_STATE_HOME/caelestia-webapps"

PREFIX="$TMP/prefix"
"$ROOT/packaging/install-core.sh" --prefix "$PREFIX" >/dev/null
RUNTIME="$PREFIX/lib/caelestia-webapps"
STATE="$XDG_STATE_HOME/caelestia-webapps"
printf '%s\n' '{"youtube":"on"}' > "$STATE/applets.json"

"$RUNTIME/upgrade.sh" --preflight >/dev/null

python3 - "$STATE/applets.json" <<'PY'
import json, sys
assert json.load(open(sys.argv[1])) == {
    "schemaVersion": 1,
    "enabled": {"youtube": True},
}
PY
[[ -s "$STATE/runtime-state-migration-last.json" ]]
[[ -s "$STATE/logs/repair.log" ]]
[[ ! -e "$HOME/.local/state/caelestia-webapps/runtime-state-migration-last.json" ]]

echo "PASS: repair and upgrade keep migration state under XDG_STATE_HOME"
