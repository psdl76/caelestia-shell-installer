import QtQuick
import QtQuick.Layouts

Text {
    property bool first: false

    Layout.fillWidth: true
    Layout.topMargin: first ? 0 : Tokens.space2xl
    Layout.bottomMargin: Tokens.spaceXs
    Layout.leftMargin: Tokens.spaceLg

    color: Theme.textSecondary
    font.pixelSize: Tokens.fontLabel
    font.weight: Font.Medium
    elide: Text.ElideRight
}
