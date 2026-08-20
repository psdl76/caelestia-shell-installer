#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/testlib.sh"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
CLI="$ROOT_DIR/bin/caelestia-webapps"

# Static architectural contract: the facade delegates mutation to the tested
# engine entry points and does not contain install/uninstall implementation.
assert_contains "$CLI" 'INSTALL_SCRIPT = ROOT / "install.sh"'
assert_contains "$CLI" 'REPAIR_SCRIPT = ROOT / "repair.sh"'
assert_contains "$CLI" 'UNINSTALL_SCRIPT = ROOT / "uninstall.sh"'
assert_contains "$CLI" 'delegate_action(command, [str(INSTALL_SCRIPT), app_id], app_id)'
assert_contains "$CLI" 'delegate_action(command, [str(REPAIR_SCRIPT), "--app", app_id, "--quiet"], app_id)'
assert_contains "$CLI" 'delegate_action(command, [str(UNINSTALL_SCRIPT), app_id], app_id)'
assert_contains "$CLI" 'subprocess.Popen('
assert_not_contains "$CLI" 'MOZ_APP_REMOTINGNAME='
assert_not_contains "$CLI" 'hyprctl dispatch'
assert_not_contains "$CLI" 'userChrome.css'
assert_not_contains "$CLI" 'desktop.desktop.tpl'
pass "engine API delegates business logic instead of duplicating it"
