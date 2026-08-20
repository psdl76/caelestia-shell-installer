#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WEB="$ROOT_DIR/native-drawer-poc/WebAppsContent.qml"

python3 -S - "$WEB" <<'PY'
import sys
from pathlib import Path
s=Path(sys.argv[1]).read_text()
start=s.index("function iconSource(app)")
end=s.index("function primaryAction(app)", start)
block=s[start:end]
store=block.index('(app.iconStore ?? "")')
installed=block.index('(app.icon ?? "")')
local=block.index('(app.iconLocal ?? "")')
assert store < installed < local, "icon fallback order is wrong"
PY

grep -Fq 'Quickshell.execDetached([app.launcher])' "$WEB"
grep -Fq '[root.actionHelper, action, app.id]' "$WEB"

echo "PASS: v5.1 keeps UI icon stable across installation state"
