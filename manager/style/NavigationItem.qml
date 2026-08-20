import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: ""
    property string description: ""
    property string icon: ""
    property bool selected: false
    property bool firstInGroup: false
    property bool lastInGroup: false
    property bool interactive: true
    signal clicked()

    implicitHeight: selected ? Tokens.navigationItemActiveHeight : Tokens.navigationItemHeight
    color: selected ? Theme.categoryActive : Theme.navigationItem
    topLeftRadius: state.pressed ? Tokens.radiusMd : (selected ? Tokens.radiusConnectedOuter : (firstInGroup ? Tokens.radiusConnectedOuter : Tokens.radiusConnectedInner))
    topRightRadius: topLeftRadius
    bottomLeftRadius: state.pressed ? Tokens.radiusMd : (selected ? Tokens.radiusConnectedOuter : (lastInGroup ? Tokens.radiusConnectedOuter : Tokens.radiusConnectedInner))
    bottomRightRadius: bottomLeftRadius
    activeFocusOnTab: interactive

    Behavior on implicitHeight { SpatialAnimation { duration: Tokens.motionFastSpatial } }
    Behavior on topLeftRadius { EffectAnimation {} }
    Behavior on topRightRadius { EffectAnimation {} }
    Behavior on bottomLeftRadius { EffectAnimation {} }
    Behavior on bottomRightRadius { EffectAnimation {} }
    Behavior on color { ColorAnimation { duration: Tokens.motionSlowEffects; easing.type: Easing.OutCubic } }

    Keys.onReturnPressed: if (interactive) root.clicked()
    Keys.onEnterPressed: if (interactive) root.clicked()
    Keys.onSpacePressed: if (interactive) root.clicked()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: Tokens.spaceLg

        Rectangle {
            implicitWidth: Tokens.navigationIconSize
            implicitHeight: Tokens.navigationIconSize
            radius: width / 2
            color: root.selected ? Theme.primary : Theme.categoryActive

            Behavior on color { ColorAnimation { duration: Tokens.motionSlowEffects; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                text: root.icon
                color: root.selected ? Theme.primaryContent : Theme.accentText
                font.family: "Material Symbols Rounded"
                font.pixelSize: 21
                font.weight: Font.Medium
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.label
                color: Theme.textPrimary
                font.pixelSize: Tokens.fontBodyLarge
                font.weight: root.selected ? Font.DemiBold : Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.description
                color: Theme.textMuted
                font.pixelSize: Tokens.fontBodySmall
                elide: Text.ElideRight
            }
        }
    }

    StateLayer {
        id: state
        disabled: !root.interactive
        color: root.selected ? Theme.accentText : Theme.textPrimary
        onClicked: root.clicked()
    }
}
