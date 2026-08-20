#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
export HOME="$TMP/home"
export USER=testuser
FAKEBIN="$TMP/bin"
mkdir -p "$FAKEBIN" "$HOME/.config/hypr/hyprland"

# Caelestia/Hyprland fixture resembling an older pre-v0.3.6 installation.
cat > "$HOME/.config/hypr/hyprland/rules.lua" <<'LUA'
local opaque_tag = "opaque"
local music_player_tag = "music_player"
local communication_app_tag = "communication_app"
local user_custom_setting = "KEEP-ME" -- user-owned

tagged_rule(opaque_tag, {
    "org.quickshell", -- Quickshell
}, "class")

tagged_rule(communication_app_tag, {
    "discord|equibop|vesktop", -- Discord clients
}, "class")

create_tag(music_player_tag, { workspace = "special:music" })
create_tag(communication_app_tag, { workspace = "special:communication" })
LUA
cat > "$HOME/.config/hypr/hyprland/keybinds.lua" <<'LUA'
create_bind(vars.kbMusicWs, fn.toggle("music"))
create_bind("SUPER + V", fn.toggle("streaming")) -- Caelestia WebApps: Streaming
create_bind(vars.kbCommunicationWs, fn.toggle("communication"))
LUA

SHELL="$HOME/.config/quickshell/caelestia"
mkdir -p "$SHELL/modules/bar/components" "$SHELL/modules/bar/popouts" "$SHELL/modules/bar/webapps" "$SHELL/modules/sidebar/webapps" "$SHELL/modules/sidebar" "$SHELL/services"
cat > "$SHELL/modules/bar/components/StatusIcons.qml" <<'QML'
import QtQuick
import QtQuick.Layouts
import "../webapps" as CaelestiaWebApps // CAELESTIA-WEBAPPS
Item {
    id: root
    property int spacing: 4
    property color colour: "white"
    property string userCustom: "KEEP-ME"
    CaelestiaWebApps.Catalog { id: webAppsCatalog }
    ColumnLayout {
        id: iconColumn
        Repeater { model: [] }
        // BEGIN CAELESTIA-WEBAPPS STATUS ICONS
        Repeater {
            model: ScriptModel { values: webAppsCatalog.installedApps }
            CaelestiaWebApps.WebAppIcon {
                required property var modelData
                required property int index
                name: `webapp-${modelData.id}`
                app: modelData
                colour: root.colour
            }
        }
        // deliberately missing END marker: repair must recover ownership
    }
}
QML
cat > "$SHELL/modules/bar/popouts/Content.qml" <<'QML'
import QtQuick
Item {
    id: root
    Item { id: content }
}
QML
cat > "$SHELL/services/NotifData.qml" <<'QML'
import QtQuick
QtObject {
    property string appName
    property var notification
    property var locks: new Set()
    function lock(item: Item): void {
        locks.add(item);
    }
    function unlock(item: Item): void {
        locks.delete(item);
    }
    Component.onCompleted: { appName = notification.appName; }
}
QML
cat > "$SHELL/services/Notifs.qml" <<'QML'
import QtQuick
QtObject {
    function save(n) {
        return {
                    appName: n.appName,
        }
    }
}
QML
cat > "$SHELL/modules/sidebar/Content.qml" <<'QML'
import QtQuick
Item { id: root }
QML
printf 'old\n' > "$SHELL/modules/bar/webapps/Old.qml"
printf 'old\n' > "$SHELL/modules/sidebar/webapps/Old.qml"

# Half-installed old apps: one has only a profile, one has an old desktop file.
mkdir -p "$HOME/.local/share/caelestia-webapps/apps/chatgpt/profile"
mkdir -p "$HOME/.local/share/applications"
printf '[Desktop Entry]\nName=Netflix\n' > "$HOME/.local/share/applications/caelestia-webapp-netflix.desktop"

cat > "$FAKEBIN/firefox" <<'EOF_FIREFOX'
#!/usr/bin/env bash
case "${1:-}" in
  --version) echo 'Mozilla Firefox 153.0.4' ;;
  --help) echo '--profile --new-instance --new-window' ;;
  *) exit 0 ;;
esac
EOF_FIREFOX
cat > "$FAKEBIN/curl" <<'EOF_CURL'
#!/usr/bin/env bash
set -e
out=""
while (($#)); do
  if [[ "$1" == "--output" ]]; then shift; out="$1"; fi
  shift || true
done
[[ -n "$out" ]]
printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"><path d="M0 0h1v1H0z"/></svg>' > "$out"
EOF_CURL
cat > "$FAKEBIN/hyprctl" <<'EOF_HYPR'
#!/usr/bin/env bash
case "${1:-}" in
  reload) echo ok ;;
  configerrors) echo 'no errors' ;;
  *) exit 0 ;;
