#!/usr/bin/env bash
set -Eeuo pipefail

PROFILE_DIR="@PROFILE_DIR@"
APP_URL="@APP_URL@"
APP_NAME="@APP_NAME@"
WINDOW_CLASS="@WINDOW_CLASS@"
SPECIAL_WORKSPACE="@HYPR_SHARED_WORKSPACE@"
APP_CSS="$PROFILE_DIR/chrome/userChrome.app.css"
ACTIVE_CSS="$PROFILE_DIR/chrome/userChrome.css"
BROWSER_BRIDGE_PORT="@BROWSER_BRIDGE_PORT@"

if ! command -v firefox >/dev/null 2>&1; then
    echo "Fehler: Firefox wurde nicht gefunden." >&2
    exit 1
fi

if [[ ! -d "$PROFILE_DIR" ]]; then
    echo "Fehler: Firefox-Profil existiert nicht: $PROFILE_DIR" >&2
    exit 1
fi

if [[ ! -s "$APP_CSS" ]]; then
    echo "Fehler: Firefox App-Mode CSS fehlt: $APP_CSS" >&2
    exit 1
fi

# Return the Hyprland address of an already running window for this exact
# dedicated WebApp class. An empty result means that the app is not running or
# Hyprland's IPC is unavailable. We deliberately avoid process-name matching:
# all WebApps are Firefox processes and only the dedicated Wayland class is a
# reliable app identity.
find_existing_window() {
    command -v hyprctl >/dev/null 2>&1 || return 1
    command -v python3 >/dev/null 2>&1 || return 1

    local clients address
    clients="$(hyprctl clients -j 2>/dev/null || true)"
    [[ -n "$clients" ]] || return 1

    address="$(python3 -c '
import json, sys
wanted = sys.argv[1].lower()
try:
    clients = json.load(sys.stdin)
except Exception:
    raise SystemExit(1)
for client in clients:
    cls = str(client.get("class", "")).lower()
    initial = str(client.get("initialClass", client.get("initial_class", ""))).lower()
    if cls == wanted or initial == wanted:
        value = str(client.get("address", ""))
        if value:
            print(value)
            raise SystemExit(0)
raise SystemExit(1)
' "$WINDOW_CLASS" <<<"$clients" 2>/dev/null)" || return 1

    [[ -n "$address" ]] || return 1
    printf '%s\n' "$address"
}

special_workspace_visible() {
    [[ -n "$SPECIAL_WORKSPACE" ]] || return 1
    command -v hyprctl >/dev/null 2>&1 || return 1
    command -v python3 >/dev/null 2>&1 || return 1

    local monitors
    monitors="$(hyprctl monitors -j 2>/dev/null || true)"
    [[ -n "$monitors" ]] || return 1

    python3 -c '
import json, sys
wanted = "special:" + sys.argv[1]
try:
    monitors = json.load(sys.stdin)
except Exception:
    raise SystemExit(1)
for monitor in monitors:
    special = monitor.get("specialWorkspace") or monitor.get("special_workspace") or {}
    if str(special.get("name", "")) == wanted:
        raise SystemExit(0)
raise SystemExit(1)
' "$SPECIAL_WORKSPACE" <<<"$monitors" >/dev/null 2>&1
}

ensure_special_workspace() {
    [[ -n "$SPECIAL_WORKSPACE" ]] || return 0
    command -v hyprctl >/dev/null 2>&1 || return 0

    if ! special_workspace_visible; then
        hyprctl dispatch togglespecialworkspace "$SPECIAL_WORKSPACE" >/dev/null 2>&1 || true
    fi
}

focus_existing_window() {
    local address="$1"

    [[ -n "$address" ]] || return 1
    ensure_special_workspace

    # Hyprland's Lua configuration path requires Lua dispatcher syntax.
    # Failing to focus an existing window must never trigger another Firefox.
    if ! hyprctl dispatch         "hl.dsp.focus({ window = \"address:$address\" })"         >/dev/null 2>&1; then
        echo "Warnung: $APP_NAME läuft bereits, konnte aber nicht fokussiert werden." >&2
    fi

    return 0
}

# Existence and focus success are separate states. Once a matching WebApp
# window exists, never start another Firefox instance.
existing_address="$(find_existing_window || true)"
if [[ -n "$existing_address" ]]; then
    focus_existing_window "$existing_address"
    exit 0
fi

# Always restore app mode before a normal start. This also repairs a setup
# session that was interrupted before it could restore userChrome.css.
if ! cmp -s "$APP_CSS" "$ACTIVE_CSS" 2>/dev/null; then
    cp "$APP_CSS" "$ACTIVE_CSS"
    chmod 644 "$ACTIVE_CSS"
fi

# Apps assigned to a special workspace should become visible when launched
# from a normal desktop/app-menu entry as well.
ensure_special_workspace

REMOTE_ARGS=()
if [[ -n "$BROWSER_BRIDGE_PORT" ]]; then
    REMOTE_ARGS+=(--remote-debugging-port "$BROWSER_BRIDGE_PORT")
fi

exec env MOZ_APP_REMOTINGNAME=@MOZ_APP_REMOTINGNAME@ \
    firefox \
    --new-instance \
    "${REMOTE_ARGS[@]}" \
    --profile "$PROFILE_DIR" \
    --new-window "$APP_URL"
