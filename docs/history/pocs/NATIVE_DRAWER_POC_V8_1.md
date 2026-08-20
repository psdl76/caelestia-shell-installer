# Native Sidebar PoC v8.1 — Search/category morph

Fixes the search/category collision from v8.

- `Alle` stays as a permanent left anchor.
- The remaining categories form a separate strip.
- Opening search fades/scales that strip away while the search field expands
  into the freed space.
- Closing search reverses the transition.
- The selected category is preserved while searching.
- Search placeholder reflects the active category.
- Search logic and all backend actions are unchanged.
