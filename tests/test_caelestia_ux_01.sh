#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
STYLE="$ROOT/manager/style"; QML="$ROOT/manager/shell.qml"
for f in ActionButton.qml IconButton.qml SearchField.qml; do test -f "$STYLE/$f"; done
grep -Fq 'ActionButton 1.0 ActionButton.qml' "$STYLE/qmldir"
grep -Fq 'IconButton 1.0 IconButton.qml' "$STYLE/qmldir"
grep -Fq 'SearchField 1.0 SearchField.qml' "$STYLE/qmldir"
grep -Fq 'readonly property real pressedScale: 0.96' "$STYLE/Tokens.qml"
grep -Fq 'Style.SearchField {' "$QML"
grep -Fq 'title: Style.I18n.choose("WebApp-Info", "WebApp info")' "$QML"
grep -Fq 'onClicked: root.openActionMenu(modelData)' "$QML"
! grep -Fq 'ToolTip' "$QML"
! grep -Fq 'tooltip:' "$QML"
grep -Fq 'Applet-Einstellungen' "$QML"
grep -Fq 'WebApp reparieren' "$QML"
grep -Fq 'Eigene WebApp bearbeiten' "$QML"
grep -Fq 'StateLayer 1.0 StateLayer.qml' "$STYLE/qmldir"
grep -Fq 'StateLayer {' "$STYLE/ActionButton.qml"
grep -Fq 'StateLayer {' "$STYLE/IconButton.qml"
! grep -REq 'import qs\.|import Caelestia(\.|$)' "$STYLE" "$QML"
python3 - "$QML" <<'PY2'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text(); start=s.index('delegate: Rectangle {',s.index('model: root.visibleApps()')); end=s.index('RowLayout {',start); assert 'Behavior on color' not in s[start:end]
PY2
echo 'PASS: Caelestia UX primitives wired without private shell imports'
