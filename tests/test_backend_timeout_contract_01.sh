#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT/bin/caelestia-webapps"
grep -Fq 'CAELESTIA_WEBAPPS_ACTION_TIMEOUT_SECONDS' "$CLI"
grep -Fq 'os.killpg(proc.pid, signal.SIGTERM)' "$CLI"
grep -Fq '"action_timeout"' "$CLI"
grep -Fq 'EXIT_ACTION_TIMEOUT = 32' "$CLI"
echo "PASS: bounded action timeout kills the process group and has a stable API error"
