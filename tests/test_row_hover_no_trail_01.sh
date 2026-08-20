#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/manager/shell.qml"

# App delegate still uses hover semantics and radius motion.
grep -Fq 'color: rowHover.hovered ? Style.Theme.surfaceRaised : "transparent"' "$QML"
grep -Fq 'Behavior on radius { NumberAnimation { duration: Style.Tokens.motionEmphasized' "$QML"

# The outer row hover fill must NOT use ColorAnimation; otherwise neighbouring
# rows overlap visually while moving the pointer.
python3 - "$QML" <<'PY'
from pathlib import Path
import sys
s=Path(sys.argv[1]).read_text()
start=s.index('delegate: Rectangle {', s.index('model: root.visibleApps()'))
end=s.index('RowLayout {', start)
block=s[start:end]
assert 'Behavior on color' not in block
assert 'ColorAnimation' not in block
PY

echo "PASS: app-row hover has no fading trail between neighbouring delegates"
