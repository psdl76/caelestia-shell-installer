#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT_DIR/manager/shell.qml"
fail(){ echo "FAIL: $*" >&2; exit 1; }

grep -Fq 'actionProcess.command = [projectRoot + "/install.sh", app.id]' "$QML" || fail "GUI install bypasses backend"
grep -Fq 'actionProcess.command = [projectRoot + "/uninstall.sh", app.id]' "$QML" || fail "GUI uninstall bypasses backend"
grep -Fq 'actionProcess.command = [projectRoot + "/repair.sh", "--app", app.id]' "$QML" || fail "GUI repair bypasses backend"
grep -Fq 'Quickshell.execDetached([app.launcher])' "$QML" || fail "GUI open bypasses installed launcher"
grep -Fq 'id: uninstallOverlay' "$QML" || fail "uninstall confirmation overlay missing"
grep -Fq 'refreshProcess.running = true' "$QML" || fail "catalog refresh after mutation missing"
grep -Fq 'onFileChanged: reload()' "$QML" || fail "catalog file watching missing"
grep -Fq 'Installiere…' "$QML" || fail "install busy feedback missing"
grep -Fq 'Entferne…' "$QML" || fail "uninstall busy feedback missing"
grep -Fq 'Behavior on scale' "$QML" || fail "Caelestia-style card interaction missing"

echo "PASS: manager store actions use tested backend, confirmation, live refresh and fluid card feedback"

! grep -Fq 'id: uninstallDialog' "$QML" || fail "legacy Qt Dialog remains in manager"
grep -Fq 'root.pendingAction === "uninstall"' "$QML" || fail "uninstall overlay is not state-driven"
grep -Fq 'root.runAction(app, "uninstall")' "$QML" || fail "confirmation does not invoke backend uninstall"
