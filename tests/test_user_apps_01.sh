#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$TMP/config"
mkdir -p "$HOME"

API="$ROOT/bin/caelestia-webapps"

payload='{"id":"example-app","name":"Example App","url":"https://example.com/","category":"ai","iconUrl":"https://example.com/icon.svg"}'

"$API" user-create "$payload" >"$TMP/create.json"
python3 - "$TMP/create.json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
assert p["apiVersion"] == 1 and p["ok"] is True and p["command"] == "user-create"
PY

DEF="$XDG_CONFIG_HOME/caelestia-webapps/apps/example-app.conf"
[[ -f "$DEF" ]]
grep -Fq 'APP_SOURCE="user"' "$DEF"
grep -Fq "APP_ID=example-app" "$DEF"

"$API" list >"$TMP/list.json"
python3 - "$TMP/list.json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
apps={a["id"]:a for a in p["data"]["apps"]}
a=apps["example-app"]
assert a["source"] == "user"
assert a["capabilities"]["edit"] is True
assert a["installed"] is False
PY

updated='{"id":"example-app","name":"Example App 2","url":"https://example.org/","category":"messaging","iconUrl":"https://example.org/icon.svg"}'
"$API" user-update example-app "$updated" >"$TMP/update.json"
"$API" list >"$TMP/list2.json"
python3 - "$TMP/list2.json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
a=next(a for a in p["data"]["apps"] if a["id"]=="example-app")
assert a["name"]=="Example App 2"
assert a["category"]=="messaging"
assert a["url"]=="https://example.org/"
PY

"$API" user-delete example-app >"$TMP/delete.json"
[[ ! -e "$DEF" ]]
"$API" list >"$TMP/list3.json"
python3 - "$TMP/list3.json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
assert not any(a["id"]=="example-app" for a in p["data"]["apps"])
PY

# Built-in IDs may never be shadowed.
if "$API" user-create '{"id":"chatgpt","name":"Oops","url":"https://example.com","category":"ai","iconUrl":"https://example.com/a.svg"}' >/dev/null 2>&1; then
  echo "builtin shadow unexpectedly allowed" >&2
  exit 1
fi

echo "PASS: user app create/update/delete persists outside project and merges into Catalog v2"
