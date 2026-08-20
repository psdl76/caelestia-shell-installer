#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash "$ROOT/tests/test_aur_package_01.sh"
python3 "$ROOT/tests/test_phase19_publication_docs.py"
python3 "$ROOT/tests/test_release_0_4_2.py"
python3 "$ROOT/tests/test_branding_assets.py"
python3 "$ROOT/tests/test_phase20_1_product_branding.py"
bash "$ROOT/tests/test_packaging_manifest_01.sh"
bash "$ROOT/tests/test_arch_pkgbuild_contract_01.sh"
bash "$ROOT/tests/test_shell_syntax.sh"

echo "PASS: Phase 19 AUR publication candidate gate"
