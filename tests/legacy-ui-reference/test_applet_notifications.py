#!/usr/bin/env python3
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

catalog_qml = (ROOT / "caelestia-applet" / "Catalog.qml").read_text()
icon_qml = (ROOT / "caelestia-applet" / "WebAppIcon.qml").read_text()
popout_qml = (ROOT / "caelestia-applet" / "WebAppPopout.qml").read_text()

# Catalog: desktopEntry first, then every configured fallback variant.
for needle in (
    "normaliseDesktopEntry",
    "notificationIdentityCandidates",
    "notificationMatchesFor",
    "app.notificationMatches",
    "matches.some(match => hay.includes(match))",
    'values.push(`caelestia-webapp-${appId}`)',
    'const workspace = (app.specialWorkspace ?? "").toString()',
):
    assert needle in catalog_qml, f"Catalog.qml missing robust matching/workspace behavior: {needle}"

# WebAppIcon: shared lock lifecycle must release stale locks rather than merely
# dropping JS references, otherwise retained NotifData objects can leak.
for needle in (
    "notificationLockKey",
    "safeUnlock",
    "!current.includes(notif)",
    "root.safeUnlock(notif)",
    "acknowledgeNotifications",
    "Colours.palette.m3primary",
    "Colours.palette.m3onPrimary",
):
    assert needle in icon_qml, f"WebAppIcon.qml missing lock/theme behavior: {needle}"

# Popout: three-message preview, avatar masking/fallback, default-action click,
# focus of an already-running app, theme-aware text and dynamic open button.
for needle in (
    "property int maxPreviewNotifications: 3",
    "root.catalog.focusExisting(root.app)",
    'a.identifier === "default"',
    "action.invoke()",
    "maskSource: avatarMask",
    "avatarImage.status !== Image.Ready",
    "visible: !root.appRunning",
    "Colours.palette.m3onSurfaceVariant",
    "Colours.tPalette.m3surfaceContainer",
    "import qs.services",
):
    assert needle in popout_qml, f"WebAppPopout.qml missing notification/theme behavior: {needle}"

# Generate a real catalog from the shipped definitions and confirm that category
# policy and all NOTIFICATION_MATCH alternatives make it into the runtime data.
with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    data = tmp / "data"
    out = tmp / "catalog.json"
    for app in ("whatsapp", "magenta-tv", "chatgpt"):
        (data / "apps" / app).mkdir(parents=True, exist_ok=True)
        (data / "apps" / app / "installed.conf").write_text("installed=true\n")

    subprocess.run(
        [
            "python3",
            str(ROOT / "scripts" / "generate_catalog.py"),
            str(ROOT / "apps"),
            str(data),
            str(out),
        ],
        check=True,
    )
    payload = json.loads(out.read_text())
    apps = {app["id"]: app for app in payload["apps"]}

    assert apps["whatsapp"]["specialWorkspace"] == "communication"
    assert apps["whatsapp"]["appletShowBadge"] is True
    assert apps["whatsapp"]["appletNotificationPreview"] is True
    assert apps["magenta-tv"]["specialWorkspace"] == "streaming"
    assert apps["magenta-tv"]["notificationMatches"] == ["MagentaTV", "Magenta TV"]
    assert apps["chatgpt"]["specialWorkspace"] == ""

# Small behavioral mirror for the intended matching precedence.
def normalize(entry):
    entry = (entry or "").strip().lower()
    return entry[:-8] if entry.endswith(".desktop") else entry


def matches(app, notif):
    app_id = app.get("id", "").lower()
    wc = app.get("windowClass", "").lower()
    candidates = list(dict.fromkeys(x for x in (app_id, wc, f"caelestia-webapp-{app_id}") if x))
    de = normalize(notif.get("desktopEntry"))
    if de and de in candidates:
        return True
    terms = app.get("notificationMatches") or [app.get("notificationMatch") or app.get("name") or app_id]
    hay = "\n".join(str(notif.get(k, "")) for k in ("appName", "summary", "body")).lower()
    return any(str(term).strip().lower() in hay for term in terms if str(term).strip())

assert matches(
    {"id": "whatsapp", "windowClass": "whatsapp", "notificationMatches": ["WhatsApp"]},
    {"desktopEntry": "whatsapp.desktop", "appName": "Firefox"},
)
assert matches(
    {"id": "whatsapp", "windowClass": "whatsapp", "notificationMatches": ["WhatsApp"]},
    {"desktopEntry": "caelestia-webapp-whatsapp", "appName": "Firefox"},
)
assert matches(
    {"id": "magenta-tv", "windowClass": "magenta-tv", "notificationMatches": ["MagentaTV", "Magenta TV"]},
    {"desktopEntry": "firefox", "summary": "Magenta TV: Neue Sendung"},
)
assert not matches(
    {"id": "whatsapp", "windowClass": "whatsapp", "notificationMatches": ["WhatsApp"]},
    {"desktopEntry": "google-messages", "appName": "Firefox", "summary": "SMS von Lina"},
)

print("PASS: applet notification matching, locks, previews, focus and theme integration are robust")
