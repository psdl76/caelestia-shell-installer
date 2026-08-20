# Native Sidebar PoC v8 — Search

v8 adds local search on top of the user-accepted v7 category checkpoint.

Design:
- the sidebar stays quiet at rest: only a small search icon is shown;
- clicking it morphs the control into a native search surface using Caelestia `Anim`;
- ESC or the close icon clears and collapses search;
- search and category filters compose rather than replacing one another;
- matching covers app name, id, generic name, description/comment, category id and
  human-readable category label;
- no process/network request runs per keystroke;
- a native empty state appears when a filter has no matches.

All v7 category behavior and v6.3 app/action UI remain unchanged.
