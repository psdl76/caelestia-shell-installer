#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/testlib.sh"

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/bin/caelestia-webapps"

HOME="$TEST_ROOT/home"
export HOME
mkdir -p "$HOME"

json_field() {
    python3 -c 'import json,sys; d=json.load(sys.stdin); v=d'"$1"'; print(v if not isinstance(v,(dict,list)) else json.dumps(v,sort_keys=True))'
}

out="$($CLI list)"
assert_eq "$(printf '%s' "$out" | json_field '["apiVersion"]')" "1"
assert_eq "$(printf '%s' "$out" | json_field '["ok"]')" "True"
assert_eq "$(printf '%s' "$out" | json_field '["command"]')" "list"
assert_eq "$(printf '%s' "$out" | json_field '["data"]["schemaVersion"]')" "2"
count="$(printf '%s' "$out" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["data"]["apps"]))')"
assert_eq "$count" "79"

out="$($CLI status chatgpt)"
assert_eq "$(printf '%s' "$out" | json_field '["data"]["app"]["id"]')" "chatgpt"
assert_eq "$(printf '%s' "$out" | json_field '["data"]["runtime"]["installed"]')" "False"

set +e
out="$($CLI status definitely-not-an-app 2>/dev/null)"
rc=$?
set -e
assert_eq "$rc" "10"
assert_eq "$(printf '%s' "$out" | json_field '["error"]["code"]')" "unknown_app"

set +e
out="$($CLI launch chatgpt 2>/dev/null)"
rc=$?
set -e
assert_eq "$rc" "11"
assert_eq "$(printf '%s' "$out" | json_field '["error"]["code"]')" "not_installed"

out="$($CLI refresh)"
assert_eq "$(printf '%s' "$out" | json_field '["data"]["appCount"]')" "79"

pass "engine API returns versioned JSON and stable basic exit codes"
