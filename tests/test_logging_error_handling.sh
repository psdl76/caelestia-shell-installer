#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
COMMON="$ROOT/lib/common.sh"
REPAIR="$ROOT/repair.sh"
INSTALL="$ROOT/install.sh"

grep -Fq '_redact_command()' "$COMMON"
grep -Fq 'Wiederherst.:' "$COMMON"
grep -Fq 'Backups   :' "$COMMON"
grep -Fq 'source "$LIB_DIR/common.sh"' "$REPAIR"
grep -Fq 'trap on_error ERR' "$REPAIR"
grep -Fq 'error_context "$HYPR_RULES_FILE"' "$INSTALL"

out="$(bash -c 'source "$1"; _redact_command "curl -H Authorization=secret token=abc password=hunter2 Bearer xyz.123"' _ "$COMMON")"
[[ "$out" != *secret* ]]
[[ "$out" != *abc* ]]
[[ "$out" != *hunter2* ]]
[[ "$out" != *xyz.123* ]]
[[ "$out" == *'<redacted>'* ]]

echo 'PASS: logging, recovery context and credential redaction are centralized'
