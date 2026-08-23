#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

export HOME="$TMP/home"
export XDG_CONFIG_HOME="$HOME/.config"
DATA="$HOME/.local/share/caelestia-webapps"
mkdir -p "$XDG_CONFIG_HOME/caelestia-webapps/apps" "$DATA"
printf '%s\n' 'OLD-CATALOG' > "$DATA/catalog.json"
printf '%s\n' 'OLD-REGISTRY' > "$DATA/applet-registry.json"

set +e
(
    ROOT_DIR="$ROOT"
    APP_DEF_DIR="$ROOT/apps"
    USER_APP_DEF_DIR="$XDG_CONFIG_HOME/caelestia-webapps/apps"
    DATA_ROOT="$DATA"
    source "$ROOT/lib/common.sh"
    eval "$(declare -f atomic_replace_file | sed '1s/atomic_replace_file/real_atomic_replace_file/')"
    source "$ROOT/lib/catalog.sh"
    replace_count=0
    atomic_replace_file() {
        replace_count=$((replace_count + 1))
        [[ "$replace_count" -ne 2 ]] || return 1
        real_atomic_replace_file "$@"
    }
    generate_catalog
) >"$TMP/generate.log" 2>&1
rc=$?
set -e

[[ $rc -ne 0 ]]
[[ "$(<"$DATA/catalog.json")" == "OLD-CATALOG" ]]
[[ "$(<"$DATA/applet-registry.json")" == "OLD-REGISTRY" ]]
grep -Fq 'der Web-App-Katalog wurde zurückgesetzt' "$TMP/generate.log"

echo "PASS: failed registry commit atomically restores the previous metadata pair"
