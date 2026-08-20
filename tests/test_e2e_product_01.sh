#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$TMP/config"
export XDG_STATE_HOME="$TMP/state"
export XDG_DATA_HOME="$TMP/data"
export XDG_CACHE_HOME="$TMP/cache"
export XDG_RUNTIME_DIR="$TMP/runtime"

mkdir -p \
  "$HOME" \
  "$XDG_CONFIG_HOME" \
  "$XDG_STATE_HOME" \
  "$XDG_DATA_HOME" \
  "$XDG_CACHE_HOME" \
  "$XDG_RUNTIME_DIR"

export PATH="$TMP/bin:$PATH"
mkdir -p "$TMP/bin"

# The ChatGPT artifact runtime injects a sitecustomize warmup into every Python
# process. The product only needs the Python standard library, so the isolated
# E2E environment deliberately bypasses external site hooks.
cat >"$TMP/bin/python3" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/python3 -S "$@"
EOF
chmod +x "$TMP/bin/python3"

# ------------------------------------------------------------------
# Stub external desktop/runtime commands.
# We test our product boundary, not Firefox/Hyprland themselves.
# ------------------------------------------------------------------

cat >"$TMP/bin/firefox" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
case "${1:-}" in
  --version) echo "Mozilla Firefox 153.0.4"; exit 0 ;;
  --help)
    cat <<'HELP'
--profile PATH
--new-instance
--new-window URL
HELP
    exit 0
    ;;
esac
printf '%s\n' "$*" >>"${E2E_FIREFOX_LOG:?}"
exit 0
EOF
chmod +x "$TMP/bin/firefox"

cat >"$TMP/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${1:-}" == "clients" && "${2:-}" == "-j" ]]; then
  printf '%s\n' "${E2E_HYPR_CLIENTS_JSON:-[]}"
  exit 0
fi

# Dispatches succeed in this isolated contract test.
printf '%s\n' "$*" >>"${E2E_HYPR_LOG:?}"
exit 0
EOF
chmod +x "$TMP/bin/hyprctl"

cat >"$TMP/bin/xdg-open" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TMP/bin/xdg-open"

export E2E_FIREFOX_LOG="$TMP/firefox.log"
export E2E_HYPR_LOG="$TMP/hypr.log"
: >"$E2E_FIREFOX_LOG"
: >"$E2E_HYPR_LOG"

# Keep the product fully local in the test.
export CAELESTIA_WEBAPPS_DISABLE_NETWORK=1

CLI="$ROOT/bin/caelestia-webapps"

json_assert() {
  local file="$1"
  local expr="$2"
  python3 - "$file" "$expr" <<'PY'
import json,sys
path,expr=sys.argv[1:3]
obj=json.load(open(path))
ns={"obj":obj}
assert eval(expr, {}, ns), f"assertion failed: {expr}\n{obj}"
PY
}

# ------------------------------------------------------------------
# 1. Fresh product can build/read its catalog without any plugin API.
# ------------------------------------------------------------------
"$CLI" list >"$TMP/list-initial.json"
json_assert "$TMP/list-initial.json" 'obj["ok"] is True'
json_assert "$TMP/list-initial.json" 'obj["apiVersion"] == 1'
json_assert "$TMP/list-initial.json" 'any(a["id"] == "chatgpt" for a in obj["data"]["apps"])'

# There must be no active dependency on the old sidebar-patching architecture.
! grep -R -E \
  'OriginalContent|native-drawer-poc|quickshell/caelestia/sidebar|modules/sidebar/Content\.qml' \
  "$ROOT/bin" "$ROOT/lib" "$ROOT/scripts" "$ROOT/manager" \
  >/dev/null 2>&1

# ------------------------------------------------------------------
# 2. Create a user app through the stable CLI/JSON boundary.
# ------------------------------------------------------------------
cat >"$TMP/e2e-icon.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <circle cx="16" cy="16" r="14"/>
</svg>
SVG

cat >"$TMP/create.json" <<JSON
{
  "id": "e2e-home-assistant",
  "name": "E2E Home Assistant",
  "url": "https://homeassistant.local/",
  "category": "messaging",
  "iconMode": "local",
  "iconFile": "$TMP/e2e-icon.svg"
}
JSON

payload="$(cat "$TMP/create.json")"
"$CLI" user-create "$payload" >"$TMP/create-result.json"
json_assert "$TMP/create-result.json" 'obj["ok"] is True'

