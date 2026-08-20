#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT/scripts/generate_catalog.py" "$ROOT/manager/shell.qml" <<'PY'
from pathlib import Path
import sys

gen = Path(sys.argv[1]).read_text()
qml = Path(sys.argv[2]).read_text()

assert 'else:\n            store_icon = ""' in gen
assert 'property string wizardAutoIconId: ""' in qml
assert 'root.wizardAutoIconId.trim()' in qml
assert 'onEditingFinished: root.wizardAutoIconId = root.wizardId.trim()' in qml

# The old bad fallback must be gone.
assert 'str(store_svg if store_svg.is_file() else store_png)' not in gen
PY

echo "PASS: missing cache icons fall through to iconUrl and auto preview waits for committed App-ID"
