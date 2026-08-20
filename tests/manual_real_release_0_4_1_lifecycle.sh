#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
[[ "${1:-}" == "--confirm-real-home" ]] || {
    echo "Refusing to modify the real HOME without --confirm-real-home" >&2
    exit 2
}
[[ "$(<"$ROOT/VERSION")" == "0.4.1" ]] || {
    echo "This manual gate is pinned to release 0.4.1" >&2
    exit 2
}
[[ -n "${HOME:-}" && "$HOME" == /* && "$HOME" != "/" ]] || {
    echo "Unsafe HOME: ${HOME:-unset}" >&2
    exit 2
}

PREFIX="$HOME/.local"
CORE="$PREFIX/lib/caelestia-webapps"
CLI="$PREFIX/bin/caelestia-webapps"
TEST_ID="caelestia-release-e2e"
TEST_ICON="$ROOT/assets/icons/webapp-generic.svg"
BACKUP="$(mktemp -d /tmp/caelestia-webapps-real-0.4.1.XXXXXX)"
RESTORED=0

[[ -f "$CORE/PACKAGE-METADATA" ]] || { echo "Existing rootless core metadata is missing" >&2; exit 1; }
grep -Fqx 'PACKAGE_ID=caelestia-webapps' "$CORE/PACKAGE-METADATA"
[[ -f "$TEST_ICON" ]]

target_paths=(
    "$HOME/.config/caelestia-webapps/apps/$TEST_ID.conf"
    "$HOME/.local/share/caelestia-webapps/apps/$TEST_ID"
    "$HOME/.local/bin/caelestia-webapp-$TEST_ID"
    "$HOME/.local/bin/caelestia-webapp-$TEST_ID-setup"
    "$HOME/.local/share/applications/caelestia-webapp-$TEST_ID.desktop"
    "$HOME/.local/share/icons/hicolor/scalable/apps/$TEST_ID.svg"
)
for target in "${target_paths[@]}"; do
    [[ ! -e "$target" ]] || { echo "Test target already exists: $target" >&2; exit 1; }
done

protected_paths=(
    ".local/lib/caelestia-webapps"
    ".local/bin/caelestia-webapps"
    ".local/bin/caelestia-webapps-manager"
    ".local/share/applications/caelestia-webapps-manager.desktop"
    ".local/share/licenses/caelestia-webapps"
    ".config/caelestia-webapps"
    ".local/state/caelestia-webapps"
    ".local/share/caelestia-webapps/catalog.json"
    ".local/share/caelestia-webapps/applet-registry.json"
    ".config/hypr/hyprland/rules.lua"
    ".config/hypr/hyprland/keybinds.lua"
)

for relative in "${protected_paths[@]}"; do
    source_path="$HOME/$relative"
    if [[ -e "$source_path" || -L "$source_path" ]]; then
        mkdir -p "$BACKUP/home/$(dirname -- "$relative")"
        cp -a -- "$source_path" "$BACKUP/home/$relative"
    fi
done

find "$HOME/.local/share/caelestia-webapps/apps" \
    -mindepth 2 -maxdepth 2 -type f -name installed.conf -print0 2>/dev/null \
    | sort -z | xargs -0 -r sha256sum > "$BACKUP/installed-before.sha256"
find "$HOME/.local/share/caelestia-webapps/apps" \
    -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
    | sort > "$BACKUP/installed-before.txt"

restore_previous_state() {
    [[ "$RESTORED" -eq 0 ]] || return 0
    RESTORED=1
    set +e

    for target in "${target_paths[@]}"; do
        rm -rf -- "$target"
    done
    for relative in "${protected_paths[@]}"; do
        target="$HOME/$relative"
        rm -rf -- "$target"
        if [[ -e "$BACKUP/home/$relative" || -L "$BACKUP/home/$relative" ]]; then
            mkdir -p "$(dirname -- "$target")"
            cp -a -- "$BACKUP/home/$relative" "$target"
        fi
    done
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null 2>&1 || true
    fi
    set -e
}

on_exit() {
    result=$?
    restore_previous_state
    if [[ "$result" -ne 0 ]]; then
        echo "FAILED: real lifecycle test; previous state restored from $BACKUP" >&2
    fi
    exit "$result"
}
trap on_exit EXIT

echo "[real] backup: $BACKUP"
echo "[real] installing candidate core 0.4.1"
"$ROOT/packaging/install-core.sh" --prefix "$PREFIX"
grep -Fqx 'PACKAGE_VERSION=0.4.1' "$CORE/PACKAGE-METADATA"
[[ "$(<"$CORE/VERSION")" == "0.4.1" ]]

echo "[real] validating installed CLI"
"$CLI" list > "$BACKUP/candidate-list.json"
python3 - "$BACKUP/candidate-list.json" <<'PY'
import json
import sys

payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload.get("apiVersion") == 1
assert payload.get("ok") is True
assert payload.get("command") == "list"
PY

printf -v payload \
    '{"id":"%s","name":"Caelestia Release E2E","url":"https://release-e2e.invalid/","category":"development","iconMode":"local","iconFile":"%s","genericName":"Release lifecycle test","comment":"Temporärer Release-Lifecycle-Test"}' \
    "$TEST_ID" "$TEST_ICON"

echo "[real] creating and installing temporary WebApp"
"$CLI" user-create "$payload" > "$BACKUP/user-create.json"
"$CLI" install "$TEST_ID" > "$BACKUP/install.json"
"$CLI" status "$TEST_ID" > "$BACKUP/status-installed.json"
python3 - "$BACKUP/install.json" "$BACKUP/status-installed.json" <<'PY'
import json
import sys

installed = json.load(open(sys.argv[1], encoding="utf-8"))
status = json.load(open(sys.argv[2], encoding="utf-8"))
assert installed.get("ok") is True
assert status.get("ok") is True
data = status.get("data", {})
value = data.get("installed")
if value is None and isinstance(data.get("app"), dict):
    value = data["app"].get("installed")
assert value is True
PY
[[ -f "$HOME/.local/share/caelestia-webapps/apps/$TEST_ID/installed.conf" ]]
[[ -x "$HOME/.local/bin/caelestia-webapp-$TEST_ID" ]]
[[ -f "$HOME/.local/share/applications/caelestia-webapp-$TEST_ID.desktop" ]]

echo "[real] uninstalling and deleting temporary WebApp"
"$CLI" uninstall "$TEST_ID" > "$BACKUP/uninstall.json"
"$CLI" user-delete "$TEST_ID" > "$BACKUP/user-delete.json"
for target in "${target_paths[@]}"; do
    [[ ! -e "$target" ]] || { echo "Residual test artifact: $target" >&2; exit 1; }
done

echo "[real] uninstalling candidate core"
"$ROOT/packaging/uninstall-core.sh" --prefix "$PREFIX"
[[ ! -e "$CORE" ]]
[[ ! -e "$PREFIX/bin/caelestia-webapps" ]]
[[ ! -e "$PREFIX/bin/caelestia-webapps-manager" ]]

echo "[real] restoring previous installation and state"
restore_previous_state

find "$HOME/.local/share/caelestia-webapps/apps" \
    -mindepth 2 -maxdepth 2 -type f -name installed.conf -print0 2>/dev/null \
    | sort -z | xargs -0 -r sha256sum > "$BACKUP/installed-after.sha256"
find "$HOME/.local/share/caelestia-webapps/apps" \
    -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null \
    | sort > "$BACKUP/installed-after.txt"
cmp "$BACKUP/installed-before.sha256" "$BACKUP/installed-after.sha256"
cmp "$BACKUP/installed-before.txt" "$BACKUP/installed-after.txt"
grep -Fqx 'PACKAGE_VERSION=0.4.0-phase15.1-firefox-fix1' "$CORE/PACKAGE-METADATA"

trap - EXIT
echo "PASS: real 0.4.1 core and WebApp install/uninstall lifecycle; previous state restored"
echo "Evidence retained in: $BACKUP"
