import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root

    property string label: ""
    property string description: ""
    property var options: []
    property string value: ""
    property bool firstInGroup: false
    property bool lastInGroup: false
    property bool interactive: true
    signal selected(string value)

    function valueLabel() {
        for (let i = 0; i < options.length; ++i) {
            if (options[i].id === value)
                return options[i].label
        }
        return value
    }

    function valueIndex() {
        for (let i = 0; i < options.length; ++i) {
            if (options[i].id === value)
                return i
        }
        return options.length > 0 ? 0 : -1
    }

    function selectCurrentOption() {
        if (optionList.currentIndex < 0 || optionList.currentIndex >= options.length)
            return
        root.selected(options[optionList.currentIndex].id)
        menu.close()
    }

    Layout.fillWidth: true
    implicitHeight: 64
    color: Theme.surfaceAlt
    opacity: root.interactive ? 1 : 0.55
    topLeftRadius: firstInGroup ? Tokens.radiusConnectedOuter : Tokens.radiusConnectedInner
    topRightRadius: topLeftRadius
    bottomLeftRadius: lastInGroup ? Tokens.radiusConnectedOuter : Tokens.radiusConnectedInner
    bottomRightRadius: bottomLeftRadius

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
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
                text: root.description
                color: Theme.textSubtle
                font.pixelSize: Tokens.fontBodySmall
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: selectButton
            implicitWidth: Math.max(118, selectContent.implicitWidth + 24)
            implicitHeight: Tokens.controlHeight
            activeFocusOnTab: root.interactive
            radius: height / 2
            color: menu.opened ? Theme.categoryActive : Theme.controlSurface
            border.width: activeFocus ? Tokens.focusRingWidth : 0
            border.color: Theme.focusStrong

            Keys.onReturnPressed: if (root.interactive) menu.opened ? menu.close() : menu.open()
            Keys.onEnterPressed: if (root.interactive) menu.opened ? menu.close() : menu.open()
            Keys.onSpacePressed: if (root.interactive) menu.opened ? menu.close() : menu.open()

            RowLayout {
                id: selectContent
                anchors.centerIn: parent
                spacing: Tokens.spaceXs
                Text {
                    text: root.valueLabel()
                    color: menu.opened ? Theme.accentText : Theme.controlText
                    font.pixelSize: Tokens.fontBodySmall
                    font.weight: Font.Medium
                }
                Text {
                    text: menu.opened ? "\ue5ce" : "\ue5cf"
                    color: menu.opened ? Theme.accentText : Theme.controlText
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18
                }
            }

            StateLayer {
                disabled: !root.interactive
                onClicked: menu.opened ? menu.close() : menu.open()
            }
        }
    }

    Popup {
        id: menu
        focus: true
        x: root.width - width - 12
        y: root.height + Tokens.spaceXs
        width: Math.min(260, root.width * 0.48)
        height: Math.min(280, optionList.contentHeight + 12)
        padding: 6
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        onOpened: {
            optionList.currentIndex = root.valueIndex()
            optionList.forceActiveFocus()
            if (optionList.currentIndex >= 0)
                optionList.positionViewAtIndex(optionList.currentIndex, ListView.Contain)
        }
        onClosed: if (root.interactive) selectButton.forceActiveFocus()

        enter: Transition {
            ParallelAnimation {
                EffectAnimation { property: "opacity"; from: 0; to: 1; duration: Tokens.motionQuick }
                NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: Tokens.motionEmphasized; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition { EffectAnimation { property: "opacity"; to: 0; duration: Tokens.motionFast } }

        background: Rectangle {
            radius: Tokens.radiusLg
            color: Theme.surfaceRaised
            border.width: 1
            border.color: Theme.fieldBorder
        }

        contentItem: ListView {
            id: optionList
            clip: true
            model: root.options
            spacing: Tokens.spaceXxs
            activeFocusOnTab: false
            keyNavigationEnabled: true
            highlightMoveDuration: Tokens.motionFastSpatial

            Keys.onUpPressed: optionList.decrementCurrentIndex()
            Keys.onDownPressed: optionList.incrementCurrentIndex()
            Keys.onHomePressed: optionList.currentIndex = optionList.count > 0 ? 0 : -1
            Keys.onEndPressed: optionList.currentIndex = optionList.count - 1
            Keys.onReturnPressed: root.selectCurrentOption()
            Keys.onEnterPressed: root.selectCurrentOption()
            Keys.onSpacePressed: root.selectCurrentOption()
            Keys.onEscapePressed: menu.close()

            delegate: Rectangle {
                required property var modelData
                required property int index
                width: optionList.width
                height: Tokens.controlHeightComfortable
                radius: Tokens.radiusControl
                color: optionList.activeFocus && index === optionList.currentIndex
                    ? Theme.categoryActive
                    : (modelData.id === root.value ? Theme.controlSurface : "transparent")

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    color: (modelData.id === root.value || (optionList.activeFocus && index === optionList.currentIndex)) ? Theme.accentText : Theme.controlText
                    font.pixelSize: Tokens.fontBodySmall
                    font.weight: modelData.id === root.value ? Font.DemiBold : Font.Normal
                }

                StateLayer {
                    onClicked: {
                        optionList.currentIndex = index
                        root.selectCurrentOption()
                    }
                }
            }
        }
    }
}
