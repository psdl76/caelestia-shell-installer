#!/usr/bin/env bash
set -Eeuo pipefail

PROFILE_DIR="@PROFILE_DIR@"
APP_URL="@APP_URL@"
APP_NAME="@APP_NAME@"
WINDOW_CLASS="@WINDOW_CLASS@"
SPECIAL_WORKSPACE="@HYPR_SHARED_WORKSPACE@"
APP_CSS="$PROFILE_DIR/chrome/userChrome.app.css"
SETUP_CSS="$PROFILE_DIR/chrome/userChrome.setup.css"
ACTIVE_CSS="$PROFILE_DIR/chrome/userChrome.css"

if ! command -v firefox >/dev/null 2>&1; then
    echo "Fehler: Firefox wurde nicht gefunden." >&2
    exit 1
fi

if [[ ! -d "$PROFILE_DIR" ]]; then
    echo "Fehler: Firefox-Profil existiert nicht: $PROFILE_DIR" >&2
    exit 1
fi

for file in "$APP_CSS" "$SETUP_CSS"; do
    if [[ ! -s "$file" ]]; then
        echo "Fehler: Benötigte CSS-Datei fehlt: $file" >&2
        exit 1
    fi
done

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

# Setup mode must never switch userChrome.css underneath a running Firefox
# process. Activate the existing app, explain what to do, and leave its profile
# untouched. The user can close the app and invoke setup again.
existing="$(find_existing_window || true)"
if [[ -n "$existing" ]]; then
    ensure_special_workspace
    hyprctl dispatch         "hl.dsp.focus({ window = \"address:$existing\" })"         >/dev/null 2>&1 || true
    echo "Setup-Modus kann nicht gestartet werden, solange $APP_NAME bereits läuft." >&2
    echo "Das vorhandene Fenster wurde aktiviert. Schließe die App vollständig und starte den Setup-Launcher erneut." >&2
    exit 2
fi

# Do not pre-judge Firefox profile lock files here. If Hyprland IPC is
# unavailable, Firefox itself remains the authority for a real profile lock.
# The EXIT trap always restores normal app mode on success, failure or signal.
restore_app_mode() {
    cp "$APP_CSS" "$ACTIVE_CSS" 2>/dev/null || true
    chmod 644 "$ACTIVE_CSS" 2>/dev/null || true
}
trap restore_app_mode EXIT INT TERM HUP

cp "$SETUP_CSS" "$ACTIVE_CSS"
chmod 644 "$ACTIVE_CSS"

ensure_special_workspace

echo "Setup-Modus für $APP_NAME"
echo "Firefox-Navigation und Berechtigungsdialoge bleiben für diesen Start sichtbar."
echo "Nach dem Schließen wird automatisch wieder der normale App-Modus aktiviert."
echo

status=0
env MOZ_APP_REMOTINGNAME=@MOZ_APP_REMOTINGNAME@ \
    firefox \
    --new-instance \
    --profile "$PROFILE_DIR" \
    --new-window "$APP_URL" || status=$?

exit "$status"
