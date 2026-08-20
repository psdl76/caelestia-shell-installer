#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export CAELESTIA_WEBAPPS_ROOT="$ROOT_DIR"

# The Manager UI owns its startup preflight. Quickshell is launched immediately
# so the user gets visual feedback while theme, local icons and catalog data are
# prepared. See scripts/manager_preflight.sh and manager/shell.qml.
if command -v qs >/dev/null 2>&1; then
    exec qs -p "$ROOT_DIR/manager/shell.qml"
elif command -v quickshell >/dev/null 2>&1; then
    exec quickshell -p "$ROOT_DIR/manager/shell.qml"
else
    echo "Fehler: Quickshell wurde nicht gefunden." >&2
    exit 1
fi
