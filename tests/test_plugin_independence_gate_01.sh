#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Current standalone product must not patch or import private Caelestia shell UI.
! grep -REq \
  'OriginalContent|native-drawer-poc|modules/sidebar/Content\.qml|quickshell/caelestia/modules/sidebar' \
  "$ROOT/bin" "$ROOT/lib" "$ROOT/scripts" "$ROOT/manager"

! grep -REq 'import qs\.|import Caelestia(\.|$)' "$ROOT/manager"

# Manager invokes only the stable CLI bridge for actions.
grep -Fq 'caelestia-webapps' "$ROOT/manager/shell.qml"

echo "PASS: standalone product has no active private Caelestia plugin/sidebar dependency"
