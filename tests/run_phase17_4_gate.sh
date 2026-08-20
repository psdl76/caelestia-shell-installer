#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT/tests/run_phase17_3_gate.sh"
python3 "$ROOT/tests/test_phase17_4_subpage_consistency.py"
bash "$ROOT/tests/test_manager_wizard_01.sh"
bash "$ROOT/tests/test_manager_ux_polish_01.sh"
bash "$ROOT/tests/test_icon_fallback_fix2.sh"
python3 "$ROOT/tests/test_phase16_6_capability_settings.py"

qmllint -I "$ROOT/manager" \
  "$ROOT/manager/style/PageHeader.qml" \
  "$ROOT/manager/style/SettingsToggle.qml" \
  "$ROOT/manager/style/SettingsTextField.qml" \
  "$ROOT/manager/style/SettingsSelect.qml"

echo "PASS: Phase 17.4 Manager subpage consistency gate"
