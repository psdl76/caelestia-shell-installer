#!/usr/bin/env python3
"""Focused contracts for Manager keyboard focus and modal isolation."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SHELL = (ROOT / "manager/shell.qml").read_text(encoding="utf-8")
SELECT = (ROOT / "manager/style/SettingsSelect.qml").read_text(encoding="utf-8")
ACTION = (ROOT / "manager/style/SettingsAction.qml").read_text(encoding="utf-8")
LOGO = (ROOT / "manager/style/AnimatedBrandLogo.qml").read_text(encoding="utf-8")


# The destructive confirmation is a focus scope, blocks global search and all
# background page trees, traps forward/backward tab traversal, and restores the
# previously focused control after either exit path.
modal = SHELL[SHELL.index("id: uninstallOverlay") :]
assert "FocusScope {" in SHELL[SHELL.index("// Nexus StackPage equivalent") : SHELL.index("id: uninstallOverlay")]
assert 'enabled: root.pendingUninstallApp === null\n            onActivated: managerSearch.forceSearchFocus()' in SHELL
assert "enabled: root.pendingUninstallApp === null" in SHELL[SHELL.index("RowLayout {") : SHELL.index("id: catalogPage")]
assert "root.uninstallPreviousFocusItem = window.activeFocusItem" in SHELL
assert "root.restoreUninstallFocus()" in SHELL[SHELL.index("function cancelUninstall") : SHELL.index("Process {", SHELL.index("function cancelUninstall"))]
for control in ("uninstallCancelButton", "uninstallConfirmButton", "uninstallCatalogToggle"):
    assert f"id: {control}" in modal
assert "uninstallCancelButton.forceActiveFocus()" in modal
assert "KeyNavigation.tab: uninstallCancelButton" in modal
assert "KeyNavigation.backtab: uninstallConfirmButton" in modal

# Select popups expose a keyboard cursor, preserve the selected entry and return
# focus to the selector after choosing or dismissing an option.
for handler in (
    "Keys.onUpPressed",
    "Keys.onDownPressed",
    "Keys.onHomePressed",
    "Keys.onEndPressed",
    "Keys.onReturnPressed",
    "Keys.onEnterPressed",
    "Keys.onSpacePressed",
    "Keys.onEscapePressed",
):
    assert handler in SELECT
assert "optionList.currentIndex = root.valueIndex()" in SELECT
assert "id: menu\n        focus: true" in SELECT
assert "optionList.forceActiveFocus()" in SELECT
assert "onClosed: if (root.interactive) selectButton.forceActiveFocus()" in SELECT

# Wizard focus is delayed until the incoming page transition is complete.
create_wizard = SHELL[SHELL.index("function openCreateWizard") : SHELL.index("function openEditWizard")]
edit_wizard = SHELL[SHELL.index("function openEditWizard") : SHELL.index("function closeWizard")]
assert "wizardFocusTimer.restart()" not in create_wizard
assert "wizardFocusTimer.restart()" not in edit_wizard
page_switch = SHELL[SHELL.index("id: mainPageSwitch") : SHELL.index("id: uninstallOverlay")]
assert "onFinished:" in page_switch
assert 'root.displayedMainPage === "wizard"' in page_switch
assert "wizardFocusTimer.restart()" in page_switch

# Tabbing keeps sidebar, catalog and action controls visible.
assert "function ensureItemVisible(" in SHELL
for view in ("navigationScroll", "scroll", "actionScroll"):
    assert f"ensureItemVisible({view}," in SHELL
assert "signal keyboardFocusEntered(var item)" in ACTION
assert "root.keyboardFocusEntered(actionButton)" in ACTION

# A hidden About page cannot finish and overwrite its reset state.
inactive = LOGO[LOGO.index("else if (!active)") : LOGO.index("Component.onCompleted")]
assert inactive.index("intro.stop()") < inactive.index("resetLogo()")

print("PASS: Manager modal focus, keyboard selection, focus timing and auto-scroll regressions")
