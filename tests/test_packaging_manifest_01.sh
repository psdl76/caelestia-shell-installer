#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/packaging/runtime-entries.txt"
test -f "$MANIFEST"
for required in VERSION apps bin config data lib manager scripts templates install.sh uninstall.sh manager.sh; do
  grep -Fqx "$required" "$MANIFEST"
done
! grep -Eq '^(tests|NATIVE_|PHASE|WEBAPPS_|README)' "$MANIFEST"
! grep -Eq '(^/|\.\.)' "$MANIFEST"
echo "PASS: runtime manifest contains only package runtime entries"
