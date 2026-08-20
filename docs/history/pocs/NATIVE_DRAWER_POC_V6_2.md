# Native Sidebar PoC v6.2 — reliable trash icon

The uninstall confirmation now renders the trash can as the Material icon glyph
U+E872 using the same Material Symbols Rounded font family used by Caelestia.

This avoids the previous situation where the ligature text `delete` could appear
literally instead of being converted into an icon.

No layout, animation, confirmation, or backend behavior changed from v6.1.
