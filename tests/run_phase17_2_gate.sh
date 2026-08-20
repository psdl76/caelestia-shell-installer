#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT/tests/run_phase17_1_gate.sh"
python3 "$ROOT/tests/test_phase17_2_manager_embedded_pages.py"

echo "PASS: Phase 17.2 embedded Manager pages gate"
