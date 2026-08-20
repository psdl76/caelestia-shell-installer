import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string stateHome: {
        const value = Quickshell.env("XDG_STATE_HOME")
        return value && value.length > 0 ? value : Quickshell.env("HOME") + "/.local/state"
    }
    readonly property string themePath: stateHome + "/caelestia/theme/caelestia-webapps.json"

    property var palette: ({})
    property bool available: false

    function colour(role, fallback) {
        const value = root.palette[role]
        return typeof value === "string" && /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value)
            ? value : fallback
    }

    function reloadTheme() {
        try {
            const parsed = JSON.parse(themeReader.text())
            const required = ["surface", "onSurface", "onSurfaceVariant", "primary", "error"]
            for (let i = 0; i < required.length; ++i) {
                const value = parsed[required[i]]
                if (typeof value !== "string" || !/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value))
                    throw new Error("Invalid theme role " + required[i])
            }
            root.palette = parsed
            root.available = true
        } catch (e) {
            if (Object.keys(root.palette).length === 0)
                root.available = false
        }
    }

    property FileView themeReader: FileView {
        path: root.themePath
        watchChanges: true
        onLoaded: root.reloadTheme()
        onFileChanged: themeReader.reload()
        onLoadFailed: function(error) {
            if (Object.keys(root.palette).length === 0)
                root.available = false
        }
    }

    readonly property color text: colour("onSurface", "#f2f2f2")
    readonly property color textMuted: colour("onSurfaceVariant", "#b9bbc2")
    readonly property color hover: colour("surfaceContainerHighest", "#26ffffff")
    readonly property color surface: colour("surfaceContainerLow", "#12ffffff")
    readonly property color surfaceHover: colour("surfaceContainerHigh", "#22ffffff")
    readonly property color outline: colour("outlineVariant", "#20ffffff")
    readonly property color outlineHover: colour("outline", "#45ffffff")
    // Native Caelestia StatusIcons/TrayItem use the Material secondary role.
    readonly property color barIcon: colour("secondary", "#a9cfe6")
    readonly property color accent: colour("primary", "#d5e3ff")
    readonly property color accentContent: colour("onPrimary", "#102028")
    readonly property color error: colour("error", "#ffb4ab")
}
