#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/lib/locking.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_RUNTIME_DIR="$TMP/run"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR"
acquire_mutation_lock parent
[[ "$CAELESTIA_WEBAPPS_LOCK_HELD" == exclusive ]]
# Nested acquisition in same inherited process is a no-op, not a deadlock.
acquire_mutation_lock child
[[ "$CAELESTIA_WEBAPPS_LOCK_HELD" == exclusive ]]
echo "PASS: nested mutation lock inherits without deadlock"
