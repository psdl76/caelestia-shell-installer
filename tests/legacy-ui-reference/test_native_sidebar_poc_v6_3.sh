#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WEB="$ROOT_DIR/native-drawer-poc/WebAppsContent.qml"
grep -Fq 'cardMouse.containsMouse || expanded' "$WEB"
grep -Fq ': "transparent"' "$WEB"
grep -Fq 'cardMouse.containsMouse || card.expanded' "$WEB"
grep -Fq 'root.runBackend(card.modelData, "repair")' "$WEB"
grep -Fq 'root.contentPage = 1' "$WEB"
grep -Fq 'text: "\ue872"' "$WEB"
echo "PASS: v6.3 borderless resting rows preserve native interaction surfaces"
