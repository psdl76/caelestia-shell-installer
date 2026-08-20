import QtQuick

NumberAnimation {
    duration: Tokens.motionDefaultSpatial
    easing.type: Easing.BezierSpline
    easing.bezierCurve: [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
}
