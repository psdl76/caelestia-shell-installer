import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    property alias text: field.text
    property string placeholderText: "Suchen…"
    signal changed(string value)

    function forceSearchFocus() {
        field.forceActiveFocus()
        field.selectAll()
    }

    implicitHeight: Tokens.searchHeight
    radius: Tokens.radiusLg
    color: field.activeFocus ? Theme.surfaceAlt : Theme.surfaceRaised
    border.width: 1
    border.color: field.activeFocus ? Theme.focus : Theme.fieldBorder

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 13
        anchors.rightMargin: 11
        spacing: Tokens.spaceMd
        Text {
            text: "\ue8b6"
            color: field.activeFocus ? Theme.primary : Theme.accentMuted
            font.family: "Material Symbols Rounded"
            font.pixelSize: 19
        }
        TextField {
            id: field
            Layout.fillWidth: true
            placeholderText: root.placeholderText
            color: Theme.textPrimaryAlt
            placeholderTextColor: Theme.placeholder
            background: null
            selectByMouse: true
            font.pixelSize: Tokens.fontBody
            Keys.onEscapePressed: {
                if (text.length > 0)
                    clear()
                else
                    focus = false
            }
            onTextChanged: root.changed(text)
        }
        Text {
            visible: field.text.length > 0
            text: "\ue5cd"
            color: closeHover.hovered ? Theme.primary : Theme.textMuted
            font.family: "Material Symbols Rounded"
            font.pixelSize: 17
            HoverHandler { id: closeHover }
            MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: field.clear() }
        }
    }
}
