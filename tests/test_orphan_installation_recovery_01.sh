#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$TMP/config"
export XDG_STATE_HOME="$TMP/state"
export XDG_DATA_HOME="$TMP/data"
export XDG_CACHE_HOME="$TMP/cache"
export XDG_RUNTIME_DIR="$TMP/runtime"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR" "$TMP/bin"
export PATH="$TMP/bin:/usr/bin:/bin"
export CAELESTIA_WEBAPPS_DISABLE_NETWORK=1

cat >"$TMP/bin/firefox" <<'EOF_FIREFOX'
#!/usr/bin/env bash
case "${1:-}" in
  --version) echo "Mozilla Firefox 153.0" ;;
  --help) printf '%s\n' '--profile PATH' '--new-instance' '--new-window URL' ;;
esac
exit 0
EOF_FIREFOX
cat >"$TMP/bin/hyprctl" <<'EOF_HYPRCTL'
#!/usr/bin/env bash
if [[ "${1:-}" == "clients" && "${2:-}" == "-j" ]]; then
    printf '%s\n' '[]'
elif [[ "${1:-}" == "configerrors" ]]; then
    printf '%s\n' 'no errors'
fi
exit 0
EOF_HYPRCTL
cat >"$TMP/bin/update-desktop-database" <<'EOF_CACHE'
#!/usr/bin/env bash
exit 0
EOF_CACHE
cat >"$TMP/bin/gtk-update-icon-cache" <<'EOF_CACHE'
#!/usr/bin/env bash
exit 0
EOF_CACHE
chmod +x "$TMP/bin/"*

CLI="$ROOT/bin/caelestia-webapps"
APP_ID="orphan-recovery-test"
cat >"$TMP/icon.svg" <<'EOF_ICON'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16"><circle cx="8" cy="8" r="7"/></svg>
EOF_ICON

payload="$(python3 - "$TMP/icon.svg" <<'PY_PAYLOAD'
import json, sys
print(json.dumps({
    "id": "orphan-recovery-test",
    "name": "Orphan Recovery Test",
    "url": "https://example.invalid/",
    "category": "ai",
    "iconMode": "local",
    "iconFile": sys.argv[1],
}))
PY_PAYLOAD
)"
"$CLI" user-create "$payload" >"$TMP/create.json"
"$CLI" install "$APP_ID" >"$TMP/install.json"

USER_DEF="$XDG_CONFIG_HOME/caelestia-webapps/apps/$APP_ID.conf"
METADATA="$HOME/.local/share/caelestia-webapps/apps/$APP_ID/installed.conf"
test -f "$USER_DEF"
test -f "$METADATA"
cp -- "$METADATA" "$TMP/installed.safe.conf"

# Simulate a legacy/manual definition loss without using the guarded product
# deletion command. This is the exact state the recovery projection addresses.
rm -f -- "$USER_DEF"
"$CLI" refresh >"$TMP/refresh.json"
"$CLI" list >"$TMP/list-orphan.json"
"$CLI" runtime >"$TMP/runtime-orphan.json"

python3 - "$TMP/list-orphan.json" "$TMP/runtime-orphan.json" "$HOME/.local/share/caelestia-webapps/catalog.json" "$HOME/.local/share/caelestia-webapps/applet-registry.json" <<'PY_ASSERT'
import json, sys
listing = json.load(open(sys.argv[1], encoding="utf-8"))["data"]
runtime = json.load(open(sys.argv[2], encoding="utf-8"))["data"]
catalog = json.load(open(sys.argv[3], encoding="utf-8"))
registry = json.load(open(sys.argv[4], encoding="utf-8"))
app_id = "orphan-recovery-test"

assert all(app.get("id") != app_id for app in listing["apps"])
matches = [app for app in listing["orphanInstallations"] if app.get("id") == app_id]
assert len(matches) == 1
orphan = matches[0]
assert orphan["installed"] is True
assert orphan["source"] == "orphan"
assert orphan["orphaned"] is True
assert orphan["recovery"]["canRestore"] is True
assert orphan["capabilities"] == {
    "launch": False, "setup": False, "install": False, "repair": False,
    "uninstall": True, "edit": False,
}
assert app_id in runtime["apps"]
assert all(app.get("id") != app_id and app.get("source") != "orphan" for app in catalog["apps"])
assert all(app.get("id") != app_id for app in registry["apps"])
PY_ASSERT

# A safely attributable former user app can be adopted without reinstalling or
# deleting its profile. It immediately returns to the regular catalog.
"$CLI" orphan-restore "$APP_ID" >"$TMP/restore.json"
test -f "$USER_DEF"
test -f "$METADATA"
"$CLI" list >"$TMP/list-restored.json"
python3 - "$TMP/restore.json" "$TMP/list-restored.json" <<'PY_RESTORED'
import json, sys
result = json.load(open(sys.argv[1], encoding="utf-8"))
listing = json.load(open(sys.argv[2], encoding="utf-8"))["data"]
assert result["ok"] is True and result["command"] == "orphan-restore"
apps = {app["id"]: app for app in listing["apps"]}
assert apps["orphan-recovery-test"]["source"] == "user"
assert apps["orphan-recovery-test"]["installed"] is True
assert not listing["orphanInstallations"]
PY_RESTORED

# Lose the restored definition once more to exercise the independent cleanup
# choice against the same installed profile.
rm -f -- "$USER_DEF"
"$CLI" refresh >"$TMP/refresh-after-restore.json"
"$CLI" orphan-uninstall "$APP_ID" >"$TMP/uninstall.json"
python3 - "$TMP/uninstall.json" <<'PY_RESULT'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload["ok"] is True
assert payload["data"] == {"appId": "orphan-recovery-test", "removed": True, "orphaned": True}
PY_RESULT

test ! -e "$HOME/.local/share/caelestia-webapps/apps/$APP_ID"
test ! -e "$HOME/.local/bin/caelestia-webapp-$APP_ID"
test ! -e "$HOME/.local/bin/caelestia-webapp-$APP_ID-setup"
test ! -e "$HOME/.local/share/applications/caelestia-webapp-$APP_ID.desktop"
test ! -e "$HOME/.local/share/icons/hicolor/scalable/apps/$APP_ID.svg"
"$CLI" list >"$TMP/list-clean.json"
python3 - "$TMP/list-clean.json" <<'PY_CLEAN'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))["data"]
assert not payload["orphanInstallations"]
PY_CLEAN

# Tampered metadata is neither exposed nor accepted for cleanup. In
# particular, an attacker cannot redirect deletion to an arbitrary path.
mkdir -p "$HOME/.local/share/caelestia-webapps/apps/$APP_ID"
cp -- "$TMP/installed.safe.conf" "$METADATA"
sed -i "s|^LAUNCHER=.*|LAUNCHER=\"$TMP/escape\"|" "$METADATA"
touch "$TMP/escape"
"$CLI" list >"$TMP/list-tampered.json"
python3 - "$TMP/list-tampered.json" <<'PY_TAMPERED'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))["data"]
assert not payload["orphanInstallations"]
PY_TAMPERED
set +e
"$CLI" orphan-uninstall "$APP_ID" >"$TMP/tampered-result.json"
rc=$?
set -e
test "$rc" -ne 0
test -f "$TMP/escape"

echo "PASS: orphan installation restore/cleanup is isolated, explicit, and path-safe"
