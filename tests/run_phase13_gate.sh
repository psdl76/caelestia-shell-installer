#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="/usr/bin:/bin"
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS=(
  test_packaging_manifest_01.sh
  test_packaging_rootless_install_01.sh
  test_packaging_installed_e2e_01.sh
  test_packaging_upgrade_preserves_user_data_01.sh
  test_packaging_uninstall_preserves_user_data_01.sh
  test_arch_pkgbuild_contract_01.sh
  test_runtime_tarball_01.sh
  test_e2e_product_01.sh
  test_plugin_independence_gate_01.sh
  test_backend_locking_01.sh
  test_backend_read_isolation_01.sh
  test_backend_timeout_contract_01.sh
  test_ownership_01.sh
  test_user_apps_01.sh
  test_component_hardening_01.sh
  test_phase16_4_lifecycle_registry_coupling.sh
  test_phase16_4_metadata_pair_failure_preserves_live.sh
)
count=0
for name in "${TESTS[@]}"; do
  echo "==> $name"
  bash "$ROOT/tests/$name"
  ((count+=1))
done
echo
echo "PASS: Phase 13 packaging gate ($count tests)"
