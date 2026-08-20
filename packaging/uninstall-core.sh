\
#!/usr/bin/env bash
set -Eeuo pipefail

PREFIX="${HOME}/.local"
usage() {
    cat <<'EOF'
Usage: packaging/uninstall-core.sh [--prefix PATH]

Removes only the package-owned Caelestia WebApps core and its launchers.
User WebApps, Firefox profiles, logs, backups and settings are preserved.
EOF
}
while (($#)); do
    case "$1" in
        --prefix) [[ $# -ge 2 ]] || exit 2; PREFIX="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done
PREFIX="${PREFIX%/}"; [[ -n "$PREFIX" ]] || PREFIX="/"
CORE_DIR="$PREFIX/lib/caelestia-webapps"

if [[ -d "$CORE_DIR" ]]; then
    meta="$CORE_DIR/PACKAGE-METADATA"
    if [[ ! -f "$meta" ]] || ! grep -Fqx 'PACKAGE_ID=caelestia-webapps' "$meta"; then
        echo "Refusing to remove unrecognized core directory: $CORE_DIR" >&2
        exit 1
    fi
    rm -rf -- "$CORE_DIR"
    echo "Removed core: $CORE_DIR"
else
    echo "Core is not installed: $CORE_DIR"
fi

remove_owned_wrapper() {
    local path="$1"
    [[ -f "$path" ]] || return 0
    if grep -Fq '# caelestia-webapps-package-wrapper-v1' "$path"; then
        rm -f -- "$path"
        echo "Removed wrapper: $path"
    else
        echo "Preserved non-owned file: $path"
    fi
}
remove_owned_wrapper "$PREFIX/bin/caelestia-webapps"
remove_owned_wrapper "$PREFIX/bin/caelestia-webapps-manager"

rm -f -- "$PREFIX/share/applications/caelestia-webapps-manager.desktop"
rm -f -- "$PREFIX/share/licenses/caelestia-webapps/LICENSE-PENDING"
rmdir --ignore-fail-on-non-empty "$PREFIX/share/licenses/caelestia-webapps" 2>/dev/null || true

cat <<'EOF'

Package core removed.
Preserved intentionally:
  ~/.config/caelestia-webapps/
  ~/.local/share/caelestia-webapps/
  ~/.local/state/caelestia-webapps/
  generated Firefox WebApp profiles and user definitions
EOF
