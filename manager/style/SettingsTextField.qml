import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: ""
    property string description: ""
    property string value: ""
    property string errorText: ""
    property bool readOnly: false
    property bool firstInGroup: false
    property bool lastInGroup: false
    readonly property alias field: input
    signal valueEdited(string value)
    signal editingFinished(string value)

    Layout.fillWidth: true
    implicitHeight: 64
    color: Theme.surfaceAlt
    opacity: root.readOnly ? 0.62 : 1
    topLeftRadius: firstInGroup ? Tokens.radiusConnectedOuter : Tokens.radiusConnectedInner
    topRightRadius: topLeftRadius
    bottomLeftRadius: lastInGroup ? Tokens.radiusConnectedOuter : Tokens.radiusConnectedInner
    bottomRightRadius: bottomLeftRadius

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
                text: root.label
                color: Theme.textPrimary
                font.pixelSize: Tokens.fontBodyLarge
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.errorText.length > 0 ? root.errorText : root.description
                color: root.errorText.length > 0 ? Theme.error : Theme.textSubtle
                font.pixelSize: Tokens.fontBodySmall
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: Math.min(300, root.width * 0.46)
            implicitHeight: Tokens.fieldHeight
            radius: Tokens.radiusControl
            color: Theme.controlSurface
            border.width: input.activeFocus ? Tokens.focusRingWidth : 0
            border.color: Theme.focusStrong

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                text: root.value
                readOnly: root.readOnly
                color: Theme.controlText
                selectionColor: Theme.primary
                selectedTextColor: Theme.primaryContent
                selectByMouse: true
                activeFocusOnTab: !root.readOnly
                font.pixelSize: Tokens.fontBodySmall
                onTextEdited: root.valueEdited(text)
                onEditingFinished: root.editingFinished(text)
            }
        }
    }
}
