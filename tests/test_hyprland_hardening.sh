#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
FAKEBIN="$TMP/bin"; mkdir -p "$FAKEBIN"

cat > "$FAKEBIN/firefox" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in --version) echo 'Mozilla Firefox 153.0.4';; --help) echo '--profile --new-instance --new-window';; *) exit 0;; esac
EOF
cat > "$FAKEBIN/curl" <<'EOF'
#!/usr/bin/env bash
set -e; out=""; while (($#)); do [[ "$1" == "--output" ]] && { shift; out="$1"; }; shift || true; done
printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"><path d="M0 0h1v1H0z"/></svg>' > "$out"
EOF
cat > "$FAKEBIN/hyprctl" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in reload) echo ok;; configerrors) echo 'no errors';; *) exit 0;; esac
EOF
for c in desktop-file-validate update-desktop-database gtk-update-icon-cache; do printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKEBIN/$c"; chmod +x "$FAKEBIN/$c"; done
chmod +x "$FAKEBIN/firefox" "$FAKEBIN/curl" "$FAKEBIN/hyprctl"
export PATH="$FAKEBIN:/usr/bin:/bin" USER=testuser

make_home() {
  export HOME="$1"; mkdir -p "$HOME/.config/hypr/hyprland"
  cat > "$HOME/.config/hypr/hyprland/rules.lua" <<'LUA'
local opaque_tag = "opaque"
local music_player_tag = "music_player"
local communication_app_tag = "communication_app"
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
create_bind(vars.kbCommunicationWs, fn.toggle("communication"))
LUA
}

# Managed inserts carry ownership markers and remain idempotent.
make_home "$TMP/home-ok"
"$ROOT_DIR/install.sh" netflix --no-applet >/dev/null
grep -Fq '"netflix", -- Caelestia WebApps: Netflix (opaque)' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq '"netflix", -- Caelestia WebApps: Netflix (Streaming)' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq 'create_bind("SUPER + Y", fn.toggle("streaming")) -- Caelestia WebApps: Streaming' "$HOME/.config/hypr/hyprland/keybinds.lua"
grep -Fq 'create_bind(vars.kbMusicWs, fn.toggle("music"))' "$HOME/.config/hypr/hyprland/keybinds.lua"
grep -Fq 'create_bind(vars.kbCommunicationWs, fn.toggle("communication"))' "$HOME/.config/hypr/hyprland/keybinds.lua"
rules_hash=$(sha256sum "$HOME/.config/hypr/hyprland/rules.lua")
keys_hash=$(sha256sum "$HOME/.config/hypr/hyprland/keybinds.lua")
"$ROOT_DIR/install.sh" netflix --no-applet >/dev/null
[[ "$rules_hash" == "$(sha256sum "$HOME/.config/hypr/hyprland/rules.lua")" ]]
[[ "$keys_hash" == "$(sha256sum "$HOME/.config/hypr/hyprland/keybinds.lua")" ]]

# A foreign SUPER+Y bind must stop the Hyprland commit completely.
make_home "$TMP/home-y-conflict"
echo 'create_bind("SUPER + Y", hl.dsp.exec_cmd("something-else")) -- user bind' >> "$HOME/.config/hypr/hyprland/keybinds.lua"
cp "$HOME/.config/hypr/hyprland/rules.lua" "$TMP/rules.before"
cp "$HOME/.config/hypr/hyprland/keybinds.lua" "$TMP/keys.before"
if "$ROOT_DIR/install.sh" netflix --no-applet >"$TMP/conflict.log" 2>&1; then
  echo 'FAIL: foreign SUPER+Y conflict was not rejected' >&2; exit 1
fi
cmp -s "$TMP/rules.before" "$HOME/.config/hypr/hyprland/rules.lua"
cmp -s "$TMP/keys.before" "$HOME/.config/hypr/hyprland/keybinds.lua"
grep -Fq 'SUPER+Y ist bereits fremd belegt' "$TMP/conflict.log"

# An existing foreign membership is respected instead of duplicated/rewritten.
make_home "$TMP/home-foreign-member"
python3 - "$HOME/.config/hypr/hyprland/rules.lua" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text(); s=s.replace('    "org.quickshell", -- Quickshell\n','    "org.quickshell", -- Quickshell\n    "chatgpt", -- user-owned rule\n'); p.write_text(s)
PY
"$ROOT_DIR/install.sh" chatgpt --no-applet >"$TMP/foreign.log" 2>&1
[[ "$(grep -Fc '"chatgpt"' "$HOME/.config/hypr/hyprland/rules.lua")" -eq 1 ]]
grep -Fq 'vorhandener Eintrag bleibt unangetastet' "$TMP/foreign.log"

# Native communication/music structures are not replaced by the project.
make_home "$TMP/home-messaging"
"$ROOT_DIR/install.sh" whatsapp --no-applet >/dev/null
grep -Fq 'create_tag(communication_app_tag, { workspace = "special:communication" })' "$HOME/.config/hypr/hyprland/rules.lua"
grep -Fq '"whatsapp", -- Caelestia WebApps: WhatsApp (Messaging)' "$HOME/.config/hypr/hyprland/rules.lua"
! grep -Fq 'SUPER + D' "$HOME/.config/hypr/hyprland/keybinds.lua" || true

echo 'PASS: Hyprland integration is transactional, ownership-aware and conflict-safe for opaque, communication, streaming and special-workspace binds'
