#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/manager/shell.qml"

grep -Fq 'text: modelData.source === "user" ? "\ue7fd" : "\ue865"' "$QML"
grep -Fq 'font.family: "Material Symbols Rounded"' "$QML"
grep -Fq '? "Eigene App"' "$QML"
grep -Fq ': "Katalog-App"' "$QML"
! grep -Fq 'text: "Eigene App"' "$QML"

echo "PASS: ownership origin uses compact user/book icons with tooltips"
