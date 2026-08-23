#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT/tests/run_phase17_6_gate.sh"
bash "$ROOT/tests/run_phase16_8_gate.sh"
bash "$ROOT/tests/test_shell_syntax.sh"
bash "$ROOT/tests/run_phase13_gate.sh"
python3 "$ROOT/tests/test_phase17_7_closing_gate.py"
python3 "$ROOT/tests/test_manager_keyboard_focus_regressions.py"
python3 "$ROOT/tests/test_manager_orphan_recovery.py"
python3 "$ROOT/tests/test_manager_user_categories.py"

echo "PASS: Phase 17.7 Manager visual acceptance and closing gate"
