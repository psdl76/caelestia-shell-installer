#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

python3 "$ROOT/tests/test_user_categories.py"
python3 "$ROOT/tests/test_user_category_rollback.py"
RUNTIME_TMP="$(mktemp -d)"
trap 'rm -rf -- "$RUNTIME_TMP"' EXIT
export XDG_RUNTIME_DIR="$RUNTIME_TMP"

TESTS=(
  test_phase16_2_contract2.py
  test_phase16_2_contract3.py
  test_phase16_2_schema_contract.py
  test_phase16_3_registry1.py
  test_phase16_3_registry2.py
  test_phase16_3_registry3.py
  test_phase16_3_registry3_fix1_plugin_bridge.py
  test_phase16_3_registry3_fix2.py
  test_phase16_3_registry3_fix3.py
  test_phase16_4_fix1_polling_race.py
  test_phase16_4_lifecycle_registry_coupling.sh
  test_phase16_4_metadata_pair_failure_preserves_live.sh
  test_phase16_5_applet_activation.py
  test_phase16_5_fix2_manager_startup_cli_bridge.py
  test_phase16_6_capability_settings.py
  test_phase16_6_fix1_manager_more_actions.py
  test_phase16_7_repair_upgrade_migration.py
  test_phase16_8_uninstall_applet_reset.sh
  test_phase16_8_installed_upgrade_migration.sh
  test_phase16_8_metadata_pair_commit_rollback.sh
  test_phase16_8_uninstall_hyprland_toctou.sh
  test_phase16_8_xdg_state_home.sh
  test_orphan_installation_recovery_01.sh
  test_packaging_installed_e2e_01.sh
  test_packaging_upgrade_preserves_user_data_01.sh
  test_packaging_uninstall_preserves_user_data_01.sh
)

count=0
for name in "${TESTS[@]}"; do
  echo "==> $name"
  case "$name" in
    *.py) python3 "$ROOT/tests/$name" ;;
    *)    bash "$ROOT/tests/$name" ;;
  esac
  ((count+=1))
done

echo
echo "PASS: Phase 16.8 end-to-end gate ($count tests)"
