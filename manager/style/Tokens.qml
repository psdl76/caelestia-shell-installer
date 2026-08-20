pragma Singleton

import QtQuick

QtObject {
    // Standalone equivalents of Caelestia-style design tokens.
    // Values are intentionally stable and owned by this project.

    // Spacing
    readonly property int spaceXxs: 2
    readonly property int spaceXs: 6
    readonly property int spaceSm: 7
    readonly property int spaceMd: 8
    readonly property int spaceLg: 12
    readonly property int spaceXl: 14
    readonly property int space2xl: 16

    // Shape
    readonly property int radiusXs: 4
    readonly property real radiusStatusDot: 4.5
    readonly property int radiusSm: 10
    readonly property int radiusSource: 11
    readonly property int radiusMd: 12
    readonly property int radiusSwitch: 13
    readonly property int radiusControl: 14
    readonly property int radiusPill: 15
    readonly property int radiusLg: 16
    readonly property int radiusXl: 17
    readonly property int radiusDialog: 24

    // Typography
    readonly property int fontLabel: 11
    readonly property int fontBodySmall: 12
    readonly property int fontBody: 13
    readonly property int fontBodyLarge: 14
    readonly property int fontSubtitle: 16
    readonly property int fontTitle: 18
    readonly property int fontTitleLarge: 19
    readonly property int fontHeadline: 22
    readonly property int fontDisplay: 28

    // Common controls
    readonly property int controlHeightCompact: 32
    readonly property int controlHeight: 34
    readonly property int controlHeightComfortable: 36
    readonly property int iconButtonSize: 36
    readonly property int searchHeight: 42
    readonly property int appRowHeight: 80
    readonly property int appIconSurface: 56
    readonly property int appIconSize: 34
    readonly property int fieldHeight: 38
    readonly property int switchHeight: 26
    readonly property int sourceIconSize: 22

    // Motion
    readonly property int motionPress: 90
    readonly property int motionFast: 120
    readonly property int motionQuick: 150
    readonly property int motionStandard: 160
    readonly property int motionEmphasized: 210
    readonly property int motionDialog: 220
    readonly property real pressedScale: 0.96
    readonly property int focusRingWidth: 2
    readonly property int emptyStateHeight: 160
}
