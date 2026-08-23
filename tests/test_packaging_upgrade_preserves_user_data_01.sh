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
mkdir -p "$XDG_CONFIG_HOME/caelestia-webapps/apps" "$XDG_DATA_HOME/caelestia-webapps/apps/demo/profile" "$XDG_STATE_HOME/caelestia-webapps/logs"
"$ROOT/packaging/install-core.sh" --prefix "$PREFIX" >/dev/null
printf 'USER_SENTINEL=1\n' > "$XDG_CONFIG_HOME/caelestia-webapps/apps/my-own-app.conf"
printf '{"schemaVersion":1,"categories":{"smart-home":{"label":"Smart Home","icon":"home"}}}\n' > "$XDG_CONFIG_HOME/caelestia-webapps/categories.json"
printf 'profile\n' > "$XDG_DATA_HOME/caelestia-webapps/apps/demo/profile/user-data"
printf 'log\n' > "$XDG_STATE_HOME/caelestia-webapps/logs/user.log"
printf 'obsolete\n' > "$PREFIX/lib/caelestia-webapps/obsolete-package-file"
"$ROOT/packaging/install-core.sh" --prefix "$PREFIX" >/dev/null
test ! -e "$PREFIX/lib/caelestia-webapps/obsolete-package-file"
test -f "$XDG_CONFIG_HOME/caelestia-webapps/apps/my-own-app.conf"
grep -Fq '"smart-home"' "$XDG_CONFIG_HOME/caelestia-webapps/categories.json"
test -f "$XDG_DATA_HOME/caelestia-webapps/apps/demo/profile/user-data"
test -f "$XDG_STATE_HOME/caelestia-webapps/logs/user.log"
grep -Fqx 'USER_SENTINEL=1' "$XDG_CONFIG_HOME/caelestia-webapps/apps/my-own-app.conf"
echo "PASS: atomic core upgrade removes stale package files and preserves all user-owned data"
