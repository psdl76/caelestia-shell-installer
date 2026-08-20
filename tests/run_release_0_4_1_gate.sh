#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(<"$ROOT/VERSION")"
OUT="${1:-$ROOT/dist/release-$VERSION}"
TOP="caelestia-webapps-$VERSION"

[[ "$VERSION" == "0.4.1" ]]
bash "$ROOT/tests/run_phase18_1_gate.sh"
python3 "$ROOT/tests/test_release_0_4_1.py"

mkdir -p "$OUT"
TARBALL="$("$ROOT/packaging/make-runtime-tarball.sh" "$VERSION" "$OUT")"
LIST="$(mktemp)"
trap 'rm -f -- "$LIST"' EXIT
tar -tzf "$TARBALL" > "$LIST"
awk -v top="$TOP" '$0 != top && index($0, top "/") != 1 { exit 1 }' "$LIST"
! grep -Eq '(^|/)(\.git|tests|__pycache__|\.pytest_cache|\.zed|\.vscode)(/|$)' "$LIST"
grep -Fqx "$TOP/VERSION" "$LIST"
grep -Fqx "$TOP/manager/style/I18n.qml" "$LIST"

"$ROOT/packaging/build-arch-package.sh" "$OUT/arch"
PACKAGE="$(find "$OUT/arch" -maxdepth 1 -type f -name "caelestia-webapps-$VERSION-1-any.pkg.tar.*" -print -quit)"
[[ -n "$PACKAGE" && -f "$PACKAGE" ]]
bsdtar -tf "$PACKAGE" | grep -Fq 'usr/bin/caelestia-webapps'
bsdtar -tf "$PACKAGE" | grep -Fq 'usr/bin/caelestia-webapps-manager'
bsdtar -tf "$PACKAGE" | grep -Fq 'usr/lib/caelestia-webapps/manager/style/I18n.qml'

(
    cd "$OUT"
    sha256sum "$(basename -- "$TARBALL")" "arch/$(basename -- "$PACKAGE")" > SHA256SUMS
)
(
    cd "$OUT"
    sha256sum -c SHA256SUMS
)

echo "PASS: Caelestia WebApps $VERSION local release artifacts"
