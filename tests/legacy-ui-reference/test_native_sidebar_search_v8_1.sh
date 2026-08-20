#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WEB="$ROOT_DIR/native-drawer-poc/WebAppsContent.qml"
grep -Fq 'id: allAnchor' "$WEB"
grep -Fq 'id: categoriesMorph' "$WEB"
grep -Fq 'opacity: root.searchOpen ? 0 : 1' "$WEB"
grep -Fq 'scale: root.searchOpen ? 0.96 : 1' "$WEB"
grep -Fq 'filterBar.width - allAnchor.width - filterBar.spacing' "$WEB"
grep -Fq 'model: root.categories' "$WEB"
! grep -Fq 'model: [{ id: "all", label: "Alle" }].concat(root.categories)' "$WEB"
grep -Fq 'root.categoryLabel(root.selectedCategory) + " durchsuchen…"' "$WEB"
echo "PASS: v8.1 morphs category strip away before search expands"
