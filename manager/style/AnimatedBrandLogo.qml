import QtQuick

Item {
    id: root

    property url source
    property bool active: true
    property bool skipIntroAnimation: false

    signal animationCompleted

    implicitWidth: 112
    implicitHeight: 112

    function resetLogo() {
        logo.rotation = 0
        logo.scale = root.skipIntroAnimation ? 1 : 0
        logo.opacity = root.skipIntroAnimation ? 1 : 0
    }

    onActiveChanged: {
        if (active && !skipIntroAnimation)
            intro.restart()
        else if (!active)
            resetLogo()
    }

    Component.onCompleted: {
        resetLogo()
        if (active && !skipIntroAnimation)
            intro.start()
    }

    Item {
        id: logo
        anchors.fill: parent
        transformOrigin: Item.Center

        Image {
            anchors.fill: parent
            source: root.source
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
            mipmap: true
        }
    }

    ParallelAnimation {
        id: intro
        running: false
        onFinished: {
            logo.rotation = 0
            root.animationCompleted()
        }

        SequentialAnimation {
            NumberAnimation {
                target: logo
                property: "rotation"
                from: 0
                to: 750
                duration: 1000
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: logo
                property: "rotation"
                from: 750
                to: 710
                duration: 300
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: logo
                property: "rotation"
                from: 710
                to: 725
                duration: 350
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: logo
                property: "rotation"
                from: 725
                to: 720
                duration: 250
                easing.type: Easing.OutQuad
            }
        }

        SequentialAnimation {
            NumberAnimation {
                target: logo
                property: "scale"
                from: 0
                to: 1.08
                duration: 1000
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: logo
                property: "scale"
                from: 1.08
                to: 0.96
                duration: 200
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: logo
                property: "scale"
                from: 0.96
                to: 1
                duration: 250
                easing.type: Easing.OutBack
                easing.overshoot: 1.05
            }
        }

        NumberAnimation {
            target: logo
            property: "opacity"
            from: 0
            to: 1
            duration: 600
            easing.type: Easing.InOutQuad
        }
    }
}
