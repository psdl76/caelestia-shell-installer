#!/usr/bin/env bash
set -Eeuo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$HERE/plugin"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CAELESTIA_CONFIG_ROOT="$CONFIG_HOME/caelestia"
DEST_ROOT="$CAELESTIA_CONFIG_ROOT/plugins"
DEST="$DEST_ROOT/webapps"
BACKUP_ROOT="$CAELESTIA_CONFIG_ROOT/plugin-backups"
STAGE_ROOT="$CAELESTIA_CONFIG_ROOT/.plugin-staging"

[[ -f "$SRC/manifest.json" ]] || {
    echo "Plugin manifest missing: $SRC/manifest.json" >&2
    exit 1
}

mkdir -p "$DEST_ROOT" "$BACKUP_ROOT" "$STAGE_ROOT"

# PoC3 and earlier placed backups directly below plugins/, which is a discovery
# root in feat/plugins. Move any such historical backups out before installing,
# otherwise Caelestia sees duplicate plugin IDs and disables both copies.
shopt -s nullglob
for legacy_backup in "$DEST_ROOT"/webapps.backup.*; do
    name="$(basename -- "$legacy_backup")"
    target="$BACKUP_ROOT/$name"
    if [[ -e "$target" ]]; then
        target="$BACKUP_ROOT/${name}.$(date +%Y%m%d-%H%M%S).$$"
    fi
    mv -- "$legacy_backup" "$target"
    echo "Moved legacy discovery-root backup to: $target"
done
shopt -u nullglob

# Stage beside (not inside) the plugin discovery root. This keeps transient
# manifests invisible to the hot-reloading plugin scanner while preserving a
# same-filesystem rename into the final destination.
STAGE="$(mktemp -d "$STAGE_ROOT/webapps.XXXXXX")"
cleanup() {
    [[ -n "${STAGE:-}" && -d "${STAGE:-}" ]] && rm -rf -- "$STAGE" || true
    return 0
}
trap cleanup EXIT

cp -a "$SRC/." "$STAGE/"

if [[ -e "$DEST" ]]; then
    BACKUP="$BACKUP_ROOT/webapps.backup.$(date +%Y%m%d-%H%M%S)"
    if [[ -e "$BACKUP" ]]; then
        BACKUP="$BACKUP.$$"
    fi
    mv -- "$DEST" "$BACKUP"
    echo "Previous plugin backed up to: $BACKUP"
fi

mv -- "$STAGE" "$DEST"
STAGE=""

# Remove an empty staging parent, but never fail installation if another
# concurrent/manual test left content there.
rmdir "$STAGE_ROOT" 2>/dev/null || true

echo "Installed experimental plugin:"
echo "  $DEST"
echo
echo "Plugin ID:"
echo "  caelestia_webapps/webapps"
echo
echo "Backups are kept outside the plugin discovery root:"
echo "  $BACKUP_ROOT"
echo
echo "This helper intentionally does NOT modify shell.json or plugins.json."
