#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/caelestia-webapps/apps"

ROOT_DIR="$ROOT"
APP_DEF_DIR="$ROOT/apps"
USER_APP_DEF_DIR="$XDG_CONFIG_HOME/caelestia-webapps/apps"
DATA_ROOT="$XDG_DATA_HOME/caelestia-webapps"
source "$ROOT/lib/common.sh"
source "$ROOT/lib/catalog.sh"

generate_catalog >/dev/null
[[ -s "$DATA_ROOT/catalog.json" ]]
[[ -s "$DATA_ROOT/applet-registry.json" ]]
python3 "$ROOT/scripts/validate_applet_registry.py" \
  "$DATA_ROOT/catalog.json" "$DATA_ROOT/applet-registry.json"
python3 - "$DATA_ROOT/applet-registry.json" <<'PY'
import json,sys
j=json.load(open(sys.argv[1]))
y=next(a for a in j['apps'] if a['id']=='youtube')
assert y['matchHosts']==['youtube.com'], y
assert y['support']=='supported'
PY

grep -Fq 'generate_catalog' "$ROOT/install.sh"
grep -Fq 'generate_catalog' "$ROOT/uninstall.sh"
grep -Fq 'generate_catalog' "$ROOT/repair.sh"
grep -Fq 'source "$ROOT_DIR/lib/catalog.sh"' "$ROOT/catalog.sh"

echo "PASS: Phase16.4 installer/uninstaller registry coupling"
