#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$TMP/config"
export XDG_DATA_HOME="$TMP/data"
export XDG_STATE_HOME="$TMP/state"
export XDG_CACHE_HOME="$TMP/cache"
export XDG_RUNTIME_DIR="$TMP/runtime"
mkdir -p \
  "$HOME/.local/share/caelestia-webapps/apps/youtube/profile" \
  "$HOME/.local/share/applications" \
  "$HOME/.local/share/icons/hicolor/scalable/apps" \
  "$HOME/.local/bin" \
  "$XDG_STATE_HOME/caelestia-webapps" \
  "$XDG_RUNTIME_DIR" \
  "$TMP/bin"

# Installed fixture expected by uninstall.sh.
printf 'INSTALLER_VERSION="0.3.6"\n' > "$HOME/.local/share/caelestia-webapps/apps/youtube/installed.conf"
: > "$HOME/.local/bin/caelestia-webapp-youtube"
: > "$HOME/.local/bin/caelestia-webapp-youtube-setup"
: > "$HOME/.local/share/applications/caelestia-webapp-youtube.desktop"
: > "$HOME/.local/share/icons/hicolor/scalable/apps/youtube.svg"

cat > "$XDG_STATE_HOME/caelestia-webapps/applets.json" <<'JSON'
{
  "schemaVersion": 1,
  "enabled": {
    "youtube": true,
    "whatsapp": true
  }
}
JSON
cat > "$XDG_STATE_HOME/caelestia-webapps/applet-settings.json" <<'JSON'
{
  "schemaVersion": 1,
  "apps": {
    "youtube": {
      "live_preview": false
    }
  }
}
JSON
cp "$XDG_STATE_HOME/caelestia-webapps/applet-settings.json" "$TMP/settings.before"

cat > "$TMP/bin/hyprctl" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == configerrors ]]; then echo 'no errors'; fi
exit 0
SH
for cmd in update-desktop-database gtk-update-icon-cache; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$TMP/bin/$cmd"
  chmod +x "$TMP/bin/$cmd"
done
chmod +x "$TMP/bin/hyprctl"
export PATH="$TMP/bin:/usr/bin:/bin"
export CAELESTIA_WEBAPPS_DISABLE_NETWORK=1

"$ROOT/uninstall.sh" youtube >/dev/null

python3 - "$XDG_STATE_HOME/caelestia-webapps/applets.json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
assert p == {"schemaVersion":1,"enabled":{"youtube":False,"whatsapp":True}}, p
PY
cmp "$TMP/settings.before" "$XDG_STATE_HOME/caelestia-webapps/applet-settings.json"

test ! -e "$HOME/.local/share/caelestia-webapps/apps/youtube"
test ! -e "$HOME/.local/share/applications/caelestia-webapp-youtube.desktop"

echo "PASS: Phase16.8 successful uninstall resets only applet activation and preserves capability settings"
