import QtQuick
import Quickshell.Wayland

// Generic live Wayland preview with an optional normalized crop rectangle.
// The source itself remains the full Toplevel Screencopy stream. Cropping is
// presentation-only: the capture is scaled and translated behind this clipped
// viewport so only the requested browser video region remains visible.
Item {
    id: root

    property var captureSource: null
    property var normalizedRect: ({})
    property var viewport: ({})
    property bool enabled: true
    property bool paintCursor: false

    // Keep the last valid crop briefly. Independent status-feed processes may
    // transiently miss a browser bridge sample; falling straight back to the
    // whole window causes a very visible flash of YouTube comments/sidebar.
    property var rememberedRect: ({})
    property var rememberedViewport: ({})
    property double rememberedAt: 0
    property int cropHoldMs: 6000

    readonly property bool incomingCropValid: Number(root.normalizedRect?.width ?? 0) > 0.01
        && Number(root.normalizedRect?.height ?? 0) > 0.01
        && Number(root.viewport?.width ?? 0) > 1
        && Number(root.viewport?.height ?? 0) > 1
    readonly property bool rememberedCropValid: Number(root.rememberedRect?.width ?? 0) > 0.01
        && Number(root.rememberedRect?.height ?? 0) > 0.01
        && Number(root.rememberedViewport?.width ?? 0) > 1
        && Number(root.rememberedViewport?.height ?? 0) > 1
        && (Date.now() - root.rememberedAt) < root.cropHoldMs
    readonly property var effectiveRect: root.incomingCropValid ? root.normalizedRect
        : (root.rememberedCropValid ? root.rememberedRect : ({}))
    readonly property var effectiveViewport: root.incomingCropValid ? root.viewport
        : (root.rememberedCropValid ? root.rememberedViewport : ({}))

    readonly property real cropX: Number(root.effectiveRect?.x ?? 0)
    readonly property real cropY: Number(root.effectiveRect?.y ?? 0)
    readonly property real cropWidth: Number(root.effectiveRect?.width ?? 0)
    readonly property real cropHeight: Number(root.effectiveRect?.height ?? 0)
    readonly property real viewportWidth: Number(root.effectiveViewport?.width ?? 0)
    readonly property real viewportHeight: Number(root.effectiveViewport?.height ?? 0)
    readonly property bool cropAvailable: root.cropWidth > 0.01
        && root.cropHeight > 0.01
        && root.viewportWidth > 1
        && root.viewportHeight > 1
    readonly property bool hasContent: captureLoader.item?.hasContent ?? false

    signal stopped()

    function rememberIncomingCrop() {
        if (!root.incomingCropValid)
            return;
        root.rememberedRect = root.normalizedRect;
        root.rememberedViewport = root.viewport;
        root.rememberedAt = Date.now();
    }

    onNormalizedRectChanged: root.rememberIncomingCrop()
    onViewportChanged: root.rememberIncomingCrop()
    Component.onCompleted: root.rememberIncomingCrop()

    Timer {
        interval: 1000
        repeat: true
        running: root.rememberedAt > 0
        onTriggered: {
            // Trigger re-evaluation of the age-dependent rememberedCropValid.
            if ((Date.now() - root.rememberedAt) >= root.cropHoldMs)
                root.rememberedAt = 0;
        }
    }

    clip: true

    function captureGeometry(targetWidth, targetHeight) {
        if (!root.cropAvailable || targetWidth <= 0 || targetHeight <= 0)
            return ({ x: 0, y: 0, width: targetWidth, height: targetHeight });

        // normalizedRect is measured against Firefox window.innerWidth/Height.
        // Reconstruct CSS-pixel coordinates first, then use one uniform scale
        // for the complete viewport. This preserves aspect ratio while the
        // parent item's clip removes everything outside the <video> rectangle.
        const rx = root.cropX * root.viewportWidth;
        const ry = root.cropY * root.viewportHeight;
        const rw = Math.max(1, root.cropWidth * root.viewportWidth);
        const rh = Math.max(1, root.cropHeight * root.viewportHeight);
        const scale = Math.max(targetWidth / rw, targetHeight / rh);
        return ({
            x: (targetWidth - rw * scale) / 2 - rx * scale,
            y: (targetHeight - rh * scale) / 2 - ry * scale,
            width: root.viewportWidth * scale,
            height: root.viewportHeight * scale
        });
    }

    Loader {
        id: captureLoader
        anchors.fill: parent
        active: root.enabled && root.captureSource !== null

        sourceComponent: Component {
            Item {
                id: captureItem
                clip: true
                readonly property bool hasContent: capture.hasContent
                readonly property var geometry: root.captureGeometry(width, height)

                ScreencopyView {
                    id: capture
                    x: captureItem.geometry.x
                    y: captureItem.geometry.y
                    width: captureItem.geometry.width
                    height: captureItem.geometry.height
                    captureSource: root.captureSource
                    live: true
                    paintCursor: root.paintCursor
                    visible: hasContent
                    onStopped: root.stopped()

                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                }
            }
        }
    }
}
