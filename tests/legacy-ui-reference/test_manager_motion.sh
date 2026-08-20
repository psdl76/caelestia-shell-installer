#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT_DIR/manager/shell.qml"
fail(){ echo "FAIL: $*" >&2; exit 1; }
grep -Fq 'property bool storeEntered' "$QML" || fail "entrance state missing"
grep -Fq 'Behavior on radius' "$QML" || fail "shape morphing missing"
grep -Fq 'Easing.OutBack' "$QML" || fail "expressive spatial easing missing"
grep -Fq 'id: toastTimer' "$QML" || fail "toast lifecycle missing"
grep -Fq 'property bool active: root.pendingAction === "uninstall"' "$QML" || fail "animated modal state missing"
grep -Fq 'actionProcess.command = [projectRoot + "/install.sh", app.id]' "$QML" || fail "backend install contract changed"
grep -Fq 'actionProcess.command = [projectRoot + "/uninstall.sh", app.id]' "$QML" || fail "backend uninstall contract changed"
echo "PASS: Caelestia-inspired expressive motion added without changing backend action contracts"

python3 - "$QML" <<'PY'
import sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
needle = 'anchors.centerIn: parent\n                    width: 430\n                    height: 214'
i = text.find(needle)
assert i >= 0, "uninstall modal card not found"
block = text[i:i+900]
assert block.count('radius:') == 1, "uninstall modal card sets radius more than once"
PY

grep -Fq 'id: statusToast' "$QML" || fail "floating status toast missing"
grep -Fq 'anchors.bottom: parent.bottom' "$QML" || fail "toast is not contained by manager window"
grep -Fq 'z: 90' "$QML" || fail "toast overlay stacking missing"
python3 - "$QML" <<'PY'
import sys
from pathlib import Path
s=Path(sys.argv[1]).read_text()
toast=s[s.index("id: statusToast"):s.index("// Caelestia-style in-window modal.")]
assert "Layout.fillWidth" not in toast, "toast must not participate in ColumnLayout"
assert "radius: hover.hovered ? 36 : 24" in s, "card morph is not expressive enough"
assert "width: hover.hovered ? 66 : 58" in s, "icon-tile morph missing"
PY
