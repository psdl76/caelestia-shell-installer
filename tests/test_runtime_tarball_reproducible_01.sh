#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT

mkdir -p "$TMP/one" "$TMP/two" "$TMP/extracted"
FIRST="$($ROOT/packaging/make-runtime-tarball.sh 0.4.3 "$TMP/one")"
sleep 1
SECOND="$($ROOT/packaging/make-runtime-tarball.sh 0.4.3 "$TMP/two")"

cmp "$FIRST" "$SECOND"
tar -xzf "$FIRST" -C "$TMP/extracted"
SOURCE="$TMP/extracted/caelestia-webapps-0.4.3"

for entry in install-core.sh uninstall-core.sh runtime-entries.txt; do
    test -f "$SOURCE/packaging/$entry"
done
"$SOURCE/packaging/install-core.sh" --help >/dev/null
"$SOURCE/packaging/uninstall-core.sh" --help >/dev/null

PREFIX="$TMP/prefix"
"$SOURCE/packaging/install-core.sh" --prefix "$PREFIX" >/dev/null
grep -Fqx 'PACKAGE_VERSION=0.4.3' "$PREFIX/lib/caelestia-webapps/PACKAGE-METADATA"
test -x "$PREFIX/bin/caelestia-webapps"
"$SOURCE/packaging/uninstall-core.sh" --prefix "$PREFIX" >/dev/null
test ! -e "$PREFIX/lib/caelestia-webapps"

FIRST_MEMBER="$(tar -tzf "$FIRST" | sed -n '1p')"
[[ "$FIRST_MEMBER" == "caelestia-webapps-0.4.3/" ]]
tar -tvzf "$FIRST" | awk '$2 != "0/0" { exit 1 }'

echo "PASS: reproducible runtime tarball supports extracted rootless install/uninstall"
