import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool interactive: true
    property bool showBack: true
    signal back()

    Layout.fillWidth: true
    spacing: Tokens.spaceLg

    IconButton {
        visible: root.showBack
        icon: "\ue5c4"
        interactive: root.interactive
        onClicked: root.back()
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Tokens.spaceXxs

        Text {
            Layout.fillWidth: true
            text: root.title
            color: Theme.textPrimaryAlt
            font.pixelSize: Tokens.fontDisplay
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: Theme.labelMuted
            font.pixelSize: Tokens.fontBodySmall
            elide: Text.ElideRight
        }
    }
}
