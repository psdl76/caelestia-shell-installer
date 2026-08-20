import QtQuick
import QtQuick.Controls
import QtQuick.Shapes

Item {
    id: root

    signal clicked()

    implicitWidth: 68
    implicitHeight: 50

    Shape {
        anchors.fill: parent

        ShapePath {
            strokeWidth: 0
            fillColor: Theme.mainSurface
            startX: 0
            startY: 12
            PathLine { x: 14; y: 12 }
            PathQuad { x: 24; y: 2; controlX: 24; controlY: 12 }
            PathQuad { x: 26; y: 0; controlX: 24; controlY: 0 }
            PathLine { x: 68; y: 0 }
            PathLine { x: 68; y: 28 }
            PathQuad { x: 58; y: 38; controlX: 68; controlY: 38 }
            PathLine { x: 56; y: 38 }
            PathLine { x: 56; y: 50 }
            PathLine { x: 0; y: 50 }
            PathLine { x: 0; y: 12 }
        }
    }

    Item {
        id: button
        anchors.top: parent.top
        anchors.right: parent.right
        width: 44
        height: 38
        scale: tap.pressed ? Tokens.pressedScale : 1

        Behavior on scale {
            NumberAnimation { duration: Tokens.motionPress; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.centerIn: parent
            text: "\ue5cd"
            color: pointer.hovered ? Theme.error : Theme.textSecondary
            font.family: "Material Symbols Rounded"
            font.pixelSize: 18
            font.weight: Font.Medium

            Behavior on color { ColorAnimation { duration: Tokens.motionFast } }
        }

        HoverHandler { id: pointer }
        TapHandler {
            id: tap
            onTapped: root.clicked()
        }

        ToolTip.visible: pointer.hovered
        ToolTip.text: "Manager schließen"
    }
}
