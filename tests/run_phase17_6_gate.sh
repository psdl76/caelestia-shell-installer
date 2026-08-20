#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT/tests/run_phase17_5_gate.sh"
python3 "$ROOT/tests/test_phase17_6_about_page.py"

qmllint -I "$ROOT/manager" "$ROOT/manager/style/PageHeader.qml"

echo "PASS: Phase 17.6 About page gate"
