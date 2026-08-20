import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property bool disabled: false
    property bool showHoverBackground: true
    property color color: Theme.textPrimary
    readonly property alias hovered: pointer.containsMouse
    readonly property alias pressed: pointer.pressed
    property real pressX: width / 2
    property real pressY: height / 2
    property real circleRadius: 0
    readonly property real endRadius: {
        const d1 = root.distanceSquared(0, 0)
        const d2 = root.distanceSquared(width, 0)
        const d3 = root.distanceSquared(0, height)
        const d4 = root.distanceSquared(width, height)
        return Math.sqrt(Math.max(d1, d2, d3, d4)) * 1.3
    }
    signal clicked()

    function distanceSquared(x, y) {
        return (pressX - x) ** 2 + (pressY - y) ** 2
    }

    function clampedRadius(value) {
        return Math.max(0, Math.min(value, width / 2, height / 2))
    }

    function cornerRadius(name) {
        if (root.parent && root.parent[name] !== undefined)
            return root.clampedRadius(root.parent[name])
        if (root.parent && root.parent.radius !== undefined)
            return root.clampedRadius(root.parent.radius)
        return 0
    }

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

    Shape {
        id: ripple
        anchors.fill: parent
        opacity: 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: RadialGradient {
                centerX: root.pressX
                centerY: root.pressY
                centerRadius: Math.max(0.01, root.circleRadius)
                focalX: centerX
                focalY: centerY

                GradientStop { position: 0; color: root.color }
                GradientStop {
                    position: Math.max(0.01, Math.min(0.99, 1 - 0.2 * root.endRadius / Math.max(0.01, root.circleRadius)))
                    color: root.color
                }
                GradientStop { position: 1; color: "transparent" }
            }

            startX: root.cornerRadius("topLeftRadius")
            startY: 0
            PathLine { x: root.width - root.cornerRadius("topRightRadius"); y: 0 }
            PathArc {
                relativeX: root.cornerRadius("topRightRadius")
                relativeY: root.cornerRadius("topRightRadius")
                radiusX: root.cornerRadius("topRightRadius")
                radiusY: radiusX
            }
            PathLine { x: root.width; y: root.height - root.cornerRadius("bottomRightRadius") }
            PathArc {
                relativeX: -root.cornerRadius("bottomRightRadius")
                relativeY: root.cornerRadius("bottomRightRadius")
                radiusX: root.cornerRadius("bottomRightRadius")
                radiusY: radiusX
            }
            PathLine { x: root.cornerRadius("bottomLeftRadius"); y: root.height }
            PathArc {
                relativeX: -root.cornerRadius("bottomLeftRadius")
                relativeY: -root.cornerRadius("bottomLeftRadius")
                radiusX: root.cornerRadius("bottomLeftRadius")
                radiusY: radiusX
            }
            PathLine { x: 0; y: root.cornerRadius("topLeftRadius") }
            PathArc {
                relativeX: root.cornerRadius("topLeftRadius")
                relativeY: -root.cornerRadius("topLeftRadius")
                radiusX: root.cornerRadius("topLeftRadius")
                radiusY: radiusX
            }
        }

        ParallelAnimation {
            id: rippleIn
            SpatialAnimation {
                target: root
                property: "circleRadius"
                from: 0
                to: root.endRadius
                duration: Tokens.motionSlowEffects * 2
            }
            SequentialAnimation {
                NumberAnimation { target: ripple; property: "opacity"; from: 0; to: 0.12; duration: Tokens.motionPress }
                PauseAnimation { duration: Tokens.motionEmphasized }
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
            root.pressX = mouse.x
            root.pressY = mouse.y
            rippleIn.restart()
        }
        onClicked: root.clicked()
    }
}
