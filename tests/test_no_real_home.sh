#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"

[[ "$TEST_ROOT" == /tmp/* || "$TEST_ROOT" == /var/tmp/* ]] || fail "TEST_ROOT ist kein temporäres Verzeichnis"

# $HOME/.config inside a test is intentional: every integration fixture first
# replaces HOME with a mktemp directory. Dangerous are literal real-home paths
# or destructive '~' operations.
for f in "$ROOT_DIR/tests"/test_*.sh; do
    if grep -Eq '/home/[A-Za-z0-9._-]+/\.config' "$f"; then
        fail "Literal realer Home-Pfad in $(basename "$f")"
    fi
    if grep -Eq 'rm[[:space:]]+-rf[[:space:]]+["'\'']?~(/|["'\'']|[[:space:]]|$)' "$f"; then
        fail "Unsicheres rm -rf auf ~ in $(basename "$f")"
    fi
done

pass "Keine Tests greifen über literale Pfade destruktiv auf reale Benutzerkonfigurationen zu"
