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
grep -Fqx "sha256sums=('57a58806c7d4cfd2d7b43f82a389af364edcdfb7c03a971d9126db6edec643b2')" "$PKGBUILD"
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

echo "PASS: AUR PKGBUILD and committed .SRCINFO are synchronized"
