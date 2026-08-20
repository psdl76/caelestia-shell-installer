#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
PREFIX="$TMP/prefix"
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/data-xdg"
export XDG_STATE_HOME="$HOME/state-xdg"
export XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$HOME/runtime"
mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR" "$TMP/bin"
"$ROOT/packaging/install-core.sh" --prefix "$PREFIX" >/dev/null
CLI="$PREFIX/bin/caelestia-webapps"
cat > "$TMP/bin/firefox" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--version" ]]; then
  printf 'Mozilla Firefox 153.0\n'
  exit 0
fi
if [[ "${1:-}" == "--help" ]]; then
  printf '%s\n' '--profile PATH' '--new-instance' '--new-window URL'
  exit 0
fi
printf '%s\n' "$*" >> "${FIREFOX_LOG:?}"
exit 0
EOF
cat > "$TMP/bin/hyprctl" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == clients && "${2:-}" == -j ]]; then printf '[]\n'; exit 0; fi
if [[ "${1:-}" == configerrors ]]; then printf 'no errors\n'; exit 0; fi
exit 0
EOF
cat > "$TMP/bin/update-desktop-database" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$TMP/bin/gtk-update-icon-cache" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$TMP/bin/"*
export PATH="$TMP/bin:/usr/bin:/bin"
export FIREFOX_LOG="$TMP/firefox.log"
: > "$FIREFOX_LOG"
export CAELESTIA_WEBAPPS_DISABLE_NETWORK=1
cat > "$TMP/package-e2e.svg" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" rx="12"/><circle cx="32" cy="32" r="14" fill="white"/></svg>
SVG
payload="{\"id\":\"package-e2e\",\"name\":\"Package E2E\",\"url\":\"https://package-e2e.invalid/\",\"category\":\"messaging\",\"iconMode\":\"local\",\"iconFile\":\"$TMP/package-e2e.svg\"}"
"$CLI" user-create "$payload" > "$TMP/create.json"
python3 - "$TMP/create.json" <<'PY'
import json,sys
assert json.load(open(sys.argv[1]))['ok'] is True
PY
APP_ID="package-e2e"
"$CLI" install "$APP_ID" > "$TMP/install.json"
python3 - "$TMP/install.json" <<'PY'
import json,sys
assert json.load(open(sys.argv[1]))['ok'] is True
PY
test -f "$HOME/.local/share/applications/caelestia-webapp-$APP_ID.desktop"
"$CLI" status "$APP_ID" > "$TMP/status.json"
python3 - "$TMP/status.json" <<'PY'
import json,sys
obj=json.load(open(sys.argv[1])); d=obj['data']; val=d.get('installed')
if val is None and isinstance(d.get('app'),dict): val=d['app'].get('installed')
assert val is True
PY
"$CLI" setup "$APP_ID" > "$TMP/setup.json"
SETUP_PID="$(python3 - "$TMP/setup.json" <<'PY'
import json,sys
print(json.load(open(sys.argv[1]))['data']['pid'])
PY
)"
for _ in $(seq 1 80); do
  [[ -s "$FIREFOX_LOG" ]] && ! kill -0 "$SETUP_PID" 2>/dev/null && break
  sleep 0.05
done
grep -Fq -- '--profile' "$FIREFOX_LOG"
! kill -0 "$SETUP_PID" 2>/dev/null
"$CLI" repair "$APP_ID" > /dev/null
"$CLI" uninstall "$APP_ID" > /dev/null
test -f "$XDG_CONFIG_HOME/caelestia-webapps/apps/$APP_ID.conf"
test ! -f "$HOME/.local/share/applications/caelestia-webapp-$APP_ID.desktop"
"$CLI" user-delete "$APP_ID" > /dev/null
test ! -f "$XDG_CONFIG_HOME/caelestia-webapps/apps/$APP_ID.conf"
echo "PASS: installed package core executes complete user-app lifecycle"
