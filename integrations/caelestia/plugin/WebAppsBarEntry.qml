import QtQuick
import caelestia_webapps.webapps

Item {
    id: root

    implicitWidth: 34
    implicitHeight: 34

    PluginTheme { id: theme }

    Rectangle {
        anchors.centerIn: parent
        width: 28
        height: 28
        radius: 14
        color: hover.hovered ? theme.hover : "transparent"

        Behavior on color {
            ColorAnimation { duration: 110 }
        }

        Text {
            anchors.centerIn: parent
            text: "\ue5c3" // Material Symbols Rounded: apps
            font.family: "Material Symbols Rounded"
            font.pixelSize: 18
            color: hover.hovered ? theme.accent : theme.text

            Behavior on color {
                ColorAnimation { duration: 110 }
            }
        }

        HoverHandler { id: hover }
    }
}
