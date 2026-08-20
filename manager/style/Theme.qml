pragma Singleton

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

    property var caelestiaPalette: ({})
    property string caelestiaMode: ""
    property bool caelestiaThemeAvailable: false

    function colour(role, fallback) {
        const value = root.caelestiaPalette[role]
        return typeof value === "string" && /^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value)
            ? value : fallback
    }

    function loadCaelestiaTheme() {
        try {
            const parsed = JSON.parse(themeReader.text())
            const required = ["background","surface","onSurface","primary","onPrimary","error"]
            for (let i = 0; i < required.length; ++i) {
                const value = parsed[required[i]]
                if (typeof value !== "string" || !/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value))
                    throw new Error("Invalid Caelestia role " + required[i])
            }
            root.caelestiaPalette = parsed
            root.caelestiaMode = typeof parsed.mode === "string" ? parsed.mode : ""
            root.caelestiaThemeAvailable = true
        } catch (e) {
            if (Object.keys(root.caelestiaPalette).length === 0)
                root.caelestiaThemeAvailable = false
        }
    }

    property FileView themeReader: FileView {
        path: root.themePath
        watchChanges: true
        onLoaded: root.loadCaelestiaTheme()
        onFileChanged: themeReader.reload()
        onLoadFailed: function(error) {
            if (Object.keys(root.caelestiaPalette).length === 0)
                root.caelestiaThemeAvailable = false
        }
    }

    // Semantic Manager roles. Each keeps the accepted Phase-10.1 value
    // as a local fallback, but follows Caelestia Material roles when present.
    readonly property color background: colour("background", "#0b1216")
    readonly property color surfaceLow: colour("surfaceContainerLowest", "#10191e")
    readonly property color primaryContent: colour("onPrimary", "#102028")
    readonly property color surfaceRaised: colour("surfaceContainerLow", "#151f24")
    readonly property color surfaceAlt: colour("surfaceContainer", "#152027")
    readonly property color sourceSurface: colour("surfaceContainerLow", "#18272e")
    readonly property color rowSurface: colour("surfaceContainerLow", "#19242a")
    readonly property color toolbarSurface: colour("surfaceContainer", "#1a2830")
    readonly property color categoryActive: colour("secondaryContainer", "#1e2b31")
    readonly property color controlSurface: colour("surfaceContainerHigh", "#202b31")
    readonly property color sourceHover: colour("surfaceContainerHigh", "#21343d")
    readonly property color rowHover: colour("surfaceContainerHigh", "#223139")
    readonly property color fieldBorder: colour("outlineVariant", "#263740")
    readonly property color controlHover: colour("surfaceContainerHighest", "#263840")
    readonly property color switchOff: colour("surfaceContainerHigh", "#27343b")
    readonly property color divider: colour("outlineVariant", "#29343a")
    readonly property color dangerSurface: colour("errorContainer", "#2a2327")
    readonly property color subtleHover: colour("surfaceContainerHigh", "#2a373e")
    readonly property color pickerHover: colour("surfaceContainerHighest", "#2a3a43")
    readonly property color categoryBorder: colour("outlineVariant", "#2d414c")
    readonly property color toolbarBorder: colour("outlineVariant", "#30434d")
    readonly property color dialogBorder: colour("outlineVariant", "#31434d")
    readonly property color switchBorderOff: colour("outline", "#3a4a52")
    readonly property color catalogSourceBorder: colour("outlineVariant", "#3b4d57")
    readonly property color userSourceBorder: colour("primary", "#3f6070")
    readonly property color dangerHover: colour("error", "#452c31")
    readonly property color dangerAction: colour("errorContainer", "#472a30")
    readonly property color dangerActionHover: colour("error", "#5a3037")

    readonly property color running: colour("tertiary", "#69d77a")
    readonly property color focus: colour("primary", "#6ea8c4")
    readonly property color textDisabled: colour("outline", "#6f818b")
    readonly property color placeholder: colour("outline", "#77858e")
    readonly property color switchOn: colour("primary", "#77b8d6")
    readonly property color hint: colour("onSurfaceVariant", "#788a94")
    readonly property color textMuted: colour("onSurfaceVariant", "#7f8d96")
    readonly property color textSubtle: colour("outline", "#7f9099")
    readonly property color textTertiary: colour("onSurfaceVariant", "#89969e")
    readonly property color statusIdle: colour("outline", "#8f9ca5")
    readonly property color labelMuted: colour("onSurfaceVariant", "#8fa0aa")
    readonly property color dialogMuted: colour("onSurfaceVariant", "#94a4ad")
    readonly property color runningBorder: colour("tertiary", "#9af1a7")
    readonly property color switchBorderOn: colour("primary", "#9cd5ee")
    readonly property color userSource: colour("primary", "#9ec9dc")
    readonly property color categoryText: colour("onSurfaceVariant", "#a1adb5")
    readonly property color accentMuted: colour("secondary", "#a9cfe6")
    readonly property color primary: colour("primary", "#a9d5ec")
    readonly property color switchThumbOff: colour("onSurfaceVariant", "#aab7be")
    readonly property color textSecondary: colour("onSurfaceVariant", "#aebdc5")
    readonly property color controlText: colour("onSurface", "#b7c8d1")
    readonly property color accentText: colour("primary", "#b8dcf1")
    readonly property color primaryHover: colour("secondary", "#b9e1f4")
    readonly property color pickerText: colour("onSurface", "#c0d0d8")
    readonly property color sliderLabel: colour("onSurface", "#c7d4db")
    readonly property color scrimSoft: "#cc000000"
    readonly property color focusStrong: colour("primary", "#d6effb")
    readonly property color textPrimaryAlt: colour("onSurface", "#d8e6ef")
    readonly property color textPrimary: colour("onSurface", "#d9e5ec")
    readonly property color scrim: "#dd000000"
    readonly property color dangerText: colour("onErrorContainer", "#e5aab0")
    readonly property color error: colour("error", "#f0a8b0")
    readonly property color dangerActionText: colour("onErrorContainer", "#f0b8bd")
}
