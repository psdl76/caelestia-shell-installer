#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/testlib.sh"

mapfile -t files < <(find "$ROOT_DIR" -type f \( -name '*.sh' -o -path "$ROOT_DIR/.git/*" \) -prune -o -type f -name '*.sh' -print)
for f in "${files[@]}"; do
    bash -n "$f" || fail "Shell-Syntax ungültig: $f"
done
pass "Shell-Syntax aller .sh-Dateien"
