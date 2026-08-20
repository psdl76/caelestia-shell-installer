#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(<"$ROOT/VERSION")"
OUT="${1:-$ROOT/dist/release-$VERSION}"
TOP="caelestia-webapps-$VERSION"

[[ "$VERSION" == "0.4.2" ]]
bash "$ROOT/tests/run_phase18_2_gate.sh"
python3 "$ROOT/tests/test_branding_assets.py"
python3 "$ROOT/tests/test_phase20_1_product_branding.py"
python3 "$ROOT/tests/test_release_0_4_2.py"

mkdir -p "$OUT"
TARBALL="$("$ROOT/packaging/make-runtime-tarball.sh" "$VERSION" "$OUT")"
LIST="$(mktemp)"
trap 'rm -f -- "$LIST"' EXIT
tar -tzf "$TARBALL" > "$LIST"
awk -v top="$TOP" '$0 != top && index($0, top "/") != 1 { exit 1 }' "$LIST"
! grep -Eq '(^|/)(\.git|tests|__pycache__|\.pytest_cache|\.zed|\.vscode)(/|$)' "$LIST"
grep -Fqx "$TOP/VERSION" "$LIST"
grep -Fqx "$TOP/assets/branding/caelestia-webapps.svg" "$LIST"
grep -Fqx "$TOP/manager/style/AnimatedBrandLogo.qml" "$LIST"

"$ROOT/packaging/build-arch-package.sh" "$OUT/arch"
PACKAGE="$(find "$OUT/arch" -maxdepth 1 -type f -name "caelestia-webapps-$VERSION-1-any.pkg.tar.*" -print -quit)"
[[ -n "$PACKAGE" && -f "$PACKAGE" ]]
bsdtar -tf "$PACKAGE" | grep -Fq 'usr/bin/caelestia-webapps-manager'
bsdtar -tf "$PACKAGE" | grep -Fq 'usr/lib/caelestia-webapps/assets/branding/caelestia-webapps.svg'
bsdtar -tf "$PACKAGE" | grep -Fq 'usr/share/icons/hicolor/scalable/apps/caelestia-webapps.svg'

(
    cd "$OUT"
    sha256sum "$(basename -- "$TARBALL")" "arch/$(basename -- "$PACKAGE")" > SHA256SUMS
)
(
    cd "$OUT"
    sha256sum -c SHA256SUMS
)

echo "PASS: Caelestia WebApps $VERSION local release artifacts"
