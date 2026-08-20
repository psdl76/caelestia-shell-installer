# Native Sidebar PoC v2

PoC v2 keeps the original Caelestia notification sidebar and adds WebApps as a
second page inside the same native sidebar.

The installer copies the user's actual current `modules/sidebar/Content.qml` to
`OriginalContent.qml`, so version-specific notification behavior is preserved.
It then installs a tiny wrapper with a native two-page switcher:

- Benachrichtigungen → exact original Sidebar Content
- WebApps → WebApps catalog view

Caelestia's `Sidebar.Wrapper`, Drawers window, PanelBg/BlobRect deformation and
native opening/closing animation are not modified.

Restore removes both PoC helper components and puts the exact backed-up original
Content.qml back.
