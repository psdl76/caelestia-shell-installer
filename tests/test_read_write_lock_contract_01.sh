#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
grep -Fq 'acquire_read_lock "catalog-list"' "$ROOT/catalog.sh"
grep -Fq 'acquire_read_lock "catalog-json"' "$ROOT/catalog.sh"
grep -Fq 'acquire_mutation_lock "install:$APP_ID"' "$ROOT/install.sh"
grep -Fq 'acquire_mutation_lock "uninstall:$APP_ID"' "$ROOT/uninstall.sh"
grep -Fq 'acquire_mutation_lock "repair${ONLY_APP:+:$ONLY_APP}"' "$ROOT/repair.sh"
grep -Fq 'with engine_lock("catalog", exclusive=False)' "$ROOT/bin/caelestia-webapps"
echo "PASS: reads are shared and all mutations are exclusive"
