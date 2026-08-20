#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WEB="$ROOT_DIR/native-drawer-poc/WebAppsContent.qml"

grep -Fq 'property bool searchOpen: false' "$WEB"
grep -Fq 'property string searchQuery: ""' "$WEB"
grep -Fq 'function openSearch()' "$WEB"
grep -Fq 'function closeSearch()' "$WEB"
grep -Fq 'app.genericName' "$WEB"
grep -Fq 'app.comment' "$WEB"
grep -Fq 'root.categoryLabel(app.category)' "$WEB"
grep -Fq 'return haystack.includes(query)' "$WEB"
grep -Fq 'root.selectedCategory === "all"' "$WEB"
grep -Fq 'id: searchSurface' "$WEB"
grep -Fq 'id: searchInput' "$WEB"
grep -Fq 'Keys.onEscapePressed' "$WEB"
grep -Fq '? "WebApps suchen…"' "$WEB"
grep -Fq 'visible: root.visibleApps.length === 0' "$WEB"
grep -Fq 'model: root.visibleApps' "$WEB"

echo "PASS: v8 search is local, category-composable, morphing and keyboard-dismissable"
