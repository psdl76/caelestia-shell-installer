#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/lib/hyprland_live.sh"

[[ "${1:-}" == "--confirm-real-home" && -n "${2:-}" ]] || {
    echo "Usage: $0 --confirm-real-home /path/to/caelestia-webapps-0.4.3.tar.gz" >&2
    exit 2
}
TARBALL="$(readlink -f -- "$2")"
[[ -f "$TARBALL" ]] || { echo "Release tarball not found: $TARBALL" >&2; exit 2; }
[[ -n "${HOME:-}" && "$HOME" == /* && "$HOME" != "/" ]] || {
    echo "Unsafe HOME: ${HOME:-unset}" >&2
    exit 2
}

PREFIX="$HOME/.local"
CORE="$PREFIX/lib/caelestia-webapps"
CLI="$PREFIX/bin/caelestia-webapps"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/caelestia-webapps"
STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/caelestia-webapps"
DATA_ROOT="$HOME/.local/share/caelestia-webapps"
TEST_ID="caelestia-release-043-e2e"
BACKUP="$(mktemp -d /tmp/caelestia-webapps-real-0.4.3.XXXXXX)"
EXTRACT="$BACKUP/candidate"
RESTORED=0

mkdir -p "$EXTRACT" "$BACKUP/saved"
tar -xzf "$TARBALL" -C "$EXTRACT"
mapfile -t TOPS < <(find "$EXTRACT" -mindepth 1 -maxdepth 1 -type d -print)
[[ ${#TOPS[@]} -eq 1 && -f "${TOPS[0]}/VERSION" ]] || {
    echo "Release archive must contain exactly one project directory" >&2
    exit 1
}
CANDIDATE="${TOPS[0]}"
[[ "$(<"$CANDIDATE/VERSION")" == "0.4.3" ]] || {
    echo "Real gate accepts only release 0.4.3" >&2
    exit 1
}

[[ -f "$CORE/PACKAGE-METADATA" ]] || {
    echo "Existing rootless core metadata is missing; refusing unsafe replacement" >&2
    exit 1
}
grep -Fqx 'PACKAGE_ID=caelestia-webapps' "$CORE/PACKAGE-METADATA"
PREVIOUS_VERSION="$(sed -n 's/^PACKAGE_VERSION=//p' "$CORE/PACKAGE-METADATA")"
[[ -n "$PREVIOUS_VERSION" ]] || { echo "Existing core version is unknown" >&2; exit 1; }

target_paths=(
    "$CONFIG_ROOT/apps/$TEST_ID.conf"
    "$DATA_ROOT/apps/$TEST_ID"
    "$PREFIX/bin/caelestia-webapp-$TEST_ID"
    "$PREFIX/bin/caelestia-webapp-$TEST_ID-setup"
    "$PREFIX/share/applications/caelestia-webapp-$TEST_ID.desktop"
    "$PREFIX/share/icons/hicolor/scalable/apps/$TEST_ID.svg"
)
for target in "${target_paths[@]}"; do
    [[ ! -e "$target" && ! -L "$target" ]] || {
        echo "Test target already exists: $target" >&2
        exit 1
    }
done

protected_paths=(
    "$CORE"
    "$PREFIX/bin/caelestia-webapps"
    "$PREFIX/bin/caelestia-webapps-manager"
    "$PREFIX/share/applications/caelestia-webapps-manager.desktop"
    "$PREFIX/share/icons/hicolor/scalable/apps/caelestia-webapps.svg"
    "$PREFIX/share/licenses/caelestia-webapps"
    "$CONFIG_ROOT"
    "$STATE_ROOT"
    "$DATA_ROOT/catalog.json"
    "$DATA_ROOT/applet-registry.json"
    "$HOME/.config/hypr/hyprland/rules.lua"
    "$HOME/.config/hypr/hyprland/keybinds.lua"
)
for i in "${!protected_paths[@]}"; do
    source_path="${protected_paths[$i]}"
    if [[ -e "$source_path" || -L "$source_path" ]]; then
        cp -a -- "$source_path" "$BACKUP/saved/$i"
        printf 'present\n' > "$BACKUP/saved/$i.state"
    else
        printf 'absent\n' > "$BACKUP/saved/$i.state"
    fi
done

HYPR_LOG=""
HYPR_LOG_SIZE=0
if [[ -n "${XDG_RUNTIME_DIR:-}" && -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    HYPR_LOG="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log"
    [[ ! -f "$HYPR_LOG" ]] || HYPR_LOG_SIZE="$(stat -c %s "$HYPR_LOG")"
fi
CONFIG_ERRORS_BEFORE="$(hyprctl configerrors)"
BINDS_BEFORE="$(hyprctl binds -j | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')"
[[ -z "$CONFIG_ERRORS_BEFORE" || "$CONFIG_ERRORS_BEFORE" == "no errors" || "$CONFIG_ERRORS_BEFORE" == "No errors" ]] || {
    echo "Hyprland already reports configuration errors; refusing to start the real gate" >&2
    exit 1
}

restore_previous_state() {
    [[ "$RESTORED" -eq 0 ]] || return 0
    RESTORED=1
    local lua_live=false i target saved state restore_tmp
    set +e
    if command -v hyprctl >/dev/null 2>&1 && hypr_lua_live_begin; then
        lua_live=true
    fi
    for target in "${target_paths[@]}"; do
        rm -rf -- "$target"
    done
    for i in "${!protected_paths[@]}"; do
        target="${protected_paths[$i]}"
        saved="$BACKUP/saved/$i"
        state="$(<"$BACKUP/saved/$i.state")"
        if [[ "$state" == present && -f "$saved" && ! -L "$saved" ]]; then
            mkdir -p "$(dirname -- "$target")"
            restore_tmp="$(mktemp "$(dirname -- "$target")/.caelestia-restore.XXXXXX")"
            cp -a -- "$saved" "$restore_tmp"
            mv -f -- "$restore_tmp" "$target"
        else
            rm -rf -- "$target"
            if [[ "$state" == present ]]; then
                mkdir -p "$(dirname -- "$target")"
                cp -a -- "$saved" "$target"
            fi
        fi
    done
    if [[ "$lua_live" == true ]]; then
        hypr_lua_live_finish || true
    else
        hyprctl reload >/dev/null 2>&1 || true
    fi
    set -e
}

on_exit() {
    result=$?
    restore_previous_state
    if [[ "$result" -ne 0 ]]; then
        echo "FAILED: real v0.4.3 lifecycle; previous state restored from $BACKUP" >&2
    fi
    exit "$result"
}
trap on_exit EXIT

echo "[real] evidence: $BACKUP"
echo "[real] replacing core $PREVIOUS_VERSION with candidate 0.4.3"
"$CANDIDATE/packaging/install-core.sh" --prefix "$PREFIX"
grep -Fqx 'PACKAGE_VERSION=0.4.3' "$CORE/PACKAGE-METADATA"

"$CLI" list > "$BACKUP/candidate-list.json"
python3 - "$BACKUP/candidate-list.json" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding="utf-8"))
assert payload.get("apiVersion") == 1
assert payload.get("ok") is True
PY

printf -v payload \
    '{"id":"%s","name":"Caelestia Release 0.4.3 E2E","url":"https://release-e2e.invalid/","category":"development","iconMode":"local","iconFile":"%s","genericName":"Release lifecycle test","comment":"Temporary release lifecycle test"}' \
    "$TEST_ID" "$CANDIDATE/assets/icons/webapp-generic.svg"

echo "[real] creating, installing and checking temporary WebApp"
"$CLI" user-create "$payload" > "$BACKUP/user-create.json"
"$CLI" install "$TEST_ID" > "$BACKUP/install.json"
"$CLI" status "$TEST_ID" > "$BACKUP/status-installed.json"
python3 - "$BACKUP/install.json" "$BACKUP/status-installed.json" <<'PY'
import json, sys
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

echo "[real] uninstalling and deleting temporary WebApp"
"$CLI" uninstall "$TEST_ID" > "$BACKUP/uninstall.json"
"$CLI" user-delete "$TEST_ID" > "$BACKUP/user-delete.json"
for target in "${target_paths[@]}"; do
    [[ ! -e "$target" && ! -L "$target" ]] || {
        echo "Residual test artifact: $target" >&2
        exit 1
    }
done

CONFIG_ERRORS_AFTER="$(hyprctl configerrors)"
BINDS_AFTER="$(hyprctl binds -j | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')"
[[ -z "$CONFIG_ERRORS_AFTER" || "$CONFIG_ERRORS_AFTER" == "no errors" || "$CONFIG_ERRORS_AFTER" == "No errors" ]]
[[ "$BINDS_AFTER" == "$BINDS_BEFORE" ]]
echo "[real] removing candidate and restoring core $PREVIOUS_VERSION"
"$CANDIDATE/packaging/uninstall-core.sh" --prefix "$PREFIX"
restore_previous_state
grep -Fqx "PACKAGE_VERSION=$PREVIOUS_VERSION" "$CORE/PACKAGE-METADATA"
[[ "$(hyprctl binds -j | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')" == "$BINDS_BEFORE" ]]
RESTORED_ERRORS="$(hyprctl configerrors)"
[[ -z "$RESTORED_ERRORS" || "$RESTORED_ERRORS" == "no errors" || "$RESTORED_ERRORS" == "No errors" ]]
if [[ -n "$HYPR_LOG" && -f "$HYPR_LOG" ]]; then
    tail -c "+$((HYPR_LOG_SIZE + 1))" "$HYPR_LOG" > "$BACKUP/hyprland-new.log"
    ! grep -Fq 'Modesetting ' "$BACKUP/hyprland-new.log"
fi

trap - EXIT
echo "PASS: real v0.4.3 lifecycle; previous core $PREVIOUS_VERSION restored"
echo "Evidence retained in: $BACKUP"
