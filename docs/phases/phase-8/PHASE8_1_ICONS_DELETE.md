# Phase 8.1 – userapps-icons-delete-01

User Apps now support create, icon selection (auto/url/local), install, launch/focus, setup, repair, edit, uninstall, and final catalog removal.

Managed local icons live under `$XDG_DATA_HOME/caelestia-webapps/user-icons/` (default `~/.local/share/caelestia-webapps/user-icons/`). SVG files are copied; PNG files are preserved and embedded into an SVG wrapper so the established SVG-only installer remains unchanged.

`user-delete` is allowed only for uninstalled user apps and removes both the definition and managed icon. Built-ins cannot be removed.


## fix2

- `iconStore` is now empty when neither cached SVG nor PNG exists.
- This allows the manager to fall through to `iconUrl` for freshly-created, not-yet-installed User Apps.
- Automatic Dashboard-Icons preview is only requested after App-ID editing is committed, avoiding 404 requests for partial slugs such as `h` or `home`.
