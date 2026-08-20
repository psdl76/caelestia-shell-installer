#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/manager/shell.qml"
THEME="$ROOT/manager/style/Theme.qml"
TOKENS="$ROOT/manager/style/Tokens.qml"
QMLDIR="$ROOT/manager/style/qmldir"

grep -Fq 'import "style" as Style' "$QML"
grep -Fq 'singleton Theme 1.0 Theme.qml' "$QMLDIR"
grep -Fq 'singleton Tokens 1.0 Tokens.qml' "$QMLDIR"
grep -Fq 'readonly property color primary:' "$THEME"
grep -Fq 'readonly property color textPrimary:' "$THEME"
grep -Fq 'readonly property int radiusControl:' "$TOKENS"
grep -Fq 'readonly property int motionStandard:' "$TOKENS"
grep -Fq 'Style.Theme.primary' "$QML"
grep -Fq 'Style.Theme.textPrimary' "$QML"
grep -Fq 'Style.Tokens.radiusControl' "$QML"
grep -Fq 'Style.Tokens.fontBodySmall' "$QML"
grep -Fq 'Style.Tokens.motionFast' "$QML"

# No raw hex colors remain in the manager implementation; palette owns them.
if grep -Eq '"#[0-9A-Fa-f]{6,8}"' "$QML"; then
    echo "raw color literal remains in shell.qml" >&2
    exit 1
fi

echo "PASS: manager styling is centralized in stable Theme/Tokens singletons"
