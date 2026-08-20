#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/manager/shell.qml"
ICON="$ROOT/manager/style/IconButton.qml"

grep -Fq 'import QtQuick.Dialogs' "$QML"
grep -Fq 'id: iconFileDialog' "$QML"
grep -Fq '{ id: "auto", label: "Automatisch" }' "$QML"
grep -Fq '{ id: "url", label: "URL" }' "$QML"
grep -Fq '{ id: "local", label: "Lokale Datei" }' "$QML"
grep -Fq 'function wizardIconPreview()' "$QML"

# Catalog removal now shares the unified destructive modal and visible action row.
grep -Fq 'title: app.installed === true ? "WebApp deinstallieren" : "Aus dem Katalog entfernen"' "$QML"
grep -Fq '? root.pendingUninstallApp.name + " aus dem Katalog entfernen?"' "$QML"
grep -Fq 'root.runAction("user-delete", app)' "$QML"
grep -Fq 'visible: !modelData.installed && modelData.source === "user"' "$QML"
grep -Fq '? "\ue5cd" : "\ue872"' "$QML"
grep -Fq 'font.family: "Material Symbols Rounded"' "$ICON"

echo 'PASS: manager icon selection and unified catalog-removal UI'
