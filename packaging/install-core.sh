\
#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${HOME}/.local"

usage() {
    cat <<'EOF'
Usage: packaging/install-core.sh [--prefix PATH]

Installs only the package-owned Caelestia WebApps core.
Default prefix: ~/.local

Examples:
  ./packaging/install-core.sh
  ./packaging/install-core.sh --prefix /usr

User data under ~/.config, ~/.local/share and ~/.local/state is never removed
or replaced by this installer.
EOF
}

while (($#)); do
    case "$1" in
        --prefix)
            [[ $# -ge 2 ]] || { echo "Missing value for --prefix" >&2; exit 2; }
            PREFIX="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

PREFIX="${PREFIX%/}"
[[ -n "$PREFIX" ]] || PREFIX="/"
CORE_DIR="$PREFIX/lib/caelestia-webapps"
BIN_DIR="$PREFIX/bin"
APP_DIR="$PREFIX/share/applications"
ICON_DIR="$PREFIX/share/icons/hicolor/scalable/apps"
LICENSE_DIR="$PREFIX/share/licenses/caelestia-webapps"
MANIFEST="$SOURCE_ROOT/packaging/runtime-entries.txt"
VERSION="$(<"$SOURCE_ROOT/VERSION")"

[[ -f "$MANIFEST" ]] || { echo "Runtime manifest missing: $MANIFEST" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }
command -v bash >/dev/null 2>&1 || { echo "bash is required" >&2; exit 1; }

mkdir -p "$PREFIX/lib" "$BIN_DIR" "$APP_DIR" "$ICON_DIR" "$LICENSE_DIR"
STAGE="$(mktemp -d "$PREFIX/lib/.caelestia-webapps.stage.XXXXXX")"
OLD=""
cleanup() {
    [[ -n "${STAGE:-}" && -d "${STAGE:-}" ]] && rm -rf -- "$STAGE" || true
    [[ -n "${OLD:-}" && -d "${OLD:-}" ]] && rm -rf -- "$OLD" || true
    return 0
}
trap cleanup EXIT

while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    [[ "$entry" != /* && "$entry" != *".."* ]] || { echo "Unsafe manifest entry: $entry" >&2; exit 1; }
    src="$SOURCE_ROOT/$entry"
    [[ -e "$src" ]] || { echo "Manifest entry missing: $src" >&2; exit 1; }
    cp -a -- "$src" "$STAGE/"
done < "$MANIFEST"

cat > "$STAGE/PACKAGE-METADATA" <<EOF
PACKAGE_FORMAT=1
PACKAGE_ID=caelestia-webapps
PACKAGE_VERSION=$VERSION
EOF

# Validate the staged core before it can replace a working one.
[[ -x "$STAGE/bin/caelestia-webapps" ]] || chmod 755 "$STAGE/bin/caelestia-webapps"
for script in install.sh repair.sh uninstall.sh upgrade.sh manager.sh catalog.sh; do
    bash -n "$STAGE/$script"
done
python3 -m py_compile "$STAGE/bin/caelestia-webapps" \
    "$STAGE/scripts/app_schema.py" \
    "$STAGE/scripts/generate_catalog.py" \
    "$STAGE/scripts/user_apps.py"

TEST_HOME="$(mktemp -d)"
trap 'rm -rf -- "$TEST_HOME"; cleanup' EXIT
HOME="$TEST_HOME" \
XDG_CONFIG_HOME="$TEST_HOME/config" \
XDG_DATA_HOME="$TEST_HOME/data" \
XDG_STATE_HOME="$TEST_HOME/state" \
XDG_CACHE_HOME="$TEST_HOME/cache" \
XDG_RUNTIME_DIR="$TEST_HOME/runtime" \
    "$STAGE/bin/caelestia-webapps" list >/dev/null
rm -rf -- "$TEST_HOME"
trap cleanup EXIT

# Atomic core replacement. The old package tree is kept only until the new one
# is committed, then removed. User directories are outside CORE_DIR entirely.
if [[ -e "$CORE_DIR" ]]; then
    OLD="$PREFIX/lib/.caelestia-webapps.old.$$"
    rm -rf -- "$OLD"
    mv -- "$CORE_DIR" "$OLD"
fi
if ! mv -- "$STAGE" "$CORE_DIR"; then
    [[ -n "$OLD" && -d "$OLD" ]] && mv -- "$OLD" "$CORE_DIR"
    echo "Core install failed; previous core restored." >&2
    exit 1
fi
STAGE=""
rm -rf -- "$OLD" 2>/dev/null || true
OLD=""

write_wrapper() {
    local target="$1" out="$2" label="$3" tmp
    tmp="$(mktemp "${out}.tmp.XXXXXX")"
    cat > "$tmp" <<EOF
#!/usr/bin/env bash
# caelestia-webapps-package-wrapper-v1
exec "$target" "\$@"
EOF
    chmod 755 "$tmp"
    mv -f -- "$tmp" "$out"
    printf 'Installed %-22s %s\n' "$label" "$out"
}

write_wrapper "$CORE_DIR/bin/caelestia-webapps" "$BIN_DIR/caelestia-webapps" "CLI"
write_wrapper "$CORE_DIR/manager.sh" "$BIN_DIR/caelestia-webapps-manager" "Manager"
install -m 644 "$SOURCE_ROOT/packaging/caelestia-webapps-manager.desktop" \
    "$APP_DIR/caelestia-webapps-manager.desktop"
install -m 644 "$SOURCE_ROOT/assets/branding/caelestia-webapps.svg" \
    "$ICON_DIR/caelestia-webapps.svg"
install -m 644 "$SOURCE_ROOT/LICENSE" "$LICENSE_DIR/LICENSE"

printf '\nCaelestia WebApps core installed.\n'
printf 'Version : %s\n' "$VERSION"
printf 'Core    : %s\n' "$CORE_DIR"
printf 'CLI     : %s\n' "$BIN_DIR/caelestia-webapps"
printf 'Manager : %s\n' "$BIN_DIR/caelestia-webapps-manager"
printf '\nUser WebApps, profiles, logs and backups were not touched.\n'
