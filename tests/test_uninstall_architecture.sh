#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
FAKEBIN="$TMP/bin"
mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/hyprctl" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  reload) exit 0 ;;
  configerrors) echo 'no errors' ;;
  *) exit 0 ;;
esac
SH
for cmd in update-desktop-database gtk-update-icon-cache; do
cat > "$FAKEBIN/$cmd" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$FAKEBIN/$cmd"
done
chmod +x "$FAKEBIN/hyprctl"
export PATH="$FAKEBIN:/usr/bin:/bin"

make_home() {
  export HOME="$TMP/home-$1"
  rm -rf "$HOME"
  mkdir -p "$HOME/.config/hypr/hyprland" "$HOME/.local/share/caelestia-webapps/apps" "$HOME/.local/share/applications" "$HOME/.local/share/icons/hicolor/scalable/apps" "$HOME/.local/bin"
  cat > "$HOME/.config/hypr/hyprland/rules.lua" <<'LUA'
local opaque_tag = "opaque"
local music_player_tag = "music_player"
local streaming_app_tag = "streaming_app" -- Caelestia WebApps
local communication_app_tag = "communication_app"
local user_keep = "KEEP-ME"

tagged_rule(opaque_tag, {
    "org.quickshell",                -- Quickshell
    "netflix",                      -- Netflix
    "youtube",                      -- YouTube
    "whatsapp",                     -- WhatsApp
    "google-messages",              -- Google Messages
    "chatgpt",                       -- ChatGPT
}, "class")

tagged_rule(streaming_app_tag, {
    "youtube", -- Caelestia WebApps: YouTube (Streaming)
    "netflix", -- Caelestia WebApps: Netflix (Streaming)
}, "class") -- Caelestia WebApps: streaming
tagged_rule(communication_app_tag, {
    "discord|equibop|vesktop", -- Discord clients
    "whatsapp",                -- Whatsapp
    "google-messages"          -- Google Messages
}, "class")

create_tag(music_player_tag, { workspace = "special:music" })
create_tag(streaming_app_tag, { workspace = "special:streaming", opaque = true, idle_inhibit = "always" }) -- Caelestia WebApps
create_tag(communication_app_tag, { workspace = "special:communication" })
LUA
  cat > "$HOME/.config/hypr/hyprland/keybinds.lua" <<'LUA'
create_bind(vars.kbMusicWs, fn.toggle("music"))
create_bind("SUPER + Y", fn.toggle("streaming")) -- Caelestia WebApps: Streaming
create_bind(vars.kbCommunicationWs, fn.toggle("communication"))
LUA
}
install_fixture() {
  local id="$1" icon="${2:-$1}"
  mkdir -p "$HOME/.local/share/caelestia-webapps/apps/$id/profile"
  printf 'INSTALLER_VERSION="0.3.6"\n' > "$HOME/.local/share/caelestia-webapps/apps/$id/installed.conf"
  : > "$HOME/.local/bin/caelestia-webapp-$id"
  : > "$HOME/.local/bin/caelestia-webapp-$id-setup"
  : > "$HOME/.local/share/applications/caelestia-webapp-$id.desktop"
  : > "$HOME/.local/share/icons/hicolor/scalable/apps/$icon.svg"
}

# 1) Streaming app with another streaming consumer: shared infrastructure stays.
make_home preserve-streaming
install_fixture netflix
install_fixture youtube
"$ROOT_DIR/uninstall.sh" netflix >/dev/null
! grep -Fq '"netflix"' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq '"youtube", -- Caelestia WebApps: YouTube (Streaming)' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq 'local streaming_app_tag = "streaming_app" -- Caelestia WebApps' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq 'create_tag(streaming_app_tag' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq 'create_bind("SUPER + Y", fn.toggle("streaming")) -- Caelestia WebApps: Streaming' "$HOME/.config/hypr/hyprland/keybinds.lua"
grep -Fq 'local user_keep = "KEEP-ME"' "$HOME/.config/hypr/hyprland/rules.lua"
[[ ! -e "$HOME/.local/share/caelestia-webapps/apps/netflix" ]]
[[ "$(find "$HOME/.local/state/caelestia-webapps/backups/netflix" -name 'rules.lua.*.bak' | wc -l)" -eq 1 ]]

# 2) Last streaming app: only WebApps-owned shared infrastructure disappears.
make_home last-streaming
# Remove fixture-only youtube from config so Netflix is really the last consumer.
sed -i '/"youtube"/d' "$HOME/.config/hypr/hyprland/rules.lua"
install_fixture netflix
"$ROOT_DIR/uninstall.sh" netflix >/dev/null
! grep -Fq 'streaming_app_tag' "$HOME/.config/hypr/hyprland/rules.lua"
! grep -Fq 'fn.toggle("streaming")' "$HOME/.config/hypr/hyprland/keybinds.lua"
grep -Fq 'communication_app_tag' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq 'local user_keep = "KEEP-ME"' "$HOME/.config/hypr/hyprland/rules.lua"

# 3) Messaging membership is removed, native Caelestia communication infra stays.
make_home messaging
install_fixture whatsapp
install_fixture google-messages
"$ROOT_DIR/uninstall.sh" whatsapp >/dev/null
! grep -Fq '"whatsapp"' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq '"google-messages"          -- Google Messages' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq 'create_tag(communication_app_tag' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq 'create_bind(vars.kbCommunicationWs' "$HOME/.config/hypr/hyprland/keybinds.lua"

# 4) AI app has no shared tag: only its opaque membership changes.
make_home ai
install_fixture chatgpt
# Keep another applet-visible app installed so shared QML applet removal is not invoked in this fixture.
install_fixture google-messages
"$ROOT_DIR/uninstall.sh" chatgpt >/dev/null
! grep -Fq '"chatgpt"' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq 'streaming_app_tag' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq 'communication_app_tag' "$HOME/.config/hypr/hyprland/rules.lua"

echo "PASS: v$(<"$ROOT_DIR/VERSION") uninstall removes only app-owned state and retires WebApps-owned shared infra only after the last consumer"
