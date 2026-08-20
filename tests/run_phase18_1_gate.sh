#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT/tests/run_phase17_7_closing_gate.sh"
python3 "$ROOT/tests/test_phase18_1_manager_localization.py"
bash "$ROOT/tests/test_shell_syntax.sh"
qmllint -I "$ROOT/manager" \
  "$ROOT/manager/style/I18n.qml" \
  "$ROOT/manager/style/SearchField.qml"

echo "PASS: Phase 18.1 German/English Manager localization gate"
