import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: ""
    property string value: ""
    property bool firstInGroup: false
    property bool lastInGroup: false

    Layout.fillWidth: true
    implicitHeight: 52
    color: Theme.surfaceAlt
    topLeftRadius: firstInGroup ? Tokens.radiusConnectedOuter : Tokens.radiusConnectedInner
    topRightRadius: topLeftRadius
    bottomLeftRadius: lastInGroup ? Tokens.radiusConnectedOuter : Tokens.radiusConnectedInner
    bottomRightRadius: bottomLeftRadius

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: Tokens.spaceLg

        Text {
            text: root.label
            color: Theme.textPrimary
            font.pixelSize: Tokens.fontBodyLarge
            font.weight: Font.Medium
        }

        Item { Layout.fillWidth: true }

        Text {
            Layout.fillWidth: true
            Layout.maximumWidth: implicitWidth + 1
            text: root.value
            color: Theme.textSecondary
            font.pixelSize: Tokens.fontBodySmall
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideMiddle
        }
    }
}
