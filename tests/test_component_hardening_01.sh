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
grep -Fq 'elide: Text.ElideRight' "$QML"
# Phase 17.5 deliberately moved ownership from crowded catalog rows into the
# selected WebApp's connected Details group.
grep -Fq 'root.actionMenuApp.source === "user" ? "Eigene App" : "Katalog-App"' "$QML"
grep -Fq 'label: "Quelle"' "$QML"
! grep -Fq 'ToolTip' "$QML"
grep -Fq 'Keine passenden WebApps' "$QML"
grep -Fq 'activeFocusOnTab: !root.actionBusy' "$QML"
grep -Fq 'Keys.onReturnPressed: root.openActionMenu(modelData)' "$QML"
grep -Fq 'Keys.onSpacePressed: root.openActionMenu(modelData)' "$QML"
grep -Fq 'border.width: activeFocus ? Style.Tokens.focusRingWidth : 0' "$QML"
grep -Fq 'focusRingWidth' "$STYLE/Tokens.qml"

echo "PASS: keyboard focus, search shortcut, WebApp-info ownership and empty state are hardened"
