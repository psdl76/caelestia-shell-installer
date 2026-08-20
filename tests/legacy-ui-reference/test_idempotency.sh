#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

export HOME="$TMP/home"
export USER="testuser"
FAKEBIN="$TMP/bin"
mkdir -p "$HOME/.config/hypr/hyprland" "$FAKEBIN"

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

snapshot() {
  local out="$1"
  {
    sha256sum "$HOME/.config/hypr/hyprland/rules.lua"
    sha256sum "$HOME/.config/hypr/hyprland/keybinds.lua"
    find "$HOME/.local/share/caelestia-webapps" "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.local/share/icons" \
      -type f ! -path '*/logs/*' -print0 2>/dev/null | sort -z | xargs -0 -r sha256sum
  } | sed "s#$HOME#HOME#g" > "$out"
}

backup_count() {
  find "$HOME/.local/state/caelestia-webapps/backups" -type f 2>/dev/null | wc -l
}

run_twice_and_assert() {
  local app="$1" first second before after
  first="$TMP/${app}.first"
  second="$TMP/${app}.second"
  "$ROOT_DIR/install.sh" "$app" --no-applet >/dev/null
  snapshot "$first"
  before="$(backup_count)"
  "$ROOT_DIR/install.sh" "$app" --no-applet >/dev/null
  snapshot "$second"
  after="$(backup_count)"
  cmp -s "$first" "$second" || {
    echo "FAIL: managed state changed on second install of $app" >&2
    diff -u "$first" "$second" >&2 || true
    exit 1
  }
  [[ "$before" == "$after" ]] || {
    echo "FAIL: second install of $app created backups ($before -> $after)" >&2
    exit 1
  }
}

# Covers special-character display name (Paramount+), streaming shared setup,
# normal opaque-only apps, and the communication tagged_rule path.
run_twice_and_assert paramount-plus
run_twice_and_assert chatgpt
run_twice_and_assert google-messages

[[ "$(grep -Fc '"paramount-plus"' "$HOME/.config/hypr/hyprland/rules.lua")" -eq 2 ]] || {
  echo 'FAIL: paramount-plus should appear exactly once in opaque and once in streaming tags' >&2
  exit 1
}
[[ "$(grep -Fc '"google-messages"' "$HOME/.config/hypr/hyprland/rules.lua")" -eq 2 ]] || {
  echo 'FAIL: google-messages should appear exactly once in opaque and once in communication tags' >&2
  exit 1
}
[[ "$(grep -Fc 'create_bind("SUPER + Y", fn.toggle("streaming")) -- Caelestia WebApps: Streaming' "$HOME/.config/hypr/hyprland/keybinds.lua")" -eq 1 ]] || {
  echo 'FAIL: streaming SUPER+Y bind is not unique' >&2
  exit 1
}

echo 'PASS: repeated installs are idempotent for streaming, AI and messaging fixtures'
