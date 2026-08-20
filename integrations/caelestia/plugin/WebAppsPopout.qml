import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import caelestia_webapps.webapps

Item {
    id: root

    implicitWidth: 316
    implicitHeight: Math.max(174, content.implicitHeight + 6)

    property var apps: []
    property var statuses: ({})
    property string errorText: ""

    PluginTheme { id: theme }

    readonly property string processPath: {
        const current = Quickshell.env("PATH") || "";
        const home = Quickshell.env("HOME") || "";
        if (home.length === 0)
            return current;

        const localBin = home + "/.local/bin";
        const entries = current.length > 0 ? current.split(":") : [];
        if (entries.indexOf(localBin) !== -1)
            return current;

        return current.length > 0 ? current + ":" + localBin : localBin;
    }

    function cliCommand(args) {
        return [
            "/usr/bin/env",
            "PATH=" + root.processPath,
            "caelestia-webapps"
        ].concat(args);
    }

    function managerCommand() {
        return [
            "/usr/bin/env",
            "PATH=" + root.processPath,
            "caelestia-webapps-manager"
        ];
    }

    function reload() {
        errorText = "";
        listProcess.exec(root.cliCommand(["list"]));
    }

    function reloadStatuses() {
        statusProcess.exec(root.cliCommand(["status-feed"]));
    }

    function statusFor(appId) {
        return root.statuses[appId] ?? {
            kind: "none",
            available: false,
            capabilities: [],
            state: {}
        };
    }

    function launch(appId) {
        actionProcess.command = root.cliCommand(["launch", appId]);
        actionProcess.startDetached();
    }

    function openManager() {
        actionProcess.command = root.managerCommand();
        actionProcess.startDetached();
    }

    Component.onCompleted: reload()

    Process {
        id: listProcess

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const payload = JSON.parse(text);
                    if (!payload.ok) {
                        root.errorText = "CLI meldet einen Fehler.";
                        root.apps = [];
                        return;
                    }

                    root.apps = (payload.data?.apps ?? []).filter(app =>
                        app.appletVisible === true && app.installed === true
                    );
                    root.reloadStatuses();
                } catch (e) {
                    root.errorText = "WebApps-Liste konnte nicht gelesen werden.";
                    root.apps = [];
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.warn("caelestia-webapps plugin:", text.trim());
            }
        }

        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0 && root.errorText.length === 0)
                root.errorText = "caelestia-webapps list ist fehlgeschlagen.";
        }
    }

    Process {
        id: statusProcess

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const payload = JSON.parse(text);
                    const items = payload.data?.statuses ?? [];
                    const next = {};
                    for (let i = 0; i < items.length; ++i) {
                        const item = items[i];
                        if (item && typeof item.appId === "string")
                            next[item.appId] = item;
                    }
                    root.statuses = next;
                } catch (e) {
                    console.warn("caelestia-webapps plugin: status-feed parse failed", e);
                    root.statuses = ({});
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    console.warn("caelestia-webapps status-feed:", text.trim());
            }
        }
    }

    Process {
        id: actionProcess
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 3
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 9
            Layout.rightMargin: 4
            Layout.topMargin: 1
            Layout.bottomMargin: 0

            Text {
                text: "WebApps"
                color: theme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: reloadHover.hovered ? theme.hover : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 110 }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\ue5d5" // refresh
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: reloadHover.hovered ? theme.accent : theme.textMuted

                    Behavior on color {
                        ColorAnimation { duration: 110 }
                    }
                }

                HoverHandler { id: reloadHover }
                TapHandler { onTapped: root.reload() }
            }
        }

        Text {
            visible: root.errorText.length > 0
            Layout.fillWidth: true
            Layout.leftMargin: 9
            Layout.rightMargin: 9
            Layout.topMargin: 2
            text: root.errorText
            color: theme.error
            wrapMode: Text.Wrap
            font.pixelSize: 13
        }

        Repeater {
            model: root.apps

            delegate: Rectangle {
                required property var modelData

                readonly property var statusData: root.statusFor(modelData.id)
                readonly property var stateData: statusData.state ?? ({})
                readonly property bool hasStatus: statusData.available === true
                readonly property bool isNotification: hasStatus && statusData.kind === "notification"
                readonly property bool isMedia: hasStatus && statusData.kind === "media"

                Layout.fillWidth: true
                implicitHeight: isNotification || isMedia ? 62 : 44
                radius: 12
                color: appHover.hovered ? theme.hover : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 110 }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 7
                    spacing: 9

                    Item {
                        width: 30
                        height: 30

                        Image {
                            anchors.centerIn: parent
                            source: modelData.icon ? "file://" + modelData.icon : ""
                            sourceSize.width: 26
                            sourceSize.height: 26
                            width: 26
                            height: 26
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        Rectangle {
                            visible: isNotification && Number(stateData.count ?? 0) > 0
                            anchors.right: parent.right
                            anchors.top: parent.top
                            width: Math.max(16, badgeText.implicitWidth + 8)
                            height: 16
                            radius: 8
                            color: theme.accent

                            Text {
                                id: badgeText
                                anchors.centerIn: parent
                                text: Number(stateData.count ?? 0) > 99 ? "99+" : String(stateData.count ?? 0)
                                color: theme.surface
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: isMedia && stateData.title ? stateData.title : modelData.name
                            color: theme.text
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: isNotification || isMedia
                            Layout.fillWidth: true
                            text: {
                                if (isNotification) {
                                    const items = Array.isArray(stateData.items) ? stateData.items : [];
                                    const newest = items.length > 0 ? items[0] : null;
                                    const title = String(newest?.title ?? stateData.title ?? "");
                                    const body = String(newest?.text ?? stateData.text ?? "");
                                    return title.length > 0 && body.length > 0 ? title + ": " + body : (body || title);
                                }
                                if (isMedia)
                                    return String(stateData.subtitle ?? "");
                                return "";
                            }
                            color: theme.textMuted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        visible: isMedia
                        text: stateData.playing === true ? "\ue034" : "\ue037"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 17
                        color: appHover.hovered ? theme.accent : theme.textMuted
                    }

                    Text {
                        visible: !isMedia
                        text: "\ue5cc" // chevron_right
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                        color: appHover.hovered ? theme.accent : theme.textMuted

                        Behavior on color {
                            ColorAnimation { duration: 110 }
                        }
                    }
                }

                HoverHandler { id: appHover }
                TapHandler { onTapped: root.launch(modelData.id) }
            }
        }

        Text {
            visible: root.apps.length === 0 && root.errorText.length === 0
            Layout.fillWidth: true
            Layout.leftMargin: 9
            Layout.rightMargin: 9
            Layout.topMargin: 4
            Layout.bottomMargin: 5
            text: "Keine installierten WebApps für das Applet aktiviert."
            color: theme.textMuted
            wrapMode: Text.Wrap
            font.pixelSize: 13
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 38
            radius: 11
            color: managerHover.hovered ? theme.surfaceHover : theme.surface
            border.width: 1
            border.color: managerHover.hovered ? theme.outlineHover : theme.outline

            Behavior on color {
                ColorAnimation { duration: 110 }
            }
            Behavior on border.color {
                ColorAnimation { duration: 110 }
            }

            RowLayout {
                anchors.centerIn: parent
                spacing: 7

                Text {
                    text: "\ue8b8" // settings
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: managerHover.hovered ? theme.accent : theme.text

                    Behavior on color {
                        ColorAnimation { duration: 110 }
                    }
                }

                Text {
                    text: "WebApps verwalten"
                    color: theme.text
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
            }

            HoverHandler { id: managerHover }
            TapHandler { onTapped: root.openManager() }
        }
    }
}
