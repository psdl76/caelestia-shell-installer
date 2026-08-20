import QtQuick
import QtQuick.Effects
import Quickshell.Io
import caelestia_webapps.webapps

Item {
    id: root

    required property string appId

    property bool appRunning: false
    property bool runningStateAvailable: false
    property bool appletEnabled: false
    property var capabilitySettings: ({})

    visible: root.appletEnabled && root.appRunning
    implicitWidth: root.appletEnabled && root.appRunning ? 34 : 0
    implicitHeight: root.appletEnabled && root.appRunning ? 34 : 0

    property string iconSource: ""
    property var status: ({ available: false, kind: "none", state: {} })

    function capabilityEnabled(name) {
        return root.capabilitySettings[name] !== false;
    }

    PluginTheme { id: theme }
    CliRuntime { id: runtime }

    function reloadApp() {
        if (metadataProcess.running)
            return;
        // Icon metadata is independent from status polling. A transient CLI/list
        // miss during shell startup must not leave the bar entry iconless for
        // the lifetime of the shell. Retry only while the icon is unresolved.
        if (root.iconSource.length === 0)
            metadataProcess.exec(runtime.cliCommand(["applet-entry", root.appId]));
    }


    function reloadActivation() {
        if (activationProcess.running)
            return;
        activationProcess.exec(runtime.cliCommand(["applet-state", root.appId]));
    }

    function reloadSettings() {
        if (settingsProcess.running)
            return;
        settingsProcess.exec(runtime.cliCommand(["applet-settings", root.appId]));
    }

    function reloadStatus() {
        // Do not restart a still-running CLI poll. Lifecycle operations such as
        // repair/upgrade can briefly hold the engine lock longer than the poll
        // interval; overlapping exec() calls may terminate the previous stdout
        // collector before it has produced JSON.
        if (statusProcess.running)
            return;
        statusProcess.exec(runtime.cliCommand(["status-feed"]));
    }

    function reloadRunning() {
        // Preserve one in-flight running-state query at a time for the same
        // reason as reloadStatus().
        if (runningProcess.running)
            return;
        runningProcess.exec(runtime.cliCommand(["running-feed"]));
    }

    function applyRunning(items, available) {
        root.runningStateAvailable = available === true;
        // Preserve the last confirmed running state across transient feed
        // failures. Visibility may only change on a successful running-feed.
        if (!root.runningStateAvailable)
            return;

        for (let i = 0; i < items.length; ++i) {
            const item = items[i];
            if (item && item.appId === root.appId) {
                root.appRunning = item.running === true;
                return;
            }
        }
        root.appRunning = false;
    }

    function applyStatus(items) {
        for (let i = 0; i < items.length; ++i) {
            const item = items[i];
            if (item && item.appId === root.appId) {
                root.status = item;
                return;
            }
        }
        root.status = ({ available: false, kind: "none", state: {} });
    }

    Component.onCompleted: {
        reloadApp();
        reloadActivation();
        reloadSettings();
        reloadRunning();
        reloadStatus();
    }

    // State-driven startup retry: no arbitrary one-shot delay. The timer stops
    // automatically as soon as list metadata resolved the icon source.
    Timer {
        id: iconRetryTimer
        interval: 1000
        repeat: true
        running: root.iconSource.length === 0
        onTriggered: root.reloadApp()
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.reloadActivation()
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.reloadSettings()
    }

    Timer {
        interval: 750
        repeat: true
        running: true
        onTriggered: root.reloadRunning()
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root.reloadStatus()
    }

    Process {
        id: metadataProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const payload = JSON.parse(text);
                    const app = payload.data?.app ?? null;
                    if (!app || app.id !== root.appId) {
                        console.warn("caelestia-webapps: applet registry metadata missing", root.appId);
                        return;
                    }
                    root.iconSource = app.iconPath ? "file://" + app.iconPath : "";
                    if (root.iconSource.length === 0)
                        console.warn("caelestia-webapps: applet icon source unresolved", root.appId);
                } catch (e) {
                    console.warn("caelestia-webapps: applet-entry parse failed", e);
                }
            }
        }
    }

    Process {
        id: activationProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output.length === 0)
                    return;
                try {
                    const payload = JSON.parse(output);
                    const items = payload.data?.apps ?? [];
                    for (let i = 0; i < items.length; ++i) {
                        const item = items[i];
                        if (item && item.appId === root.appId) {
                            root.appletEnabled = item.enabled === true;
                            return;
                        }
                    }
                } catch (e) {
                    console.warn("caelestia-webapps: applet-state parse failed", e);
                    // Preserve the last confirmed activation state across a
                    // transient CLI/lock failure.
                }
            }
        }
    }

    Process {
        id: settingsProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output.length === 0)
                    return;
                try {
                    const payload = JSON.parse(output);
                    const items = payload.data?.apps ?? [];
                    for (let i = 0; i < items.length; ++i) {
                        const item = items[i];
                        if (item && item.appId === root.appId) {
                            root.capabilitySettings = item.settings ?? ({});
                            return;
                        }
                    }
                } catch (e) {
                    console.warn("caelestia-webapps: applet-settings parse failed", e);
                }
            }
        }
    }

    Process {
        id: runningProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output.length === 0) {
                    // Empty output is a transient process/reload condition, not
                    // evidence that the app stopped and not valid JSON.
                    root.runningStateAvailable = false;
                    return;
                }
                try {
                    const payload = JSON.parse(output);
                    root.applyRunning(
                        payload.data?.apps ?? [],
                        payload.data?.available === true
                    );
                } catch (e) {
                    console.warn("caelestia-webapps: running-feed parse failed", e);
                    // A parse/transport failure is not evidence that the app
                    // stopped. Keep the last confirmed state until a valid feed
                    // explicitly reports running:false.
                    root.runningStateAvailable = false;
                }
            }
        }
    }

    Process {
        id: statusProcess
        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output.length === 0)
                    return;
                try {
                    const payload = JSON.parse(output);
                    root.applyStatus(payload.data?.statuses ?? []);
                } catch (e) {
                    console.warn("caelestia-webapps: app entry status parse failed", e);
                    root.status = ({ available: false, kind: "none", state: {} });
                }
            }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: 30
        height: 30
        radius: 15
        color: hover.hovered ? theme.hover : "transparent"

        Behavior on color { ColorAnimation { duration: 110 } }

        // Instantiate the icon only after the CLI has resolved a concrete source.
        // This avoids the first-start race seen when a layered Image is created
        // with an empty source and receives the SVG path later.
        Loader {
            id: iconLoader
            anchors.centerIn: parent
            width: 21
            height: 21
            active: root.iconSource.length > 0

            sourceComponent: Component {
                Image {
                    id: appIcon
                    width: 21
                    height: 21
                    sourceSize.width: 42
                    sourceSize.height: 42
                    source: root.iconSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: false
                    cache: true

                    layer.enabled: status === Image.Ready
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: theme.barIcon
                    }

                    onStatusChanged: {
                        if (status === Image.Error)
                            console.warn("caelestia-webapps: icon load failed", root.appId, source);
                    }
                }
            }
        }

        Rectangle {
            id: badge
            visible: root.status.available === true
                     && root.status.kind === "notification"
                     && root.capabilityEnabled("notifications")
                     && root.capabilityEnabled("badge")
                     && Number(root.status.state?.count ?? 0) > 0

            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -3
            anchors.topMargin: -3

            implicitWidth: Math.max(15, badgeText.implicitWidth + 7)
            width: implicitWidth
            height: 15
            radius: 8

            color: theme.accent
            border.width: 1
            border.color: theme.surface

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: String(root.status.state?.count ?? "")
                color: theme.accentContent
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        Rectangle {
            visible: root.status.available === true
                     && !badge.visible
                     && ((root.status.kind === "notification" && root.capabilityEnabled("notifications"))
                         || (root.status.kind === "media" && root.capabilityEnabled("now_playing")))
            width: 7
            height: 7
            radius: 4
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: theme.accent
            border.width: 1
            border.color: theme.surface
        }

        HoverHandler { id: hover }
    }
}
