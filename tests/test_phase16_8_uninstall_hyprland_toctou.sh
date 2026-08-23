#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$TMP/state"
export XDG_RUNTIME_DIR="$TMP/runtime"
export CAELESTIA_WEBAPPS_DISABLE_NETWORK=1
FAKEBIN="$TMP/bin"
LIVE_RULES="$HOME/.config/hypr/hyprland/rules.lua"
export LIVE_RULES
mkdir -p "$FAKEBIN" "$XDG_RUNTIME_DIR" "$(dirname "$LIVE_RULES")" \
    "$HOME/.local/share/caelestia-webapps/apps/airbnb/profile" \
    "$HOME/.local/bin"

cat > "$LIVE_RULES" <<'LUA'
local opaque_tag = "opaque"
tagged_rule(opaque_tag, {
    "airbnb", -- Caelestia WebApps: Airbnb (opaque)
}, "class")
create_tag(opaque_tag, { opaque = true })
LUA
printf 'INSTALLER_VERSION="0.4.2"\n' > "$HOME/.local/share/caelestia-webapps/apps/airbnb/installed.conf"
printf '#!/usr/bin/env bash\n' > "$HOME/.local/bin/caelestia-webapp-airbnb"
chmod +x "$HOME/.local/bin/caelestia-webapp-airbnb"

cat > "$FAKEBIN/luac" <<'SH'
#!/usr/bin/env bash
printf '%s\n' '-- concurrent user edit' >> "${LIVE_RULES:?}"
exit 0
SH
chmod +x "$FAKEBIN/luac"
export PATH="$FAKEBIN:/usr/bin:/bin"

set +e
"$ROOT/uninstall.sh" airbnb >"$TMP/uninstall.log" 2>&1
rc=$?
set -e

[[ $rc -ne 0 ]]
grep -Fq 'während der Deinstallation extern verändert' "$TMP/uninstall.log"
grep -Fq -- '-- concurrent user edit' "$LIVE_RULES"
[[ -d "$HOME/.local/share/caelestia-webapps/apps/airbnb" ]]
[[ -x "$HOME/.local/bin/caelestia-webapp-airbnb" ]]

echo "PASS: uninstall aborts before deleting artifacts when live Hyprland config changes"
