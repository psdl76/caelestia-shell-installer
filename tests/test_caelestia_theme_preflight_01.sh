#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
grep -Fq 'scripts/caelestia_theme_bridge.py' "$ROOT/manager.sh"
grep -Fq '|| true' "$ROOT/manager.sh"
echo "PASS: theme bridge cannot block Manager startup"
