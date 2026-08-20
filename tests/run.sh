#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$ROOT_DIR/tests"

pass=0
fail=0

run_test() {
    local test_file="$1"
    printf '\n==> %s\n' "$(basename "$test_file")"
    if bash "$test_file"; then
        ((pass+=1))
    else
        ((fail+=1))
    fi
}

mapfile -t test_files < <(find "$TEST_DIR" -maxdepth 1 -type f -name 'test_*.sh' -print | sort)

if ((${#test_files[@]} == 0)); then
    echo "Keine Tests gefunden." >&2
    exit 1
fi

for test_file in "${test_files[@]}"; do
    run_test "$test_file"
done

printf '\nTests: %d bestanden, %d fehlgeschlagen\n' "$pass" "$fail"
(( fail == 0 ))
