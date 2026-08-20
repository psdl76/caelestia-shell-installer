#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(<"$ROOT/VERSION")"
BUILD_DIR="${1:-$ROOT/dist/arch}"
command -v makepkg >/dev/null 2>&1 || {
    echo "makepkg not found. Run this helper on Arch Linux with pacman available." >&2
    exit 1
}
mkdir -p "$BUILD_DIR"
TARBALL="$($ROOT/packaging/make-runtime-tarball.sh "$VERSION" "$BUILD_DIR")"
SHA="$(sha256sum "$TARBALL" | awk '{print $1}')"
sed "s/@SHA256@/$SHA/" "$ROOT/packaging/arch/PKGBUILD.in" > "$BUILD_DIR/PKGBUILD"
(
  cd "$BUILD_DIR"
  makepkg -f --cleanbuild
)
echo "Arch package build completed in: $BUILD_DIR"
