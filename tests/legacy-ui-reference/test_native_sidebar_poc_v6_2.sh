#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WEB="$ROOT_DIR/native-drawer-poc/WebAppsContent.qml"

grep -Fq 'text: "\ue872"' "$WEB"
grep -Fq 'font.family: "Material Symbols Rounded"' "$WEB"
! grep -Fq 'text: "delete"' "$WEB"
grep -Fq 'root.contentPage = 1' "$WEB"
grep -Fq 'id: actionTrack' "$WEB"

echo "PASS: v6.2 uses an explicit Material trash glyph in the native confirmation page"
