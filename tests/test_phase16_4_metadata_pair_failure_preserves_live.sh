#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
COPY="$TMP/project"
cp -a "$ROOT" "$COPY"
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
mkdir -p "$XDG_CONFIG_HOME/caelestia-webapps/apps" "$HOME/.local/share/caelestia-webapps"
DATA="$HOME/.local/share/caelestia-webapps"
printf '%s\n' 'OLD-CATALOG' > "$DATA/catalog.json"
printf '%s\n' 'OLD-REGISTRY' > "$DATA/applet-registry.json"
cat > "$COPY/scripts/generate_applet_registry.py" <<'PY'
#!/usr/bin/env python3
raise SystemExit(9)
PY
chmod +x "$COPY/scripts/generate_applet_registry.py"

set +e
(
  ROOT_DIR="$COPY"
  APP_DEF_DIR="$COPY/apps"
  USER_APP_DEF_DIR="$XDG_CONFIG_HOME/caelestia-webapps/apps"
  DATA_ROOT="$DATA"
  source "$COPY/lib/common.sh"
  source "$COPY/lib/catalog.sh"
  generate_catalog
) >/dev/null 2>&1
rc=$?
set -e
[[ $rc -ne 0 ]]
[[ "$(cat "$DATA/catalog.json")" == 'OLD-CATALOG' ]]
[[ "$(cat "$DATA/applet-registry.json")" == 'OLD-REGISTRY' ]]
echo "PASS: Phase16.4 failed metadata generation preserves live pair"
