#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PHASE_DIR = ROOT / "docs/phases/phase-17"
SHELL = (ROOT / "manager/shell.qml").read_text(encoding="utf-8")
AGENTS = (ROOT / "AGENTS.md").read_text(encoding="utf-8")
CLOSING = PHASE_DIR / "PHASE17_7_VISUAL_ACCEPTANCE_CLOSING_GATE.md"

for number in range(1, 8):
    matches = sorted(PHASE_DIR.glob(f"PHASE17_{number}_*.md"))
    assert len(matches) == 1, (number, matches)
    assert "Status: **ACCEPTED / FROZEN**" in matches[0].read_text(encoding="utf-8")

for number in range(1, 8):
    assert f"Phase 17.{number}" in AGENTS
assert "Phase 17.7 — Manager visual acceptance and closing gate: ACCEPTED / FROZEN" in AGENTS
assert "Release 0.4.1 — localized package release: PUBLIC / LIVE ACCEPTED" in AGENTS
assert "Release 0.4.2 — branded package release: PUBLIC / LIVE ACCEPTED" in AGENTS

# Closing regression found during the full packaging gate.
assert "activeFocusOnTab: !root.actionBusy" in SHELL
assert "Keys.onReturnPressed: root.openActionMenu(modelData)" in SHELL
assert "Keys.onSpacePressed: root.openActionMenu(modelData)" in SHELL
assert "border.width: activeFocus ? Style.Tokens.focusRingWidth : 0" in SHELL

closing = CLOSING.read_text(encoding="utf-8")
for checkpoint in ("`1A`", "`1B`", "`1C`", "keyboard regression check"):
    assert checkpoint in closing
assert "Phase 16.8 end-to-end gate (22 tests)" in closing
assert "Phase 13 packaging/product gate (17 tests)" in closing

print("PASS: Phase17.7 acceptance evidence, frozen status and keyboard contract")
