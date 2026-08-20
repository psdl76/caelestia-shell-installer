#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$TMP/config"
mkdir -p "$XDG_CONFIG_HOME/caelestia-webapps/apps"

# User definition must live outside package tree.
cat >"$XDG_CONFIG_HOME/caelestia-webapps/apps/example-user.conf" <<'EOF'
APP_SOURCE="user"
APP_ID=example-user
APP_NAME="Example User"
APP_GENERIC_NAME="Web Application"
APP_COMMENT="Example"
APP_URL="https://example.com"
APP_CATEGORIES="Network;"
APP_KEYWORDS="Example;"
APP_CATALOG_CATEGORY="ai"
MOZ_APP_REMOTINGNAME=example-user
WINDOW_CLASS=example-user
ICON_NAME=example-user
ICON_URL="https://example.com/icon.svg"
USE_OPAQUE_TAG="true"
NOTIFICATION_MATCH="Example User"
EOF

"$ROOT/bin/caelestia-webapps" list >"$TMP/list.json"

python3 - "$TMP/list.json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
apps={a["id"]:a for a in p["data"]["apps"]}
u=apps["example-user"]
assert u["source"]=="user"
assert u["ownership"]["owner"]=="user"
assert u["ownership"]["definitionMutable"] is True
assert u["ownership"]["survivesUpgrade"] is True
assert u["ownership"]["removableFromCatalog"] is True

b=apps["chatgpt"]
assert b["source"]=="builtin"
assert b["ownership"]["owner"]=="package"
assert b["ownership"]["definitionMutable"] is False
assert b["ownership"]["survivesUpgrade"] is False
assert b["ownership"]["removableFromCatalog"] is False
PY

# Audit must accept separated roots.
"$ROOT/scripts/ownership_audit.py" >"$TMP/audit.json"
python3 - "$TMP/audit.json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
assert p["ok"] is True
assert p["userCount"] == 1
assert p["shadowedIds"] == []
PY

# Shadowing a built-in is forbidden.
cp "$XDG_CONFIG_HOME/caelestia-webapps/apps/example-user.conf" \
   "$XDG_CONFIG_HOME/caelestia-webapps/apps/chatgpt.conf"

if "$ROOT/scripts/ownership_audit.py" >/dev/null 2>&1; then
    echo "shadowing unexpectedly accepted" >&2
    exit 1
fi

echo "PASS: package-owned built-ins and user-owned definitions have separate persistent ownership"