APP_ID="$(python3 - "$TMP/create-result.json" <<'PY'
import json,sys
o=json.load(open(sys.argv[1]))
data=o.get("data",{})
print(data.get("id") or data.get("appId") or "e2e-home-assistant")
PY
)"

[[ -n "$APP_ID" ]]
USER_DEF="$XDG_CONFIG_HOME/caelestia-webapps/apps/$APP_ID.conf"
test -f "$USER_DEF"

"$CLI" list >"$TMP/list-user.json"
python3 - "$TMP/list-user.json" "$APP_ID" <<'PY'
import json,sys
o=json.load(open(sys.argv[1]))
app_id=sys.argv[2]
apps={a["id"]:a for a in o["data"]["apps"]}
assert app_id in apps
a=apps[app_id]
assert a["source"]=="user"
assert a["ownership"]["owner"]=="user"
assert a["ownership"]["definitionMutable"] is True
PY

# ------------------------------------------------------------------
# 3. Install through the engine.
# ------------------------------------------------------------------
"$CLI" install "$APP_ID" >"$TMP/install.json"
json_assert "$TMP/install.json" 'obj["ok"] is True'

"$CLI" status "$APP_ID" >"$TMP/status-installed.json"
json_assert "$TMP/status-installed.json" 'obj["ok"] is True'
python3 - "$TMP/status-installed.json" <<'PY'
import json,sys
o=json.load(open(sys.argv[1]))
d=o["data"]
# Preserve compatibility with either top-level installed or nested app.
installed = d.get("installed")
if installed is None and isinstance(d.get("app"),dict):
    installed=d["app"].get("installed")
assert installed is True, d
PY

# Desktop entry / launcher is the durable installed state.
test -f "$HOME/.local/share/applications/caelestia-webapp-$APP_ID.desktop"

# ------------------------------------------------------------------
# 4. Setup remains a separate visible Firefox-profile flow.
# ------------------------------------------------------------------
"$CLI" setup "$APP_ID" >"$TMP/setup.json"
json_assert "$TMP/setup.json" 'obj["ok"] is True'

# Setup is async; give the stub a moment to receive the launch.
for _ in $(seq 1 20); do
  [[ -s "$E2E_FIREFOX_LOG" ]] && break
  sleep 0.05
done
grep -Fq -- '--profile' "$E2E_FIREFOX_LOG"

# ------------------------------------------------------------------
# 5. Launch while no matching window exists -> Firefox is launched.
# ------------------------------------------------------------------
export E2E_HYPR_CLIENTS_JSON='[]'
before_lines="$(wc -l <"$E2E_FIREFOX_LOG")"
"$CLI" launch "$APP_ID" >"$TMP/launch-closed.json"
json_assert "$TMP/launch-closed.json" 'obj["ok"] is True'

for _ in $(seq 1 20); do
  after_lines="$(wc -l <"$E2E_FIREFOX_LOG")"
  (( after_lines > before_lines )) && break
  sleep 0.05
done
after_lines="$(wc -l <"$E2E_FIREFOX_LOG")"
(( after_lines > before_lines ))

# ------------------------------------------------------------------
# 6. Matching window exists -> focus path, NEVER spawn duplicate.
# ------------------------------------------------------------------
WINDOW_CLASS="$(
  python3 - "$ROOT/catalog.json" "$APP_ID" <<'PY' 2>/dev/null || true
import json,sys
p=sys.argv[1]; app_id=sys.argv[2]
try:
    o=json.load(open(p))
except Exception:
    raise SystemExit
for a in o.get("apps",[]):
    if a.get("id")==app_id:
        print(a.get("windowClass") or app_id)
        break
PY
)"
[[ -n "$WINDOW_CLASS" ]] || WINDOW_CLASS="$APP_ID"

export E2E_HYPR_CLIENTS_JSON="$(
python3 - "$WINDOW_CLASS" <<'PY'
import json,sys
cls=sys.argv[1]
print(json.dumps([{
  "address":"0xE2E",
  "class":cls,
  "initialClass":cls,
  "title":"E2E",
  "workspace":{"id":1,"name":"1"}
}]))
PY
)"

before_lines="$(wc -l <"$E2E_FIREFOX_LOG")"
"$CLI" launch "$APP_ID" >"$TMP/launch-running.json"
json_assert "$TMP/launch-running.json" 'obj["ok"] is True'
sleep 0.15
after_lines="$(wc -l <"$E2E_FIREFOX_LOG")"
[[ "$before_lines" == "$after_lines" ]]

