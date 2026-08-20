import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property string icon: ""
    property string tooltip: ""
    property bool danger: false
    property bool active: false
    property bool interactive: true
    signal clicked()

    implicitWidth: Tokens.iconButtonSize
    implicitHeight: Tokens.iconButtonSize
    activeFocusOnTab: root.interactive
    radius: Tokens.radiusControl
    opacity: root.interactive ? 1.0 : 0.45
    scale: pointer.pressed && root.interactive ? Tokens.pressedScale : 1.0
    color: {
        if (root.danger) return hover.hovered && root.interactive ? Theme.dangerHover : Theme.dangerSurface
        if (root.active) return Theme.categoryActive
        return hover.hovered && root.interactive ? Theme.controlHover : Theme.controlSurface
    }
    border.width: root.activeFocus ? Tokens.focusRingWidth : (root.active ? 1 : 0)
    border.color: root.activeFocus ? Theme.focusStrong : Theme.categoryBorder
    Behavior on scale { NumberAnimation { duration: Tokens.motionPress; easing.type: Easing.OutCubic } }
    Keys.onReturnPressed: if (root.interactive) root.clicked()
    Keys.onEnterPressed: if (root.interactive) root.clicked()
    Keys.onSpacePressed: if (root.interactive) root.clicked()

    HoverHandler { id: hover }
    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.danger ? Theme.dangerText : (root.active ? Theme.accentText : Theme.controlText)
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
        font.weight: Font.Medium
    }
    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.interactive
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
    ToolTip.visible: hover.hovered && root.tooltip.length > 0
    ToolTip.text: root.tooltip
}
