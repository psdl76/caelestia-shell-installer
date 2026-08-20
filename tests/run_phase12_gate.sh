#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

TESTS=(
  test_e2e_product_01.sh
  test_plugin_independence_gate_01.sh
  test_backend_locking_01.sh
  test_backend_lock_inheritance_01.sh
  test_backend_read_isolation_01.sh
  test_read_write_lock_contract_01.sh
  test_direct_script_lock_01.sh
  test_backend_timeout_contract_01.sh
  test_engine_api_contract.sh
  test_engine_api_delegation.sh
  test_engine_api_launch_contract.sh
  test_engine_api_runtime_contract.sh
  test_catalog_v2_contract.sh
  test_catalog_v2_validator.sh
  test_catalog_v2_recovery.sh
  test_ownership_01.sh
  test_user_apps_01.sh
  test_uninstall_close_contract.sh
  test_manager_remove_flow_01.sh
  test_caelestia_theme_bridge_01.sh
  test_caelestia_theme_qml_01.sh
  test_caelestia_ux_01.sh
  test_component_hardening_01.sh
  test_manager_wizard_01.sh
)

count=0
for name in "${TESTS[@]}"; do
  path="$ROOT/tests/$name"
  if [[ ! -f "$path" ]]; then
    echo "FAIL: required Phase 12 gate test missing: $name" >&2
    exit 1
  fi
  echo "==> $name"
  bash "$path"
  ((count+=1))
done

echo
echo "PASS: Phase 12 release gate ($count tests)"
