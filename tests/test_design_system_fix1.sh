#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/manager/shell.qml"
TOKENS="$ROOT/manager/style/Tokens.qml"

grep -Fq 'readonly property real radiusStatusDot: 4.5' "$TOKENS"
grep -Fq 'radius: Style.Tokens.radiusStatusDot' "$QML"

! grep -Eq 'Style\.Tokens\.[A-Za-z0-9_]+\.[0-9]+' "$QML"
! grep -Eq 'Style\.(Theme|Tokens)\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+' "$QML"

echo "PASS: decimal radius is represented by a valid design token"
