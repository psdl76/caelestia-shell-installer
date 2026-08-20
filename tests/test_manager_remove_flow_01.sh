#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
QML="$ROOT/manager/shell.qml"

grep -Fq 'property bool removeFromCatalogAfterUninstall: false' "$QML"
grep -Fq 'property bool chainedCatalogRemoval: false' "$QML"
grep -Fq 'id: removeCatalogSwitch' "$QML"
grep -Fq 'text: "Aus dem Katalog entfernen"' "$QML"
grep -Fq 'root.removeFromCatalogAfterUninstall = !root.removeFromCatalogAfterUninstall' "$QML"
grep -Fq 'root.chainedCatalogRemoval = app.source === "user"' "$QML"
grep -Fq 'root.actionCommand = "user-delete"' "$QML"
grep -Fq '? "Aus Katalog entfernen"' "$QML"

! grep -Fq 'pendingCatalogRemovalApp' "$QML"
! grep -Fq 'requestCatalogRemoval' "$QML"
! grep -Fq 'text: "Aus Katalog";' "$QML"

echo "PASS: unified trash dialog uses optional catalog-removal switch for installed User Apps"
