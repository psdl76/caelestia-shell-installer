#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
PREFIX="$TMP/prefix"
HOME_TEST="$TMP/home"
mkdir -p "$HOME_TEST" "$TMP/bin"
"$ROOT/packaging/install-core.sh" --prefix "$PREFIX" >/dev/null
test -f "$PREFIX/lib/caelestia-webapps/PACKAGE-METADATA"
grep -Fqx 'PACKAGE_ID=caelestia-webapps' "$PREFIX/lib/caelestia-webapps/PACKAGE-METADATA"
test -x "$PREFIX/bin/caelestia-webapps"
test -x "$PREFIX/bin/caelestia-webapps-manager"
test -f "$PREFIX/share/applications/caelestia-webapps-manager.desktop"
export HOME="$HOME_TEST"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_DATA_HOME="$HOME/data"
export XDG_STATE_HOME="$HOME/state"
export XDG_CACHE_HOME="$HOME/cache"
export XDG_RUNTIME_DIR="$HOME/runtime"
mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME" "$XDG_RUNTIME_DIR"
"$PREFIX/bin/caelestia-webapps" list > "$TMP/list.json"
python3 - "$TMP/list.json" <<'PY'
import json,sys
obj=json.load(open(sys.argv[1]))
assert obj['ok'] is True
assert any(a['id']=='chatgpt' for a in obj['data']['apps'])
PY
cat > "$TMP/bin/qs" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${CAELESTIA_WEBAPPS_ROOT:-}" > "${QS_ROOT_LOG:?}"
printf '%s\n' "$*" > "${QS_ARGS_LOG:?}"
exit 0
EOF
chmod +x "$TMP/bin/qs"
export PATH="$TMP/bin:/usr/bin:/bin"
export QS_ROOT_LOG="$TMP/qs-root.log"
export QS_ARGS_LOG="$TMP/qs-args.log"
"$PREFIX/bin/caelestia-webapps-manager"
grep -Fqx "$PREFIX/lib/caelestia-webapps" "$QS_ROOT_LOG"
grep -Fq "$PREFIX/lib/caelestia-webapps/manager/shell.qml" "$QS_ARGS_LOG"
echo "PASS: rootless package layout and installed CLI/Manager wrappers work"
