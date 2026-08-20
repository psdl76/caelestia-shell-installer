#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

export HOME="$TMP/home"
unset XDG_STATE_HOME || true
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_RUNTIME_DIR="$TMP/runtime"
export CAELESTIA_WEBAPPS_DISABLE_NETWORK=1
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR"

PREFIX="$TMP/prefix"
"$ROOT/packaging/install-core.sh" --prefix "$PREFIX" >/dev/null
RUNTIME="$PREFIX/lib/caelestia-webapps"
STATE="$HOME/.local/state/caelestia-webapps"
mkdir -p "$STATE"

cat > "$STATE/applets.json" <<'JSON'
{
  "youtube": "on",
  "whatsapp": 0,
  "broken": "wat"
}
JSON
cat > "$STATE/applet-settings.json" <<'JSON'
{
  "schemaVersion": 0,
  "apps": {
    "youtube": {
      "live_preview": "off",
      "pin": true,
      "broken": "wat"
    }
  }
}
JSON

"$RUNTIME/upgrade.sh" --preflight >/dev/null

python3 - "$STATE/applets.json" "$STATE/applet-settings.json" <<'PY'
import json,sys
activation=json.load(open(sys.argv[1]))
settings=json.load(open(sys.argv[2]))
assert activation == {
    "schemaVersion": 1,
    "enabled": {"whatsapp": False, "youtube": True},
}, activation
assert settings == {
    "schemaVersion": 1,
    "apps": {"youtube": {"live_preview": False, "pin": True}},
}, settings
PY

# A second preflight must be a no-op for runtime state and create no new backup.
backup_count_before="$(find "$STATE/migration-backups" -maxdepth 1 -type f -name '*.bak' | wc -l)"
sha_before="$(sha256sum "$STATE/applets.json" "$STATE/applet-settings.json")"
"$RUNTIME/upgrade.sh" --preflight >/dev/null
backup_count_after="$(find "$STATE/migration-backups" -maxdepth 1 -type f -name '*.bak' | wc -l)"
sha_after="$(sha256sum "$STATE/applets.json" "$STATE/applet-settings.json")"
[[ "$backup_count_before" == "$backup_count_after" ]]
[[ "$sha_before" == "$sha_after" ]]

echo "PASS: Phase16.8 installed upgrade preflight migrates legacy runtime state once and is idempotent"
