# Native Sidebar PoC v5.1 — Stable icons

Live testing confirmed:
- native install works;
- installed launchers preserve activate-or-launch and prevent duplicate windows.

Gemini exposed a UI-only icon regression. Before installation the card used `iconStore`
(the cached PNG fallback); after installation it switched to the installed SVG via
`app.icon`, which Qt/Quickshell did not render reliably.

v5.1 always prefers `iconStore` for sidebar presentation, then falls back to installed
and local icons. The icon therefore remains visually stable before and after install.
No install/open backend behavior changed.
