#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
THEME="$ROOT/manager/style/Theme.qml"
QML="$ROOT/manager/shell.qml"

grep -Fq 'readonly property color primaryContent: colour("onPrimary", "#102028")' "$THEME"
grep -Fq 'Style.Theme.primaryContent' "$QML"
! grep -Fq 'Style.Theme.onPrimary' "$QML"
! grep -Eq 'readonly property [A-Za-z]+ on[A-Z][A-Za-z0-9_]*:' "$THEME"

echo "PASS: Theme avoids QML onXxx signal-handler naming collisions"
