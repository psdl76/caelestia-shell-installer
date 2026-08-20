#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
API="$ROOT/bin/caelestia-webapps"

python3 - "$API" <<'PY'
from pathlib import Path
import sys
s = Path(sys.argv[1]).read_text()
assert 'hl.dsp.window.close({{ window = "{selector}" }})' in s
assert 'time.monotonic() + timeout_seconds' in s
assert 'time.sleep(0.15)' in s
assert '"window_close_timeout"' in s
assert 'delegate_action(command, [str(UNINSTALL_SCRIPT), app_id], app_id)' in s
PY

echo "PASS: uninstall-close waits for graceful window exit before delegating uninstall"
