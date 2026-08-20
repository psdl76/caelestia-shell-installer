#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
FAKEBIN="$TMP/bin"
mkdir -p "$FAKEBIN"

cat > "$FAKEBIN/firefox" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  --version) echo 'Mozilla Firefox 153.0' ;;
  --help) echo '--profile --new-instance --new-window' ;;
  *) exit 0 ;;
esac
SH
cat > "$FAKEBIN/curl" <<'SH'
#!/usr/bin/env bash
set -e
out=""
while (($#)); do
  [[ "$1" == "--output" ]] && { shift; out="$1"; }
  shift || true
done
printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"><path d="M0 0h1v1H0z"/></svg>' > "$out"
SH
cat > "$FAKEBIN/hyprctl" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${HYPR_LOG:?}"
case "${1:-}" in
  systeminfo) printf 'configProvider: %s\n' "${HYPR_PROVIDER:-lua}" ;;
  getoption) printf '{"option":"misc:disable_autoreload","bool":false,"set":false}\n' ;;
  configerrors) echo 'no errors' ;;
  *) echo ok ;;
esac
SH
for command_name in desktop-file-validate update-desktop-database gtk-update-icon-cache; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$FAKEBIN/$command_name"
  chmod +x "$FAKEBIN/$command_name"
done
chmod +x "$FAKEBIN/firefox" "$FAKEBIN/curl" "$FAKEBIN/hyprctl"
export PATH="$FAKEBIN:/usr/bin:/bin" USER=testuser
export HYPR_LOG="$TMP/hypr.log"
export XDG_RUNTIME_DIR="$TMP/runtime"
mkdir -p "$XDG_RUNTIME_DIR"

make_home() {
  export HOME="$1"
  mkdir -p "$HOME/.config/hypr/hyprland"
  cat > "$HOME/.config/hypr/hyprland/rules.lua" <<'LUA'
local opaque_tag = "opaque"
tagged_rule(opaque_tag, {
    "org.quickshell", -- Quickshell
}, "class")
create_tag(opaque_tag, { opaque = true })
LUA
  printf '%s\n' '-- test keybind fixture' > "$HOME/.config/hypr/hyprland/keybinds.lua"
}

# Current Lua Hyprland: persist and activate only the app rule; never reload the
# complete config and therefore never trigger a monitor modeset.
make_home "$TMP/home-lua"
: > "$HYPR_LOG"
export HYPR_PROVIDER=lua
if ! "$ROOT/install.sh" airbnb --no-applet >"$TMP/install-lua.log" 2>&1; then
  cat "$TMP/install-lua.log" >&2
  exit 1
fi
grep -Fq 'eval hl.config({ misc = { disable_autoreload = true } }); hl.exec_scheduled_prop_refresh_immediately()' "$HYPR_LOG"
grep -Fq 'eval hl.window_rule({ name = "caelestia-webapps-airbnb-opaque"' "$HYPR_LOG"
grep -Fq 'eval hl.config({ misc = { disable_autoreload = false } }); hl.exec_scheduled_prop_refresh_immediately()' "$HYPR_LOG"
! grep -Eq '^reload($| )' "$HYPR_LOG"

if ! "$ROOT/uninstall.sh" airbnb >"$TMP/uninstall-lua.log" 2>&1; then
  cat "$TMP/uninstall-lua.log" >&2
  exit 1
fi
grep -Fq 'keyword windowrule[caelestia-webapps-airbnb-opaque]:enable false' "$HYPR_LOG"
! grep -Eq '^reload($| )' "$HYPR_LOG"

# Non-Lua/older configurations keep the proven reload-and-configerror fallback.
make_home "$TMP/home-fallback"
: > "$HYPR_LOG"
export HYPR_PROVIDER=hyprlang
if ! "$ROOT/install.sh" airbnb --no-applet >"$TMP/install-fallback.log" 2>&1; then
  cat "$TMP/install-fallback.log" >&2
  exit 1
fi
grep -Eq '^reload($| )' "$HYPR_LOG"
grep -Eq '^configerrors($| )' "$HYPR_LOG"

echo "PASS: Lua Hyprland app lifecycle avoids full reload while legacy fallback remains"
