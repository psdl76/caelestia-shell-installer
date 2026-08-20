#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$TMP/config"
export XDG_DATA_HOME="$TMP/data"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"

"$ROOT_DIR/catalog.sh" validate >/dev/null

# Category-owned fields must not creep back into app-specific definitions.
if grep -REn '^(APPLET_VISIBLE|APPLET_SHOW_BADGE|APPLET_NOTIFICATION_PREVIEW|HYPR_SHARED_[A-Z0-9_]*)=' "$ROOT_DIR/apps"/*.conf; then
    echo "FAIL: category-owned fields found in apps/*.conf" >&2
    exit 1
fi

# Verify category policies from the single source of truth.
python3 - "$ROOT_DIR/config/categories.json" <<'PY'
import json,sys
j=json.load(open(sys.argv[1]))['categories']
assert j['messaging']['appletVisible'] is True
assert j['messaging']['appletShowBadge'] is True
assert j['messaging']['appletNotificationPreview'] is True
assert j['ai']['appletVisible'] is False
assert j['ai']['appletShowBadge'] is False
assert j['video']['appletVisible'] is False
assert j['video']['hyprSharedWorkspace'] == 'streaming'
assert j['video']['hyprSharedKeybind'].startswith('create_bind("SUPER + Y"')
PY

echo "PASS: app definitions use the central category schema"
