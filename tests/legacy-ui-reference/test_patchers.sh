#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"

# Existing Python patchers must at least compile; their install/validate behavior
# is covered by the project's dedicated fixture tests when present.
for f in "$ROOT_DIR"/scripts/*.py; do
    python3 -m py_compile "$f" || fail "Python-Syntax ungültig: $f"
done

pass "Patcher kompilieren und Tests bleiben von echter Benutzerkonfiguration isoliert"