esac
EOF_HYPR
for cmd in desktop-file-validate update-desktop-database gtk-update-icon-cache; do
cat > "$FAKEBIN/$cmd" <<'EOF_STUB'
#!/usr/bin/env bash
exit 0
EOF_STUB
chmod +x "$FAKEBIN/$cmd"
done
chmod +x "$FAKEBIN/firefox" "$FAKEBIN/curl" "$FAKEBIN/hyprctl"
export PATH="$FAKEBIN:/usr/bin:/bin"

# Dry-run must not touch managed/user configuration files.
sha256sum "$HOME/.config/hypr/hyprland/rules.lua" "$HOME/.config/hypr/hyprland/keybinds.lua" "$SHELL/modules/bar/components/StatusIcons.qml" > "$TMP/before-dry.sha"
"$ROOT_DIR/repair.sh" --dry-run >/dev/null
sha256sum "$HOME/.config/hypr/hyprland/rules.lua" "$HOME/.config/hypr/hyprland/keybinds.lua" "$SHELL/modules/bar/components/StatusIcons.qml" > "$TMP/after-dry.sha"
cmp -s "$TMP/before-dry.sha" "$TMP/after-dry.sha"

"$ROOT_DIR/repair.sh" >/dev/null

# Half-installs reconstructed and version-stamped.
grep -Fq "INSTALLER_VERSION=\"$(<"$ROOT_DIR/VERSION")\"" "$HOME/.local/share/caelestia-webapps/apps/chatgpt/installed.conf"
grep -Fq "INSTALLER_VERSION=\"$(<"$ROOT_DIR/VERSION")\"" "$HOME/.local/share/caelestia-webapps/apps/netflix/installed.conf"
[[ -x "$HOME/.local/bin/caelestia-webapp-chatgpt" ]]
[[ -x "$HOME/.local/bin/caelestia-webapp-netflix" ]]

# Known v0.3.0 streaming bind migrates, and old V is removed.
grep -Fq 'create_bind("SUPER + Y", fn.toggle("streaming")) -- Caelestia WebApps: Streaming' "$HOME/.config/hypr/hyprland/keybinds.lua"
! grep -Fq 'create_bind("SUPER + V", fn.toggle("streaming")) -- Caelestia WebApps: Streaming' "$HOME/.config/hypr/hyprland/keybinds.lua"

# Missing END marker + old modules are normalized into one current integration.
[[ "$(grep -Fc 'BEGIN CAELESTIA-WEBAPPS STATUS ICONS' "$SHELL/modules/bar/components/StatusIcons.qml")" -eq 1 ]]
[[ "$(grep -Fc 'END CAELESTIA-WEBAPPS STATUS ICONS' "$SHELL/modules/bar/components/StatusIcons.qml")" -eq 1 ]]
[[ "$(grep -Fc 'catalog: webAppsCatalog' "$SHELL/modules/bar/popouts/Content.qml")" -eq 1 ]]
[[ -f "$SHELL/modules/bar/webapps/Catalog.qml" ]]
[[ ! -d "$SHELL/modules/sidebar/webapps" ]]
[[ -f "$HOME/.local/state/caelestia-webapps/applet/enabled" ]]
[[ "$(cat "$HOME/.local/state/caelestia-webapps/last-repaired-version")" == "$(<"$ROOT_DIR/VERSION")" ]]

# User-owned content around project markers survives repair.
grep -Fq 'local user_custom_setting = "KEEP-ME" -- user-owned' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq 'property string userCustom: "KEEP-ME"' "$SHELL/modules/bar/components/StatusIcons.qml"

# A second full repair is idempotent and must not create new backups.
before_backups="$(find "$HOME/.local/state/caelestia-webapps/backups" -type f 2>/dev/null | wc -l)"
"$ROOT_DIR/repair.sh" >/dev/null
after_backups="$(find "$HOME/.local/state/caelestia-webapps/backups" -type f 2>/dev/null | wc -l)"
[[ "$before_backups" == "$after_backups" ]]

echo "PASS: v$(<"$ROOT_DIR/VERSION") reconstructs half-installs, migrates legacy state, preserves user content and is repair-idempotent"
