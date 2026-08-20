#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$ROOT_DIR/lib"
APP_DEF_DIR="$ROOT_DIR/apps"
TEMPLATE_DIR="$ROOT_DIR/templates"

# shellcheck source=lib/common.sh
source "$LIB_DIR/common.sh"
source "$LIB_DIR/app_definitions.sh"
source "$LIB_DIR/ownership.sh"
source "$LIB_DIR/locking.sh"
source "$LIB_DIR/app_schema.sh"
trap on_error ERR

usage() {
    echo "Verwendung: $0 <app-id> [--no-applet]"
    echo
    echo "Verfügbare Apps:"
    local f
    shopt -s nullglob
    for f in "$APP_DEF_DIR"/*.conf "$USER_APP_DEF_DIR"/*.conf; do
        [[ -f "$f" ]] || continue
        printf '  %s\n' "$(basename "$f" .conf)"
    done
}

[[ $# -ge 1 && $# -le 2 ]] || { usage; exit 2; }
REQUESTED_APP="$1"
if [[ $# -eq 2 && "$2" != "--no-applet" ]]; then
    echo "Unbekannte Option: $2" >&2
    usage
    exit 2
fi
# --no-applet is retained as a compatibility no-op for legacy automation.
# The engine core has no UI/applet integration at all.
APP_DEF="$(find_app_definition "$REQUESTED_APP" || true)"
[[ -n "$APP_DEF" && -f "$APP_DEF" ]] || { echo "Unbekannte App: $REQUESTED_APP" >&2; usage; exit 2; }

validate_app_schema_source "$APP_DEF"
# shellcheck disable=SC1090
source "$APP_DEF"
apply_app_category_defaults

acquire_mutation_lock "install:$APP_ID"

STATE_ROOT="$HOME/.local/state/caelestia-webapps"
LOG_DIR="$STATE_ROOT/logs"
BACKUP_DIR="$STATE_ROOT/backups/$APP_ID"
LOG_FILE="$LOG_DIR/$APP_ID.log"
DATA_ROOT="$HOME/.local/share/caelestia-webapps"
APP_DATA_DIR="$DATA_ROOT/apps/$APP_ID"
PROFILE_DIR="$APP_DATA_DIR/profile"
CHROME_DIR="$PROFILE_DIR/chrome"
USER_CHROME="$CHROME_DIR/userChrome.css"
APP_USER_CHROME="$CHROME_DIR/userChrome.app.css"
SETUP_USER_CHROME="$CHROME_DIR/userChrome.setup.css"
USER_JS="$PROFILE_DIR/user.js"
BIN_DIR="$HOME/.local/bin"
LAUNCHER="$BIN_DIR/caelestia-webapp-$APP_ID"
SETUP_LAUNCHER="$BIN_DIR/caelestia-webapp-$APP_ID-setup"
APPLICATIONS_DIR="$HOME/.local/share/applications"
DESKTOP_FILE="$APPLICATIONS_DIR/caelestia-webapp-$APP_ID.desktop"
ICON_ROOT="$HOME/.local/share/icons/hicolor"
ICON_DIR="$ICON_ROOT/scalable/apps"
ICON_FILE="$ICON_DIR/$ICON_NAME.svg"
HYPR_RULES_FILE="$HOME/.config/hypr/hyprland/rules.lua"
HYPR_KEYBINDS_FILE="$HOME/.config/hypr/hyprland/keybinds.lua"
METADATA_FILE="$APP_DATA_DIR/installed.conf"
INSTALLER_VERSION="$(<"$ROOT_DIR/VERSION")"

mkdir -p "$LOG_DIR" "$BACKUP_DIR" || { echo "FEHLER: State-Verzeichnisse konnten nicht erstellt werden."; exit 1; }
touch "$LOG_FILE" || { echo "FEHLER: Logdatei konnte nicht erstellt werden: $LOG_FILE"; exit 1; }
exec > >(tee -a "$LOG_FILE") 2>&1

source "$LIB_DIR/firefox.sh"
source "$LIB_DIR/icon.sh"
source "$LIB_DIR/desktop.sh"
source "$LIB_DIR/hyprland.sh"
source "$LIB_DIR/catalog.sh"

cat <<EOF_BANNER

╭────────────────────────────────────────────────────────╮
│                                                        │
│             Caelestia Web App Installer                │
│                                                        │
╰────────────────────────────────────────────────────────╯

App      : $APP_NAME
App-ID   : $APP_ID
URL      : $APP_URL
Benutzer : $USER
Home     : $HOME
Log      : $LOG_FILE
EOF_BANNER

step "App-Definition prüfen"
validate_app_definition
[[ "$REQUESTED_APP" == "$APP_ID" ]] || die "Dateiname und APP_ID stimmen nicht überein: $REQUESTED_APP != $APP_ID"

step "System und Voraussetzungen prüfen"
require_command grep "sudo pacman -S grep"
require_command awk "sudo pacman -S gawk"
require_command cmp "sudo pacman -S diffutils"
require_command diff "sudo pacman -S diffutils"
require_command date "sudo pacman -S coreutils"
require_command mktemp "sudo pacman -S coreutils"
check_firefox

step "Anwendungsverzeichnisse erstellen"
mkdir -p "$APP_DATA_DIR" "$BIN_DIR" "$APPLICATIONS_DIR" "$ICON_DIR" || die "Benötigte Verzeichnisse konnten nicht erstellt werden."
for dir in "$APP_DATA_DIR" "$BIN_DIR" "$APPLICATIONS_DIR" "$ICON_DIR" "$BACKUP_DIR"; do
    verify_directory "$dir"
done

step "$APP_NAME-Icon installieren"
install_icon

step "Separates Firefox-Profil konfigurieren"
install_firefox_profile

step "$APP_NAME-Startskripte erstellen"
install_launcher
install_setup_launcher

step "Desktop Launcher erstellen"
install_desktop_entry

step "Desktop-Datenbank aktualisieren"
update_desktop_database_safe

step "Icon-Cache aktualisieren"
update_icon_cache

step "Hyprland Lua-Regel integrieren"
error_context "$HYPR_RULES_FILE" "Bei einem Commit-/Reload-Fehler werden die ursprünglichen Hyprland-Dateien automatisch wiederhergestellt."
install_hyprland_rule
clear_error_context

step "Installationsmetadaten schreiben"
error_context "$METADATA_FILE" "Eine vorhandene Metadatendatei bleibt als Backup unter $BACKUP_DIR erhalten."
metadata_tmp="$(mktemp)" || die "Temporäre Metadatendatei konnte nicht erstellt werden."
cat > "$metadata_tmp" <<EOF_META
APP_ID="$APP_ID"
INSTALLER_VERSION="$INSTALLER_VERSION"
APP_NAME="$APP_NAME"
APP_URL="$APP_URL"
WINDOW_CLASS="$WINDOW_CLASS"
MOZ_APP_REMOTINGNAME="$MOZ_APP_REMOTINGNAME"
LAUNCHER="$LAUNCHER"
SETUP_LAUNCHER="$SETUP_LAUNCHER"
DESKTOP_FILE="$DESKTOP_FILE"
ICON_FILE="$ICON_FILE"
PROFILE_DIR="$PROFILE_DIR"
USE_OPAQUE_TAG="$USE_OPAQUE_TAG"
APP_CATALOG_CATEGORY="${APP_CATALOG_CATEGORY:-other}"
NOTIFICATION_MATCH="${NOTIFICATION_MATCH:-$APP_NAME}"
EOF_META
if install_file_if_changed "$metadata_tmp" "$METADATA_FILE" 644 "Installationsmetadaten"; then
    :
else
    rm -f "$metadata_tmp"
fi
verify_file "$METADATA_FILE"
clear_error_context

step "Katalog und Applet Registry aktualisieren"
generate_catalog


step "Vollständige Installation prüfen"
ERRORS=0
for file in "$LAUNCHER" "$SETUP_LAUNCHER" "$DESKTOP_FILE" "$ICON_FILE" "$USER_JS" "$USER_CHROME" "$APP_USER_CHROME" "$SETUP_USER_CHROME" "$METADATA_FILE" "$CATALOG_FILE" "$APPLET_REGISTRY_FILE"; do
    if [[ -s "$file" ]]; then
        ok "$file"
    else
        echo -e "${RED}✗ FEHLT ODER LEER: $file${RESET}"
        ERRORS=$((ERRORS + 1))
    fi
done
[[ -x "$LAUNCHER" ]] || { echo -e "${RED}✗ Launcher ist nicht ausführbar${RESET}"; ERRORS=$((ERRORS + 1)); }
[[ -x "$SETUP_LAUNCHER" ]] || { echo -e "${RED}✗ Setup-Launcher ist nicht ausführbar${RESET}"; ERRORS=$((ERRORS + 1)); }
[[ "$ERRORS" -eq 0 ]] || die "$ERRORS Fehler bei der Abschlussprüfung gefunden."

echo
echo -e "${GREEN}${BOLD}╭────────────────────────────────────────────────────────╮${RESET}"
echo -e "${GREEN}${BOLD}│              INSTALLATION ERFOLGREICH                  │${RESET}"
echo -e "${GREEN}${BOLD}╰────────────────────────────────────────────────────────╯${RESET}"
echo
echo "App            : $APP_NAME"
echo "Firefox-Profil : $PROFILE_DIR"
echo "Launcher       : $LAUNCHER"
echo "Setup-Launcher : $SETUP_LAUNCHER"
echo "Desktop Entry  : $DESKTOP_FILE"
echo "Icon           : $ICON_FILE"
echo "Wayland-Klasse : $WINDOW_CLASS"
echo "Log            : $LOG_FILE"
echo "Katalog        : $CATALOG_FILE"
echo "Applet Registry: $APPLET_REGISTRY_FILE"
echo
echo "Ersteinrichtung / Berechtigungen:"
echo "  $SETUP_LAUNCHER"
echo
echo "Normal starten:"
echo "  $LAUNCHER"
echo
echo "Nach dem Start prüfen:"
echo "  hyprctl clients | grep -A 15 -B 5 -i '$APP_NAME'"
echo
echo "Erwartet:"
echo "  class: $WINDOW_CLASS"
echo "  initialClass: $WINDOW_CLASS"
echo
