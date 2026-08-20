import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: ""
    property string description: ""
    property string actionLabel: ""
    property bool firstInGroup: false
    property bool lastInGroup: false
    property bool danger: false
    property bool interactive: true
    signal clicked()

    implicitHeight: Tokens.appRowHeight
    color: Theme.surfaceAlt
    topLeftRadius: firstInGroup ? Tokens.radiusDialog : Tokens.radiusConnectedInner
    topRightRadius: topLeftRadius
    bottomLeftRadius: lastInGroup ? Tokens.radiusDialog : Tokens.radiusConnectedInner
    bottomRightRadius: bottomLeftRadius

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: Tokens.spaceLg

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spaceXxs

            Text {
                Layout.fillWidth: true
                text: root.title
                color: root.danger ? Theme.error : Theme.textPrimary
                font.pixelSize: Tokens.fontBodyLarge
                font.weight: Font.Medium
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

        ActionButton {
            minimumWidth: 104
            label: root.actionLabel
            danger: root.danger
            interactive: root.interactive
            onClicked: root.clicked()
        }
    }
}
