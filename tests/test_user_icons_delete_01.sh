#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home" XDG_CONFIG_HOME="$TMP/config" XDG_DATA_HOME="$TMP/data"; mkdir -p "$HOME"
TOOL="$ROOT/scripts/user_apps.py"
cat > "$TMP/icon.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16"><rect width="16" height="16"/></svg>
SVG
payload=$(python3 -c 'import json,sys; print(json.dumps({"id":"local-icon-app","name":"Local Icon App","url":"https://example.com","category":"ai","iconMode":"local","iconFile":sys.argv[1]}))' "$TMP/icon.svg")
python3 "$TOOL" create "$payload" >/dev/null
DEF="$XDG_CONFIG_HOME/caelestia-webapps/apps/local-icon-app.conf"; ICON="$XDG_DATA_HOME/caelestia-webapps/user-icons/local-icon-app.svg"
[[ -f "$DEF" && -f "$ICON" ]]; grep -Fq 'APP_ICON_MODE=local' "$DEF"; grep -Fq "ICON_LOCAL_FILE=$ICON" "$DEF"
python3 "$TOOL" delete local-icon-app >/dev/null; [[ ! -e "$DEF" && ! -e "$ICON" ]]
printf '\x89PNG\r\n\x1a\nFAKEPNGDATA' > "$TMP/icon.png"
payload=$(python3 -c 'import json,sys; print(json.dumps({"id":"png-icon-app","name":"PNG Icon App","url":"https://example.org","category":"messaging","iconMode":"local","iconFile":sys.argv[1]}))' "$TMP/icon.png")
python3 "$TOOL" create "$payload" >/dev/null
ICON="$XDG_DATA_HOME/caelestia-webapps/user-icons/png-icon-app.svg"; [[ -f "$ICON" ]]; grep -Fq 'data:image/png;base64,' "$ICON"
echo 'PASS: persistent local SVG/PNG user icons and cleanup'
