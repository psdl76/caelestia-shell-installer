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
    radius: state.pressed ? Tokens.radiusMd : height / 2
    opacity: root.interactive ? 1.0 : 0.45
    scale: state.pressed && root.interactive ? Tokens.pressedScale : 1.0
    color: {
        if (root.danger) return state.hovered && root.interactive ? Theme.dangerHover : Theme.dangerSurface
        if (root.active) return Theme.categoryActive
        return state.hovered && root.interactive ? Theme.controlHover : Theme.controlSurface
    }
    border.width: root.activeFocus ? Tokens.focusRingWidth : (root.active ? 1 : 0)
    border.color: root.activeFocus ? Theme.focusStrong : Theme.categoryBorder
    Behavior on scale { NumberAnimation { duration: Tokens.motionPress; easing.type: Easing.OutCubic } }
    Behavior on radius { EffectAnimation {} }
    Keys.onReturnPressed: if (root.interactive) root.clicked()
    Keys.onEnterPressed: if (root.interactive) root.clicked()
    Keys.onSpacePressed: if (root.interactive) root.clicked()

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.danger ? Theme.dangerText : (root.active ? Theme.accentText : Theme.controlText)
        font.family: "Material Symbols Rounded"
        font.pixelSize: 18
        font.weight: Font.Medium
    }
    StateLayer {
        id: state
        disabled: !root.interactive
        color: root.danger ? Theme.dangerText : (root.active ? Theme.accentText : Theme.controlText)
        onClicked: root.clicked()
    }
    ToolTip.visible: state.hovered && root.tooltip.length > 0
    ToolTip.text: root.tooltip
}
