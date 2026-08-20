import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: ""
    property string description: ""
    property bool checked: false
    property bool firstInGroup: false
    property bool lastInGroup: false
    property bool interactive: true
    signal toggled()

    Layout.fillWidth: true
    implicitHeight: 64
    activeFocusOnTab: root.interactive
    color: Theme.surfaceAlt
    opacity: root.interactive ? 1 : 0.55
    topLeftRadius: firstInGroup ? Tokens.radiusConnectedOuter : Tokens.radiusConnectedInner
    topRightRadius: topLeftRadius
    bottomLeftRadius: lastInGroup ? Tokens.radiusConnectedOuter : Tokens.radiusConnectedInner
    bottomRightRadius: bottomLeftRadius
    border.width: root.activeFocus ? Tokens.focusRingWidth : 0
    border.color: Theme.focusStrong

    Keys.onReturnPressed: if (root.interactive) root.toggled()
    Keys.onEnterPressed: if (root.interactive) root.toggled()
    Keys.onSpacePressed: if (root.interactive) root.toggled()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: Tokens.spaceLg

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.title
                color: Theme.textPrimary
                font.pixelSize: Tokens.fontBodyLarge
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.description
                color: Theme.textSubtle
                font.pixelSize: Tokens.fontBodySmall
                elide: Text.ElideRight
            }
        }

        Rectangle {
            implicitWidth: 42
            implicitHeight: 24
            radius: height / 2
            color: root.checked ? Theme.switchOn : Theme.switchOff
            border.width: 1
            border.color: root.checked ? Theme.switchBorderOn : Theme.switchBorderOff

            Rectangle {
                width: 18
                height: 18
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.checked ? parent.width - width - 3 : 3
                color: root.checked ? Theme.primaryContent : Theme.switchThumbOff
                Behavior on x { SpatialAnimation { duration: Tokens.motionFastSpatial } }
            }
        }
    }

    StateLayer {
        disabled: !root.interactive
        onClicked: root.toggled()
    }
}
