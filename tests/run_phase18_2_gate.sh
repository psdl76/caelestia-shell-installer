#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT/tests/run_phase18_1_gate.sh"
bash "$ROOT/tests/test_phase18_2_reload_free_hyprland.sh"
bash "$ROOT/tests/test_shell_syntax.sh"

echo "PASS: Phase 18.2 reload-free Hyprland Lua integration gate"
