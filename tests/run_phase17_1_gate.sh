#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_TMP="$(mktemp -d)"
trap 'rm -rf -- "$RUNTIME_TMP"' EXIT
export XDG_RUNTIME_DIR="$RUNTIME_TMP"

python3 "$ROOT/tests/test_phase17_1_manager_nexus_layout.py"
python3 "$ROOT/tests/test_phase16_1_fix2f_installed_filter.py"
bash "$ROOT/tests/test_phase16_1_fix1_catalog_review.sh"
bash "$ROOT/tests/test_caelestia_ux_01.sh"
python3 "$ROOT/tests/test_phase16_5_fix2_manager_startup_cli_bridge.py"
python3 "$ROOT/tests/test_phase16_6_capability_settings.py"
python3 "$ROOT/tests/test_phase16_6_fix1_manager_more_actions.py"

qmllint -I "$ROOT/manager" \
  "$ROOT/manager/style/ActionButton.qml" \
  "$ROOT/manager/style/IconButton.qml" \
  "$ROOT/manager/style/StateLayer.qml" \
  "$ROOT/manager/style/NavigationItem.qml" \
  "$ROOT/manager/style/SpatialAnimation.qml" \
  "$ROOT/manager/style/EffectAnimation.qml"

echo "PASS: Phase 17.1 Manager Nexus layout gate"
