#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
AUR="$ROOT/packaging/aur"
PKGBUILD="$AUR/PKGBUILD"
SRCINFO="$AUR/.SRCINFO"

[[ -f "$PKGBUILD" ]]
[[ -f "$SRCINFO" ]]
grep -Fqx 'pkgname=caelestia-webapps' "$PKGBUILD"
grep -Fqx 'pkgver=0.4.2' "$PKGBUILD"
grep -Fqx 'pkgrel=1' "$PKGBUILD"
grep -Fqx 'license=('"'"'GPL-3.0-only'"'"')' "$PKGBUILD"
grep -Fqx 'url="https://github.com/psdl76/caelestia-shell-installer"' "$PKGBUILD"
grep -Fq '/releases/download/v$pkgver/$pkgname-$pkgver.tar.gz' "$PKGBUILD"
grep -Fqx "sha256sums=('66c6dfa140dde3250362225454ac8c7feca87c17b6302ac3f64ef98babb6f27f')" "$PKGBUILD"
grep -Fq 'usr/share/icons/hicolor/scalable/apps/caelestia-webapps.svg' "$PKGBUILD"

generated="$(mktemp)"
trap 'rm -f -- "$generated"' EXIT
(
  cd "$AUR"
  makepkg --printsrcinfo
) > "$generated"
cmp "$generated" "$SRCINFO"

grep -Fqx 'pkgbase = caelestia-webapps' "$SRCINFO"
grep -Fqx 'pkgname = caelestia-webapps' "$SRCINFO"
grep -Fqx $'\tlicense = GPL-3.0-only' "$SRCINFO"
grep -Fqx $'\tdepends = quickshell' "$SRCINFO"
grep -Fqx $'\tdepends = hicolor-icon-theme' "$SRCINFO"

echo "PASS: AUR PKGBUILD and committed .SRCINFO are synchronized"
