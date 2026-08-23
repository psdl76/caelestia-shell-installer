#!/usr/bin/env python3
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
qml = (ROOT / "manager" / "shell.qml").read_text(encoding="utf-8")

required = [
    "property var availableCategories",
    '"__category_create__"',
    '"__category_manage__"',
    'root.openCategoryCreate("wizard")',
    'id: categoryManagePage',
    'id: categoryEditorPage',
    'id: categoryNameField',
    'root.categoryIconChoices()',
    '"user-category-create"',
    '"user-category-update"',
    '"user-category-delete"',
    'root.wizardCategory = created.id',
    'root.categoryDeleteConfirm = true',
    'root.displayedMainPage === "category-editor"',
]
for needle in required:
    assert needle in qml, f"missing Manager category contract: {needle}"

assert "options: root.categoryOptions()" in qml
assert "onSelected: function(value) { root.selectWizardCategory(value) }" in qml
assert "import qs." not in qml
assert "import Caelestia." not in qml

print("PASS: Manager embedded user-category flow contract")
