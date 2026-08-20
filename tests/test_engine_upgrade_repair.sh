#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export USER="testuser"
FAKEBIN="$TMP/bin"
mkdir -p "$HOME/.config/hypr/hyprland" "$FAKEBIN"

cat > "$HOME/.config/hypr/hyprland/rules.lua" <<'LUA'
local opaque_tag = "opaque"
local communication_app_tag = "communication_app"
tagged_rule(opaque_tag, {
    "org.quickshell", -- fixture only
}, "class")
tagged_rule(communication_app_tag, {
}, "class")
create_tag(communication_app_tag, { workspace = "special:communication" })
LUA
cat > "$HOME/.config/hypr/hyprland/keybinds.lua" <<'LUA'
create_bind(vars.kbCommunicationWs, fn.toggle("communication"))
LUA

cat > "$FAKEBIN/firefox" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  --version) echo 'Mozilla Firefox 153.0.4'; exit 0 ;;
  --help) echo '--profile --new-instance --new-window'; exit 0 ;;
esac
exit 0
SH
cat > "$FAKEBIN/curl" <<'SH'
#!/usr/bin/env bash
set -e
out=""
while (($#)); do
  if [[ "$1" == "--output" ]]; then shift; out="$1"; fi
  shift || true
done
[[ -n "$out" ]]
printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"><path d="M0 0h1v1H0z"/></svg>' > "$out"
SH
cat > "$FAKEBIN/hyprctl" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  reload) echo ok ;;
  configerrors) echo 'no errors' ;;
  clients|monitors) [[ "${2:-}" == "-j" ]] && echo '[]' || true ;;
  *) exit 0 ;;
esac
SH
for cmd in desktop-file-validate update-desktop-database gtk-update-icon-cache; do
cat > "$FAKEBIN/$cmd" <<'SH'
#!/usr/bin/env bash
exit 0
SH
chmod +x "$FAKEBIN/$cmd"
done
chmod +x "$FAKEBIN/firefox" "$FAKEBIN/curl" "$FAKEBIN/hyprctl"
export PATH="$FAKEBIN:/usr/bin:/bin"

"$ROOT_DIR/install.sh" chatgpt --no-applet >/dev/null
[[ -x "$HOME/.local/bin/caelestia-webapp-chatgpt" ]]
[[ -f "$HOME/.local/share/caelestia-webapps/apps/chatgpt/installed.conf" ]]

rm -f "$HOME/.local/bin/caelestia-webapp-chatgpt"
"$ROOT_DIR/repair.sh" --app chatgpt --quiet
[[ -x "$HOME/.local/bin/caelestia-webapp-chatgpt" ]]

# Engine repair must never create or modify Caelestia QML state.
[[ ! -e "$HOME/.config/quickshell/caelestia" ]]
pass "Engine-only Repair rekonstruiert Runtime ohne Caelestia-QML-Integration"
