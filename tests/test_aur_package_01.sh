#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
AUR="$ROOT/packaging/aur"
PKGBUILD="$AUR/PKGBUILD"
SRCINFO="$AUR/.SRCINFO"
VERSION="$(<"$ROOT/VERSION")"

[[ -f "$PKGBUILD" ]]
[[ -f "$SRCINFO" ]]
grep -Fqx 'pkgname=caelestia-webapps' "$PKGBUILD"
grep -Fqx "pkgver=$VERSION" "$PKGBUILD"
grep -Fqx 'pkgrel=1' "$PKGBUILD"
grep -Fqx 'license=('"'"'GPL-3.0-only'"'"')' "$PKGBUILD"
grep -Fqx 'url="https://github.com/psdl76/caelestia-shell-installer"' "$PKGBUILD"
grep -Fq '/releases/download/v$pkgver/$pkgname-$pkgver.tar.gz' "$PKGBUILD"
grep -Fq 'usr/share/icons/hicolor/scalable/apps/caelestia-webapps.svg' "$PKGBUILD"

expected_sha="$(sed -n "s/^sha256sums=('\\([0-9a-f]\\{64\\}\\)')$/\\1/p" "$PKGBUILD")"
[[ -n "$expected_sha" ]]
archive_dir="$(mktemp -d)"
trap 'rm -rf -- "$archive_dir"; [[ -z "${generated:-}" ]] || rm -f -- "$generated"' EXIT
archive="$($ROOT/packaging/make-runtime-tarball.sh "$VERSION" "$archive_dir")"
actual_sha="$(sha256sum "$archive" | awk '{print $1}')"
[[ "$actual_sha" == "$expected_sha" ]]

generated="$(mktemp)"
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
grep -Fqx $'\tsha256sums = '"$expected_sha" "$SRCINFO"

echo "PASS: AUR PKGBUILD and committed .SRCINFO are synchronized"
