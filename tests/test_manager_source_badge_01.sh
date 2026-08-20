#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/manager/shell.qml"

grep -Fq 'root.actionMenuApp.source === "user" ? "Eigene App" : "Katalog-App"' "$QML"
grep -Fq 'label: "Quelle"' "$QML"
! grep -Fq 'text: modelData.source === "user" ? "\ue7fd" : "\ue865"' "$QML"

echo "PASS: ownership origin is shown on WebApp info rather than cluttering catalog rows"
