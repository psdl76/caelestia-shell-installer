#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT/tests/run_phase17_2_gate.sh"
python3 "$ROOT/tests/test_phase17_3_nexus_motion_grouping.py"

qmllint -I "$ROOT/manager" \
  "$ROOT/manager/style/SectionHeader.qml"

echo "PASS: Phase 17.3 Nexus motion and grouping gate"
