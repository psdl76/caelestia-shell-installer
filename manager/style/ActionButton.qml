import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string label: ""
    property string icon: ""
    property bool primary: false
    property bool danger: false
    property bool interactive: true
    property int minimumWidth: 0
    signal clicked()

    implicitWidth: Math.max(minimumWidth, content.implicitWidth + 24)
    implicitHeight: Tokens.controlHeight
    activeFocusOnTab: root.interactive
    radius: state.pressed ? Tokens.radiusMd : height / 2
    opacity: root.interactive ? 1.0 : 0.45
    scale: state.pressed && root.interactive ? Tokens.pressedScale : 1.0
    color: {
        if (root.danger) return Theme.dangerAction
        if (root.primary) return Theme.primary
        return Theme.controlSurface
    }
    border.width: root.activeFocus ? Tokens.focusRingWidth : (root.primary || root.danger ? 0 : 1)
    border.color: root.activeFocus ? Theme.focusStrong : Theme.fieldBorder
    Behavior on scale { NumberAnimation { duration: Tokens.motionPress; easing.type: Easing.OutCubic } }
    Behavior on radius { EffectAnimation {} }

    Keys.onReturnPressed: if (root.interactive) root.clicked()
    Keys.onEnterPressed: if (root.interactive) root.clicked()
    Keys.onSpacePressed: if (root.interactive) root.clicked()

    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Tokens.spaceXs
        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: root.danger ? Theme.dangerActionText : (root.primary ? Theme.primaryContent : Theme.controlText)
            font.family: "Material Symbols Rounded"
            font.pixelSize: 17
            font.weight: Font.Medium
        }
        Text {
            visible: root.label.length > 0
            text: root.label
            color: root.danger ? Theme.dangerActionText : (root.primary ? Theme.primaryContent : Theme.controlText)
            font.pixelSize: Tokens.fontBodySmall
            font.weight: root.primary || root.danger ? Font.DemiBold : Font.Medium
        }
    }
    StateLayer {
        id: state
        disabled: !root.interactive
        color: root.danger ? Theme.dangerActionText : (root.primary ? Theme.primaryContent : Theme.controlText)
        onClicked: root.clicked()
    }
}
