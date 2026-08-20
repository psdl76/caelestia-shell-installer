#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/manager/shell.qml"

grep -Fq 'root.actionMenuApp.source === "user" ? Style.I18n.choose("Eigene App", "Custom app") : Style.I18n.choose("Katalog-App", "Catalog app")' "$QML"
grep -Fq 'label: Style.I18n.choose("Quelle", "Source")' "$QML"
! grep -Fq 'text: modelData.source === "user" ? "\ue7fd" : "\ue865"' "$QML"

echo "PASS: ownership origin is shown on WebApp info rather than cluttering catalog rows"
