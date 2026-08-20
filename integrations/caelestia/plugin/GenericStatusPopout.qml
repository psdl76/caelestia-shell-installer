import QtQuick
import QtQuick.Effects
import Quickshell
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import caelestia_webapps.webapps

Item {
    id: root

    required property string appId

    implicitWidth: root.status.available === true && root.status.kind === "media"
        ? (root.compactMediaActive ? 344 : 396)
        : 316
    implicitHeight: Math.max(164, content.implicitHeight + 6)

    property var app: ({ id: appId, name: appId, icon: "" })
    property var status: ({ available: false, kind: "none", state: {} })
    property string errorText: ""
    property var mediaToplevel: null
    property var mediaHyprToplevel: null
    property bool livePreviewEnabled: true
    property real visualizerPhase: 0
    // Presentation policy is supplied by the thin per-app wrapper. The
    // renderer remains generic: video apps can prefer a live capture while
    // music apps can prefer MPRIS album artwork.
    property string mediaPresentation: "auto" // auto | video_preview | live_preview | artwork
    property bool pinSupported: false
    property bool pinned: false
    property bool compactMedia: false
    property var capabilitySettings: ({})

    readonly property string pinStatePath: {
        const xdg = Quickshell.env("XDG_STATE_HOME")
        const stateRoot = xdg && xdg.length > 0 ? xdg : Quickshell.env("HOME") + "/.local/state"
        return stateRoot + "/caelestia-webapps/pins.json"
    }
    // Compact styling is only active while a real media status exists.
    // Without a player, YouTube falls back to the same generic layout used by
    // YouTube Music / other status-less WebApps.
    readonly property bool compactMediaActive: root.compactMedia
        && root.status.available === true
        && root.status.kind === "media"

    readonly property bool mediaArtworkAvailable: String(root.status.state?.artwork ?? "").length > 0
    readonly property bool isVideoPresentation: root.mediaPresentation === "video_preview" || root.mediaPresentation === "live_preview"
    readonly property bool useLivePreview: root.isVideoPresentation
        || (root.mediaPresentation === "auto" && !root.mediaArtworkAvailable)
    readonly property bool livePreviewHasContent: livePreviewLoader.item?.hasContent ?? false
    readonly property var videoRect: root.status.state?.videoRect ?? ({})
    readonly property var videoViewport: root.status.state?.videoViewport ?? ({})
    readonly property bool videoCropAvailable: root.isVideoPresentation
        && Number(root.videoRect?.width ?? 0) > 0.01
        && Number(root.videoRect?.height ?? 0) > 0.01
        && Number(root.videoViewport?.width ?? 0) > 1
        && Number(root.videoViewport?.height ?? 0) > 1
    function capabilityEnabled(name) {
        return root.capabilitySettings[name] !== false;
    }

    readonly property bool notificationPresentationEnabled: root.capabilityEnabled("notifications")
    readonly property bool mediaPresentationEnabled: root.capabilityEnabled("now_playing")

    readonly property bool mediaPlaying: String(root.status.state?.videoBridge ?? "").length > 0
        ? root.status.state?.domPlaying === true
        : root.status.state?.playing === true

    function liveCaptureGeometry(targetWidth, targetHeight) {
        if (!root.videoCropAvailable)
            return ({ x: 0, y: 0, width: targetWidth, height: targetHeight });
        const vw = Number(root.videoViewport.width);
        const vh = Number(root.videoViewport.height);
        const rx = Number(root.videoRect.x) * vw;
        const ry = Number(root.videoRect.y) * vh;
        const rw = Math.max(1, Number(root.videoRect.width) * vw);
        const rh = Math.max(1, Number(root.videoRect.height) * vh);
        const scale = Math.max(targetWidth / rw, targetHeight / rh);
        return ({
            x: (targetWidth - rw * scale) / 2 - rx * scale,
            y: (targetHeight - rh * scale) / 2 - ry * scale,
            width: vw * scale,
            height: vh * scale
        });
    }

    PluginTheme { id: theme }
    CliRuntime { id: runtime }

    readonly property var notificationItems: {
        const state = root.status?.state ?? ({});
        return Array.isArray(state.items) ? state.items : [];
    }
    readonly property int notificationCount: Number(root.status?.state?.count ?? 0)
    readonly property int visibleNotificationCount: Math.min(root.notificationItems.length, 3)
    readonly property int hiddenNotificationCount: Math.max(0, root.notificationCount - root.visibleNotificationCount)

    function setMediaToplevel(candidate, hyprCandidate) {
        if (root.mediaToplevel === candidate && root.mediaHyprToplevel === hyprCandidate)
            return;

        root.mediaHyprToplevel = hyprCandidate ?? null;
        root.mediaToplevel = candidate ?? null;
        root.restartLivePreview();
    }

    function resolveMediaToplevel() {
        const wanted = String(root.appId).toLowerCase();

        // Prefer Quickshell's public Hyprland model. The Hyprland class is the
        // same stable app id our launcher creates, while `.wayland` supplies
        // the Toplevel object ScreencopyView explicitly requires.
        const hyprValues = Hyprland.toplevels?.values ?? [];
        for (let i = 0; i < hyprValues.length; ++i) {
            const top = hyprValues[i];
            const ipc = top?.lastIpcObject ?? ({});
            const cls = String(ipc.class ?? "").toLowerCase();
            const initialClass = String(ipc.initialClass ?? "").toLowerCase();
            if (cls === wanted || initialClass === wanted) {
                root.setMediaToplevel(top?.wayland ?? null, top);
                return;
            }
        }

        // Generic Wayland fallback for compositors / cases where Hyprland has
        // not resolved its IPC object yet.
        const values = ToplevelManager.toplevels?.values ?? [];
        for (let i = 0; i < values.length; ++i) {
            const top = values[i];
            if (String(top?.appId ?? "").toLowerCase() === wanted) {
                root.setMediaToplevel(top, null);
                return;
            }
        }

        root.setMediaToplevel(null, null);
    }

    function restartLivePreview() {
        // Recreate ScreencopyView instead of trying to revive a stopped
        // compositor stream in-place. Qt.callLater keeps this event-driven and
        // avoids an arbitrary startup delay.
        root.livePreviewEnabled = false;
        Qt.callLater(() => {
            root.livePreviewEnabled = true;
        });
    }

    function formatTime(seconds) {
        const value = Math.max(0, Math.floor(Number(seconds) || 0));
        const minutes = Math.floor(value / 60);
        const rest = value % 60;
        return minutes + ":" + String(rest).padStart(2, "0");
    }

    function mediaControl(action) {
        mediaControlProcess.exec(runtime.cliCommand(["media-control", root.appId, action]));
    }

    function reloadSettings() {
        if (!settingsProcess.running)
            settingsProcess.exec(runtime.cliCommand(["applet-settings", root.appId]));
    }

    function reloadPinState() {
        if (root.pinSupported)
            pinStateFile.reload();
    }

    function applyPinState() {
        if (!root.pinSupported) {
            root.pinned = false;
            return;
        }
        try {
            const raw = pinStateFile.text().trim();
            if (raw.length === 0) {
                root.pinned = false;
                return;
            }
            const payload = JSON.parse(raw);
            const pins = payload?.pins ?? ({});
            root.pinned = pins[root.appId] === true;
        } catch (e) {
            root.pinned = false;
            console.warn("caelestia-webapps: pin file parse failed", e);
        }
    }

    function togglePinned() {
        if (!root.pinSupported)
            return;
        pinSetProcess.exec(runtime.cliCommand(["pin-set", root.appId, root.pinned ? "off" : "on"]));
    }

    function reload() {
        root.resolveMediaToplevel();
        root.errorText = "";
        metadataProcess.exec(runtime.cliCommand(["applet-entry", root.appId]));
        reloadSettings();
        statusProcess.exec(runtime.cliCommand(["status-feed"]));
    }

    function launch() {
        actionProcess.command = runtime.cliCommand(["launch", root.appId]);
        actionProcess.startDetached();
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
        Hyprland.refreshToplevels();
        reload();
        reloadSettings();
        reloadPinState();
    }

    Connections {
        target: root.mediaHyprToplevel
        function onWaylandChanged() {
            const candidate = root.mediaHyprToplevel?.wayland ?? null;
            if (candidate !== root.mediaToplevel)
                root.setMediaToplevel(candidate, root.mediaHyprToplevel);
        }
    }

    Timer {
        interval: 120
        repeat: true
        running: root.status.available === true && root.status.kind === "media" && root.mediaPlaying
        onTriggered: root.visualizerPhase += 0.38
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.pinSupported
        onTriggered: pinStateFile.reload()
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.reloadSettings()
    }

    Timer {
        interval: root.isVideoPresentation ? 1000 : 2000
        repeat: true
        running: true
        onTriggered: {
            root.resolveMediaToplevel();
            statusProcess.exec(runtime.cliCommand(["status-feed"]));
        }
    }

    Process {
        id: metadataProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const payload = JSON.parse(text);
                    const entry = payload.data?.app ?? null;
                    if (!entry || entry.id !== root.appId) {
                        root.errorText = "Applet registry metadata missing";
                        return;
                    }
                    root.app = ({
                        id: entry.id,
                        name: entry.name ?? entry.id,
                        icon: entry.iconPath ?? "",
                        adapter: entry.adapter ?? "none",
                        support: entry.support ?? "experimental",
                        capabilities: entry.capabilities ?? []
                    });
                    root.errorText = "";
                } catch (e) {
                    root.errorText = "Applet metadata konnte nicht gelesen werden.";
                    console.warn("caelestia-webapps: applet-entry parse failed", root.appId, e);
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
        id: statusProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const payload = JSON.parse(text);
                    root.applyStatus(payload.data?.statuses ?? []);
                } catch (e) {
                    console.warn("caelestia-webapps: per-app status parse failed", e);
                }
            }
        }
    }

    Process { id: actionProcess }
    Process { id: mediaControlProcess }

    FileView {
        id: pinStateFile
        path: root.pinSupported ? root.pinStatePath : ""
        watchChanges: true
        printErrors: false
        onLoaded: root.applyPinState()
        onFileChanged: pinStateFile.reload()
        onLoadFailed: root.pinned = false
    }

    Process {
        id: pinSetProcess
        stdout: StdioCollector {
            onStreamFinished: pinStateFile.reload()
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: root.compactMediaActive ? 2 : 4
        spacing: root.compactMediaActive ? 4 : 7

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 7
            Layout.rightMargin: 3

            Item {
                Layout.preferredWidth: root.compactMediaActive ? 22 : 26
                Layout.preferredHeight: Layout.preferredWidth

                Image {
                    anchors.centerIn: parent
                    width: root.appId === "youtube" ? parent.width : parent.width
                    height: root.appId === "youtube" ? Math.round(parent.width * 20 / 28) : parent.height
                    sourceSize.width: width
                    sourceSize.height: height
                    source: root.appId === "youtube"
                        ? Qt.resolvedUrl("assets/youtube.svg")
                        : (root.app.icon ? "file://" + root.app.icon : "")
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            Text {
                text: root.app.name || root.appId
                color: theme.text
                font.pixelSize: root.compactMediaActive ? 13 : 15
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                visible: root.status.available === true
                         && root.status.kind === "notification"
                         && root.notificationPresentationEnabled
                         && root.capabilityEnabled("badge")
                         && root.notificationCount > 0
                implicitWidth: Math.max(22, headerCountText.implicitWidth + 10)
                height: 20
                radius: 10
                color: theme.accent

                Text {
                    id: headerCountText
                    anchors.centerIn: parent
                    text: root.notificationCount > 99 ? "99+" : String(root.notificationCount)
                    color: theme.surface
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }

            Rectangle {
                visible: root.pinSupported && root.capabilityEnabled("pin")
                width: root.compactMediaActive ? 24 : 28
                height: width
                radius: width / 2
                color: root.pinned
                    ? Qt.alpha(theme.accent, pinHover.hovered ? 0.26 : 0.18)
                    : (pinHover.hovered ? theme.hover : "transparent")

                Text {
                    anchors.centerIn: parent
                    text: "push_pin"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: root.compactMediaActive ? 14 : 16
                    color: root.pinned ? theme.accent : (pinHover.hovered ? theme.accent : theme.textMuted)
                }
                HoverHandler { id: pinHover }
                TapHandler { onTapped: root.togglePinned() }
            }

            Rectangle {
                width: root.compactMediaActive ? 24 : 28
                height: width
                radius: width / 2
                color: reloadHover.hovered ? theme.hover : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "\ue5d5"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: reloadHover.hovered ? theme.accent : theme.textMuted
                }
                HoverHandler { id: reloadHover }
                TapHandler { onTapped: root.reload() }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            visible: root.status.available === true
                     && root.status.kind === "notification"
                     && root.notificationPresentationEnabled
                     && root.capabilityEnabled("preview")
                     && root.notificationItems.length > 0

            Repeater {
                model: root.notificationItems.slice(0, 3)

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: eventColumn.implicitHeight + 16
                    radius: 12
                    color: eventHover.hovered ? theme.surfaceHover : theme.surface
                    border.width: 1
                    border.color: eventHover.hovered ? theme.outlineHover : theme.outline

                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 10
                        anchors.rightMargin: 12
                        spacing: 9

                        Rectangle {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            radius: 19
                            visible: String(modelData?.image ?? "").length > 0
                            color: theme.surfaceHover
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: String(modelData?.image ?? "")
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                            }
                        }

                        ColumnLayout {
                            id: eventColumn
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: String(modelData?.title ?? "Neue Benachrichtigung")
                                color: theme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: String(modelData?.text ?? "")
                                color: theme.textMuted
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }
                    }

                    HoverHandler { id: eventHover }
                    TapHandler { onTapped: root.launch() }
                }
            }

            Text {
                visible: root.hiddenNotificationCount > 0
                Layout.fillWidth: true
                Layout.leftMargin: 7
                text: "+ " + root.hiddenNotificationCount + " weitere"
                color: theme.textMuted
                font.pixelSize: 11
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: legacyNotificationColumn.implicitHeight + 18
            radius: 12
            color: theme.surface
            border.width: 1
            border.color: theme.outline

            visible: root.status.available === true
                     && root.status.kind === "notification"
                     && root.notificationPresentationEnabled
                     && root.capabilityEnabled("preview")
                     && root.notificationItems.length === 0

            ColumnLayout {
                id: legacyNotificationColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: root.status.state?.title ?? "Neue Benachrichtigung"
                    color: theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.status.state?.text ?? ""
                    color: theme.textMuted
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: mediaColumn.implicitHeight
            visible: root.status.available === true && root.status.kind === "media" && root.mediaPresentationEnabled

            ColumnLayout {
                id: mediaColumn
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: root.compactMediaActive ? 8 : 10

                // The captured YouTube video is the hero itself. No nested card,
                // border or app/logo overlay.
                Item {
                    id: heroFrame
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.compactMediaActive ? 181 : 203

                    Rectangle { anchors.fill: parent; radius: 8; color: theme.surfaceHover }

                    Item {
                        id: heroSource
                        anchors.fill: parent
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: heroMask
                        }

                        VideoCropView {
                            id: livePreviewLoader
                            anchors.fill: parent
                            enabled: root.useLivePreview && root.livePreviewEnabled && root.capabilityEnabled("live_preview")
                            captureSource: root.mediaToplevel
                            normalizedRect: root.capabilityEnabled("video_crop") ? root.videoRect : ({ x: 0, y: 0, width: 1, height: 1 })
                            viewport: root.videoViewport
                            onStopped: root.restartLivePreview()
                        }

                        Image {
                            anchors.fill: parent
                            source: String(root.status.state?.artwork ?? "")
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            smooth: true
                            visible: (!root.useLivePreview || !root.capabilityEnabled("live_preview") || !root.livePreviewHasContent)
                                && root.capabilityEnabled("artwork")
                                && source.toString().length > 0
                        }
                    }

                    Rectangle {
                        id: heroMask
                        anchors.fill: parent
                        radius: 8
                        color: "white"
                        visible: false
                        layer.enabled: true
                    }

                    TapHandler { onTapped: root.mediaToplevel ? root.mediaToplevel.activate() : root.launch() }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 2
                    Layout.rightMargin: 2
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: root.status.state?.title ?? ""
                        color: theme.text
                        font.pixelSize: root.compactMediaActive ? 14 : 15
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.status.state?.subtitle ?? ""
                        color: theme.textMuted
                        font.pixelSize: root.compactMediaActive ? 12 : 13
                        elide: Text.ElideRight
                    }
                }

                // Native Caelestia's dashboard player uses time labels around a
                // wavy progress slider. We reproduce that visual language here
                // without importing private shell components.
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 2
                    Layout.rightMargin: 2
                    spacing: 8

                    Text {
                        text: root.formatTime(root.status.state?.position ?? 0)
                        color: theme.textMuted
                        font.pixelSize: 10
                    }

                    Canvas {
                        id: mediaProgress
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18

                        property real progress: Math.max(0, Math.min(1, Number(root.status.state?.progress ?? 0)))
                        property real phase: root.visualizerPhase

                        onProgressChanged: requestPaint()
                        onPhaseChanged: requestPaint()
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const mid = height / 2;
                            const amplitude = 2.1;
                            const wave = 18;
                            const activeEnd = Math.max(0, Math.min(width, width * progress));

                            // Inactive track.
                            ctx.strokeStyle = Qt.alpha(theme.textMuted, 0.35);
                            ctx.lineWidth = 3;
                            ctx.lineCap = "round";
                            ctx.beginPath();
                            ctx.moveTo(activeEnd, mid);
                            ctx.lineTo(width, mid);
                            ctx.stroke();

                            // Active wavy track.
                            if (activeEnd > 0) {
                                ctx.strokeStyle = theme.accent;
                                ctx.lineWidth = 3;
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.moveTo(0, mid);
                                for (let x = 1; x <= activeEnd; x += 2) {
                                    const y = mid + Math.sin((x / wave) * Math.PI * 2 + phase) * amplitude;
                                    ctx.lineTo(x, y);
                                }
                                ctx.stroke();
                            }

                            // Native-like playhead.
                            ctx.fillStyle = theme.accent;
                            ctx.beginPath();
                            ctx.arc(activeEnd, mid, 3.2, 0, Math.PI * 2);
                            ctx.fill();
                        }
                    }

                    Text {
                        text: root.formatTime(root.status.state?.duration ?? 0)
                        color: theme.textMuted
                        font.pixelSize: 10
                    }
                }

                // Caelestia-like transport row: tonal previous/next and a larger
                // filled primary play/pause button.
                RowLayout {
                    visible: root.capabilityEnabled("playback_controls")
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 2
                    spacing: 8

                    Rectangle {
                        width: 42
                        height: 42
                        radius: 21
                        color: prevHover.hovered ? theme.surfaceHover : Qt.alpha(theme.textMuted, 0.10)

                        Text {
                            anchors.centerIn: parent
                            text: "skip_previous"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 23
                            color: theme.text
                        }
                        HoverHandler { id: prevHover }
                        TapHandler { onTapped: root.mediaControl("previous") }
                    }

                    Rectangle {
                        width: 76
                        height: 46
                        radius: 16
                        color: playHover.hovered ? Qt.lighter(theme.accent, 1.06) : theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: root.mediaPlaying ? "pause" : "play_arrow"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 28
                            color: theme.accentContent
                        }
                        HoverHandler { id: playHover }
                        TapHandler { onTapped: root.mediaControl("play-pause") }
                    }

                    Rectangle {
                        width: 42
                        height: 42
                        radius: 21
                        color: nextHover.hovered ? theme.surfaceHover : Qt.alpha(theme.textMuted, 0.10)

                        Text {
                            anchors.centerIn: parent
                            text: "skip_next"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 23
                            color: theme.text
                        }
                        HoverHandler { id: nextHover }
                        TapHandler { onTapped: root.mediaControl("next") }
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 7
            Layout.rightMargin: 7
            visible: (root.status.available !== true
                      || (root.status.kind === "notification" && !root.notificationPresentationEnabled)
                      || (root.status.kind === "media" && !root.mediaPresentationEnabled))
                     && root.errorText.length === 0
            text: root.status.available === true ? "Status in den Applet-Einstellungen deaktiviert." : "Kein aktueller Status verfügbar."
            color: theme.textMuted
            font.pixelSize: 12
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 7
            Layout.rightMargin: 7
            visible: root.errorText.length > 0
            text: root.errorText
            color: theme.error
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.appId !== "youtube"
            implicitHeight: visible ? (root.compactMediaActive ? 34 : 38) : 0
            radius: 11
            color: openHover.hovered ? theme.surfaceHover : theme.surface
            border.width: 1
            border.color: openHover.hovered ? theme.outlineHover : theme.outline

            RowLayout {
                anchors.centerIn: parent
                spacing: 7
                Text {
                    text: "\ue89e"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: root.compactMediaActive ? 14 : 16
                    color: openHover.hovered ? theme.accent : theme.text
                }
                Text {
                    text: (root.app.name || root.appId) + " öffnen"
                    color: theme.text
                    font.pixelSize: root.compactMediaActive ? 11 : 13
                    font.weight: Font.Medium
                }
            }

            HoverHandler { id: openHover }
            TapHandler { onTapped: root.launch() }
        }
    }
}
