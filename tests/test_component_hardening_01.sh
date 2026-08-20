#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STYLE="$ROOT/manager/style"
QML="$ROOT/manager/shell.qml"

grep -Fq 'activeFocusOnTab: root.interactive' "$STYLE/ActionButton.qml"
grep -Fq 'Keys.onReturnPressed' "$STYLE/ActionButton.qml"
grep -Fq 'activeFocusOnTab: root.interactive' "$STYLE/IconButton.qml"
grep -Fq 'Keys.onSpacePressed' "$STYLE/IconButton.qml"
grep -Fq 'function forceSearchFocus()' "$STYLE/SearchField.qml"
grep -Fq 'sequence: "Ctrl+F"' "$QML"
grep -Fq 'id: managerSearch' "$QML"
grep -Fq 'ToolTip.visible: appNameHover.hovered && appNameText.truncated' "$QML"
grep -Fq 'Keine passenden WebApps' "$QML"
grep -Fq 'activeFocusOnTab: true' "$QML"
grep -Fq 'focusRingWidth' "$STYLE/Tokens.qml"

echo "PASS: keyboard focus, search shortcut, long-name tooltip and empty state are hardened"
