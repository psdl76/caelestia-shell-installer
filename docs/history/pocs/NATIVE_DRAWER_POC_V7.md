# Native Sidebar PoC v7 — Categories

v7 adds data-driven category filtering on top of the frozen v6.3 UI checkpoint.

- Category labels/order live in `config/categories.json`.
- App assignments remain in each app definition through `APP_CATALOG_CATEGORY`.
- `catalog.json` now includes only categories that actually contain apps, including counts.
- The WebApps sidebar reads those category objects directly.
- `Alle` is a UI-only aggregate filter.
- Categories are horizontally scrollable for future larger catalogs.
- Borderless v6.3 rows and all existing actions remain unchanged.

No category/app mapping is hard-coded in QML.
