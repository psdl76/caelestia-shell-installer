#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf -- "$TMP"' EXIT
TAR="$($ROOT/packaging/make-runtime-tarball.sh 0.4.0 "$TMP")"
test -f "$TAR"
LIST="$TMP/list"
tar -tzf "$TAR" > "$LIST"
grep -Fq 'caelestia-webapps-0.4.0/bin/caelestia-webapps' "$LIST"
grep -Fq 'caelestia-webapps-0.4.0/manager/shell.qml' "$LIST"
grep -Fq 'caelestia-webapps-0.4.0/packaging/arch/wrappers/caelestia-webapps' "$LIST"
! grep -Fq 'caelestia-webapps-0.4.0/tests/' "$LIST"
! grep -Fq 'NATIVE_DRAWER_POC' "$LIST"
echo "PASS: runtime source tarball excludes development/test history"
