import QtQuick

Item {
    id: root

    property bool disabled: false
    property bool showHoverBackground: true
    property color color: Theme.textPrimary
    readonly property alias hovered: pointer.containsMouse
    readonly property alias pressed: pointer.pressed
    signal clicked()

    anchors.fill: parent
    clip: true

    Rectangle {
        anchors.fill: parent
        color: root.color
        opacity: root.showHoverBackground && pointer.containsMouse ? 0.08 : 0
        topLeftRadius: root.parent && root.parent.topLeftRadius !== undefined
            ? root.parent.topLeftRadius : (root.parent && root.parent.radius !== undefined ? root.parent.radius : 0)
        topRightRadius: root.parent && root.parent.topRightRadius !== undefined
            ? root.parent.topRightRadius : (root.parent && root.parent.radius !== undefined ? root.parent.radius : 0)
        bottomLeftRadius: root.parent && root.parent.bottomLeftRadius !== undefined
            ? root.parent.bottomLeftRadius : (root.parent && root.parent.radius !== undefined ? root.parent.radius : 0)
        bottomRightRadius: root.parent && root.parent.bottomRightRadius !== undefined
            ? root.parent.bottomRightRadius : (root.parent && root.parent.radius !== undefined ? root.parent.radius : 0)

        Behavior on opacity { EffectAnimation { duration: Tokens.motionFast } }
    }

    Rectangle {
        id: ripple
        width: 28
        height: 28
        radius: 14
        color: root.color
        opacity: 0
        scale: 0
        transformOrigin: Item.Center

        ParallelAnimation {
            id: rippleIn
            SpatialAnimation {
                target: ripple
                property: "scale"
                from: 0
                to: Math.max(root.width, root.height) / 10
                duration: Tokens.motionDefaultSpatial
            }
            SequentialAnimation {
                NumberAnimation { target: ripple; property: "opacity"; from: 0; to: 0.12; duration: Tokens.motionPress }
                EffectAnimation { target: ripple; property: "opacity"; to: 0; duration: Tokens.motionSlowEffects }
            }
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: !root.disabled
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: function(mouse) {
            ripple.x = mouse.x - ripple.width / 2
            ripple.y = mouse.y - ripple.height / 2
            rippleIn.restart()
        }
        onClicked: root.clicked()
    }
}
