#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
PREFIX="$TMP/prefix"
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/data"
export XDG_STATE_HOME="$HOME/state"
mkdir -p "$XDG_CONFIG_HOME/caelestia-webapps/apps" "$XDG_DATA_HOME/caelestia-webapps/apps/x/profile" "$XDG_STATE_HOME/caelestia-webapps/backups"
printf 'mine\n' > "$XDG_CONFIG_HOME/caelestia-webapps/apps/mine.conf"
printf '{"schemaVersion":1,"categories":{"smart-home":{"label":"Smart Home","icon":"home"}}}\n' > "$XDG_CONFIG_HOME/caelestia-webapps/categories.json"
printf 'profile\n' > "$XDG_DATA_HOME/caelestia-webapps/apps/x/profile/data"
printf 'backup\n' > "$XDG_STATE_HOME/caelestia-webapps/backups/keep"
"$ROOT/packaging/install-core.sh" --prefix "$PREFIX" >/dev/null
"$ROOT/packaging/uninstall-core.sh" --prefix "$PREFIX" >/dev/null
test ! -e "$PREFIX/lib/caelestia-webapps"
test ! -e "$PREFIX/bin/caelestia-webapps"
test ! -e "$PREFIX/bin/caelestia-webapps-manager"
test -f "$XDG_CONFIG_HOME/caelestia-webapps/apps/mine.conf"
grep -Fq '"smart-home"' "$XDG_CONFIG_HOME/caelestia-webapps/categories.json"
test -f "$XDG_DATA_HOME/caelestia-webapps/apps/x/profile/data"
test -f "$XDG_STATE_HOME/caelestia-webapps/backups/keep"
echo "PASS: package-core removal preserves config, profiles, state and backups"
