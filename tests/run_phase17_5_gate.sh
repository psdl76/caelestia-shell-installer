#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT/tests/run_phase17_4_gate.sh"
python3 "$ROOT/tests/test_phase17_5_webapp_info_navigation.py"
bash "$ROOT/tests/test_manager_actions_01.sh"
bash "$ROOT/tests/test_manager_source_badge_01.sh"

qmllint -I "$ROOT/manager" "$ROOT/manager/style/SettingsInfoRow.qml"

echo "PASS: Phase 17.5 WebApp info navigation gate"