# The focus dispatch should have been attempted.
grep -Eq 'focus|address:0xE2E' "$E2E_HYPR_LOG"

# ------------------------------------------------------------------
# 7. Repair is idempotent and preserves user ownership.
# ------------------------------------------------------------------
cp "$USER_DEF" "$TMP/user-before.conf"
"$CLI" repair "$APP_ID" >"$TMP/repair.json"
json_assert "$TMP/repair.json" 'obj["ok"] is True'
cmp "$USER_DEF" "$TMP/user-before.conf"

# ------------------------------------------------------------------
# 8. Dynamic Caelestia theme bridge works independently of Shell plugin API.
# ------------------------------------------------------------------
mkdir -p "$XDG_STATE_HOME/caelestia"
cat >"$XDG_STATE_HOME/caelestia/scheme.json" <<'JSON'
{
  "name":"e2e",
  "mode":"light",
  "colours":{
    "background":"fdf8f7",
    "surface":"fdf8f7",
    "surfaceContainerLowest":"ffffff",
    "surfaceContainerLow":"f7f2f1",
    "surfaceContainer":"f1eceb",
    "surfaceContainerHigh":"ebe6e5",
    "surfaceContainerHighest":"e5e0df",
    "onSurface":"1c1b1b",
    "onSurfaceVariant":"494847",
    "outline":"7a7777",
    "outlineVariant":"cbc6c5",
    "primary":"8c4a5c",
    "onPrimary":"ffffff",
    "secondary":"74565e",
    "secondaryContainer":"ffd9e2",
    "onSecondaryContainer":"2b151b",
    "tertiary":"7c5733",
    "error":"ba1a1a",
    "onError":"ffffff",
    "errorContainer":"ffdad6",
    "onErrorContainer":"410002",
    "scrim":"000000"
  }
}
JSON

"$ROOT/scripts/caelestia_theme_bridge.py"
test -f "$XDG_CONFIG_HOME/caelestia/templates/caelestia-webapps.json"
test -f "$XDG_STATE_HOME/caelestia/theme/caelestia-webapps.json"

python3 - "$XDG_STATE_HOME/caelestia/theme/caelestia-webapps.json" <<'PY'
import json,sys
o=json.load(open(sys.argv[1]))
assert o["mode"]=="light"
assert o["primary"]=="#8c4a5c"
assert o["onSurface"]=="#1c1b1b"
PY

# ------------------------------------------------------------------
# 9. Uninstall removes runtime integration but preserves user definition.
# ------------------------------------------------------------------
export E2E_HYPR_CLIENTS_JSON='[]'
"$CLI" uninstall "$APP_ID" >"$TMP/uninstall.json"
json_assert "$TMP/uninstall.json" 'obj["ok"] is True'
test ! -f "$HOME/.local/share/applications/caelestia-webapp-$APP_ID.desktop"
test -f "$USER_DEF"

"$CLI" status "$APP_ID" >"$TMP/status-uninstalled.json"
json_assert "$TMP/status-uninstalled.json" 'obj["ok"] is True'
python3 - "$TMP/status-uninstalled.json" <<'PY'
import json,sys
o=json.load(open(sys.argv[1]))
d=o["data"]
installed=d.get("installed")
if installed is None and isinstance(d.get("app"),dict):
    installed=d["app"].get("installed")
assert installed is False, d
PY

# ------------------------------------------------------------------
# 10. Catalog removal explicitly deletes ONLY the user definition.
# ------------------------------------------------------------------
"$CLI" user-delete "$APP_ID" >"$TMP/delete.json"
json_assert "$TMP/delete.json" 'obj["ok"] is True'
test ! -f "$USER_DEF"

"$CLI" list >"$TMP/list-final.json"
python3 - "$TMP/list-final.json" "$APP_ID" <<'PY'
import json,sys
o=json.load(open(sys.argv[1]))
app_id=sys.argv[2]
assert all(a["id"] != app_id for a in o["data"]["apps"])
assert any(a["id"] == "chatgpt" for a in o["data"]["apps"])
PY

# ------------------------------------------------------------------
# 11. User-space cleanup did not mutate package-owned built-ins.
# ------------------------------------------------------------------
test -f "$ROOT/apps/chatgpt.conf"

echo "PASS: full standalone product lifecycle works without Caelestia plugin API"
