# Phase 16.1-fix1 — Catalog UI review

Changes from first live review:

- Category strip is a horizontal `Flickable` with wheel/touchpad support.
- `Featured` is a real manager filter and the default view.
- Built-in catalog icons prefer cached/installed assets, then their real remote icon URL, and use the generic local icon only as the final fallback.
- All 79 built-in apps now have short functional descriptions instead of “... im Firefox App-Modus”.
- Catalog schema supports multiple category memberships while keeping `category` as the primary/backward-compatible category.
- Microsoft Teams is listed in both `Messaging` and `Microsoft`.
- Natural cross-provider memberships are enabled for Gemini, Copilot, Google Messages, YouTube, YouTube Music, Proton Lumo and Proton Meet.

No Phase-15 applet/runtime behavior is changed.
