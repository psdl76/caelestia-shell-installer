#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"

export HOME="$TEST_ROOT/home"
export XDG_CONFIG_HOME="$TEST_ROOT/config"
export XDG_DATA_HOME="$HOME/.local/share"
mkdir -p "$XDG_DATA_HOME/caelestia-webapps/apps/chatgpt" "$XDG_CONFIG_HOME/caelestia-webapps/apps"
DATA_ROOT="$XDG_DATA_HOME/caelestia-webapps"
CATALOG_FILE="$DATA_ROOT/catalog.json"
APP_DEF_DIR="$ROOT_DIR/apps"
USER_APP_DEF_DIR="$XDG_CONFIG_HOME/caelestia-webapps/apps"

cat > "$DATA_ROOT/apps/chatgpt/installed.conf" <<'CFG'
APP_ID="chatgpt"
PACKAGE_VERSION="test"
CFG

ok(){ :; }
info(){ :; }
warn(){ :; }
die(){ echo "$*" >&2; exit 1; }
require_command(){ command -v "$1" >/dev/null || exit 1; }
verify_file(){ [[ -f "$1" ]] || exit 1; }
verify_contains(){ grep -Fq "$2" "$1" || exit 1; }

source "$ROOT_DIR/lib/catalog.sh"
generate_catalog

assert_file "$CATALOG_FILE"
python3 - "$CATALOG_FILE" <<'PY'
import json, sys
p=sys.argv[1]
with open(p, encoding="utf-8") as f: data=json.load(f)
assert data["schemaVersion"] == 2
apps=data.get("apps", [])
ids={a["id"] for a in apps}
assert "chatgpt" in ids, ids
PY
pass "Katalog wird isoliert erzeugt und enthält installierte App"
