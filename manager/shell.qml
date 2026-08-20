import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io
import "style" as Style

ShellRoot {
    id: root

    property string projectRoot: Quickshell.env("CAELESTIA_WEBAPPS_ROOT")
    property string homeDir: Quickshell.env("HOME")
    property string catalogPath: homeDir + "/.local/share/caelestia-webapps/catalog.json"
    property var catalogData: ({})
    property var apps: []
    property var categories: []
    property string selectedCategory: "featured"
    property string searchQuery: ""
    property string statusText: "Catalog wird geladen…"
    property bool catalogReady: false
    property bool catalogError: false
    property var runtimeByApp: ({})
    property bool runtimeStateAvailable: false
    property string runtimeStatusText: "Runtime wird geprüft…"
    property var appletEnabledByApp: ({})
    property bool appletStateAvailable: false
    property bool appletSettingsOpen: false
    property bool actionMenuOpen: false
    property string mainPage: "catalog"
    property var actionMenuApp: null
    property var appletSettingsApp: null
    property var appletSettingsItems: []
    property bool appletSettingsBusy: false
    property string appletSettingsError: ""
    property bool actionBusy: false
    property string actionCommand: ""
    property string actionAppId: ""
    property string actionStatusText: ""
    property bool actionError: false
    property var pendingUninstallApp: null
    property bool removeFromCatalogAfterUninstall: false
    property bool chainedCatalogRemoval: false
    property bool continuationScheduled: false
    property bool wizardOpen: false
    property bool wizardEditing: false
    property string wizardEditingId: ""
    property string wizardName: ""
    property string wizardId: ""
    property string wizardUrl: ""
    property string wizardCategory: "ai"
    property string wizardIconMode: "auto"
    property string wizardIconUrl: ""
    property string wizardIconFile: ""
    property string wizardAutoIconId: ""
    property string wizardError: ""
    property string startupStage: "boot"
    property string startupLabel: "Caelestia WebApps"
    property string startupDetail: "Manager wird vorbereitet"
    property real startupProgress: 0.02
    property bool startupReady: false
    property bool startupError: false
    property bool startupPreflightDone: false
    property bool startupCatalogDone: false
    property bool startupAppletDone: false

    function consumeStartup(line) {
        const value = String(line ?? "").trim()
        if (value.length === 0)
            return
        try {
            const event = JSON.parse(value)
            root.startupStage = event.stage || root.startupStage
            root.startupLabel = event.label || root.startupLabel
            root.startupDetail = event.detail || root.startupDetail
            if (typeof event.progress === "number")
                root.startupProgress = Math.max(root.startupProgress, Math.min(1.0, event.progress))
            if (event.state === "error")
                root.startupError = true
            if (event.stage === "ready") {
                root.startupPreflightDone = true
                root.startupStage = "catalog-load"
                root.startupLabel = "WebApp Katalog"
                root.startupDetail = "Katalogdaten werden geladen"
                root.startupProgress = Math.max(root.startupProgress, 0.97)
                root.refreshCatalog()
            }
        } catch (e) {
            // Startup diagnostics must never take the Manager down.
        }
    }

    function normalized(value) {
        return String(value ?? "").toLowerCase()
    }

    function categoryLabel(id) {
        if (id === "featured")
            return "Featured"
        if (id === "all")
            return "Alle"
        if (id === "installed")
            return "Installiert"
        for (let i = 0; i < categories.length; ++i) {
            if (categories[i].id === id)
                return categories[i].label
        }
        return id
    }

    function categoryDescription(id) {
        const descriptions = ({
            "featured": "Empfohlene WebApps",
            "all": "Vollständiger Katalog",
            "installed": "Lokal eingerichtete WebApps",
            "ai": "Assistenten und KI-Werkzeuge",
            "messaging": "Chats und Kommunikation",
            "google": "Google Dienste",
            "microsoft": "Microsoft Dienste",
            "proton": "Proton Dienste",
            "productivity": "Arbeit und Organisation",
            "social": "Soziale Netzwerke",
            "video": "Video und Streaming",
            "music": "Musik und Audio",
            "development": "Entwicklung und Code",
            "design": "Design und Kreativität",
            "cloud": "Cloud und Dateien",
            "shopping": "Shopping und Handel",
            "travel": "Reisen und Mobilität"
        })
        return descriptions[id] || "WebApps in dieser Kategorie"
    }

    function categoryIcon(id) {
        const icons = ({
            "featured": "\ue838",
            "all": "\ue5c3",
            "installed": "\ue2c4",
            "ai": "\uf1d0",
            "messaging": "\ue0b7",
            "google": "\ue8b6",
            "microsoft": "\ue5c3",
            "proton": "\ue8e8",
            "productivity": "\ue8f9",
            "social": "\ue7fb",
            "video": "\ue04b",
            "music": "\ue405",
            "development": "\ue86f",
            "design": "\ue40a",
            "cloud": "\ue2bd",
            "shopping": "\ue8cc",
            "travel": "\ue53d"
        })
        return icons[id] || "\ue5c3"
    }

    function categoryCount(id) {
        if (id === "installed")
            return apps.filter(function(app) { return app.installed }).length
        if (id === "featured")
            return apps.filter(function(app) { return app.featured === true }).length
        if (id === "all")
            return apps.length
        const category = categories.find(function(item) { return item.id === id })
        return category ? category.count : 0
    }

    function selectCategory(id, direction) {
        if (root.mainPage !== "catalog") {
            root.mainPage = "catalog"
            root.actionMenuOpen = false
            root.wizardOpen = false
            root.appletSettingsOpen = false
        }
        if (root.selectedCategory === id)
            return
        contentSwitch.complete()
        contentPane.opacity = 0
        contentTranslate.y = (direction || 1) * Style.Tokens.space2xl
        root.selectedCategory = id
        scroll.contentY = 0
        contentSwitch.restart()
    }

    function visibleApps() {
        const query = normalized(searchQuery).trim()
        return apps.filter(function(app) {
            const appCategories = app.categories || [app.category]
            const categoryOk = selectedCategory === "all"
                || (selectedCategory === "featured" && app.featured === true)
                || (selectedCategory === "installed" && app.installed === true)
                || appCategories.includes(selectedCategory)
            if (!categoryOk)
                return false
            if (query.length === 0)
                return true
            const haystack = [
                app.name,
                app.id,
                app.genericName,
                app.comment,
                app.category,
                root.categoryLabel(app.category)
            ].map(root.normalized).join(" ")
            return haystack.includes(query)
        })
    }

    function iconSource(app) {
        if (app.source === "user" && (app.iconLocal ?? "").length > 0)
            return "file://" + app.iconLocal
        if ((app.iconStore ?? "").length > 0)
            return "file://" + app.iconStore
        if (app.installed && (app.icon ?? "").length > 0)
            return "file://" + app.icon
        if (app.source === "user" && (app.iconUrl ?? "").length > 0)
            return app.iconUrl
        if ((app.iconLocal ?? "").length > 0)
            return "file://" + app.iconLocal
        return ""
    }

    function wizardIconPreview() {
        if (root.wizardIconMode === "local") return root.wizardIconFile
        if (root.wizardIconMode === "url") return root.wizardIconUrl
        if (root.wizardAutoIconId.trim().length === 0) return ""
        return "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/" + root.wizardAutoIconId.trim() + ".svg"
    }

    function consumeCatalog(text) {
        try {
            const payload = JSON.parse(String(text ?? "").trim())
            if (payload.apiVersion !== 1 || payload.ok !== true || payload.command !== "list")
                throw new Error("Unerwartete Catalog-Antwort")
            const parsed = payload.data || ({})
            if (parsed.schemaVersion !== 2)
                throw new Error("Unerwartete Catalog-Version: " + parsed.schemaVersion)
            catalogData = parsed
            apps = parsed.apps || []
            categories = parsed.categories || []
            catalogReady = true
            catalogError = false
            statusText = apps.length + " WebApps geladen"
            if (!root.startupReady) {
                root.startupCatalogDone = true
                root.startupLabel = "Applet Status"
                root.startupDetail = "Applet-Aktivierungen werden geladen"
                root.startupProgress = Math.max(root.startupProgress, 0.985)
                root.refreshAppletState()
                root.maybeFinishStartup()
            }
        } catch (e) {
            catalogData = ({})
            apps = []
            categories = []
            catalogReady = false
            catalogError = true
            statusText = "Catalog konnte nicht gelesen werden: " + e
            if (!root.startupReady) {
                root.startupError = true
                root.startupLabel = "Start fehlgeschlagen"
                root.startupDetail = "Katalog konnte nicht über die CLI geladen werden"
                root.startupProgress = 1.0
            }
        }
    }

    function refreshCatalog() {
        if (!catalogProcess.running)
            catalogProcess.running = true
    }

    function maybeFinishStartup() {
        if (root.startupReady || root.startupError)
            return
        if (root.startupPreflightDone && root.startupCatalogDone && root.startupAppletDone) {
            root.startupStage = "ready"
            root.startupLabel = "WebApps Manager"
            root.startupDetail = "Bereit"
            root.startupProgress = 1.0
            startupFinishDelay.restart()
        }
    }

    function appRunning(appId) {
        const state = runtimeByApp[appId]
        return state !== undefined && state !== null && state.running === true
    }

    function appletEnabled(appId) {
        return root.appletEnabledByApp[appId] === true
    }

    function consumeAppletState(text) {
        try {
            const payload = JSON.parse(text)
            if (payload.apiVersion !== 1 || payload.ok !== true || payload.command !== "applet-state")
                throw new Error("Unerwartete Applet-State-Antwort")
            const next = ({})
            const items = payload.data?.apps ?? []
            for (let i = 0; i < items.length; ++i) {
                const item = items[i]
                if (item && item.appId)
                    next[item.appId] = item.enabled === true
            }
            root.appletEnabledByApp = next
            root.appletStateAvailable = true
            if (!root.startupReady && root.startupPreflightDone) {
                root.startupAppletDone = true
                root.maybeFinishStartup()
            }
        } catch (e) {
            root.appletStateAvailable = false
            if (!root.startupReady && root.startupPreflightDone) {
                root.startupError = true
                root.startupLabel = "Start fehlgeschlagen"
                root.startupDetail = "Applet-Status konnte nicht gelesen werden"
                root.startupProgress = 1.0
            }
        }
    }

    function refreshAppletState() {
        if (!appletStateProcess.running)
            appletStateProcess.running = true
    }

    function capabilityLabel(name) {
        const labels = ({
            "notifications": "Benachrichtigungen",
            "badge": "Badge",
            "preview": "Vorschau",
            "now_playing": "Now Playing",
            "playback_controls": "Wiedergabesteuerung",
            "live_preview": "Live-Vorschau",
            "video_crop": "Video-Zuschnitt",
            "pin": "Anheften",
            "artwork": "Cover / Artwork"
        })
        return labels[name] || name
    }

    function capabilityDescription(name) {
        const descriptions = ({
            "notifications": "Benachrichtigungsstatus im Applet anzeigen",
            "badge": "Anzahl neuer Ereignisse am Bar-Icon anzeigen",
            "preview": "Benachrichtigungsinhalte im Popout anzeigen",
            "now_playing": "Aktuelle Medieninformationen im Popout anzeigen",
            "playback_controls": "Zurück, Play/Pause und Weiter anzeigen",
            "live_preview": "Livebild des Video-Fensters verwenden",
            "video_crop": "Livebild automatisch auf den Videobereich zuschneiden",
            "pin": "Anheften des Medien-Popouts erlauben",
            "artwork": "Cover- bzw. Artwork-Bild anzeigen"
        })
        return descriptions[name] || "Capability aktivieren oder deaktivieren"
    }

    function openActionMenu(app) {
        if (!app)
            return
        root.actionMenuApp = app
        root.actionMenuOpen = true
        root.mainPage = "actions"
    }

    function closeActionMenu() {
        root.actionMenuOpen = false
        root.mainPage = "catalog"
    }

    function actionMenuEntries() {
        const app = root.actionMenuApp
        if (!app)
            return []
        const entries = []
        if (app.installed === true && app.applet?.available === true && app.applet?.support === "supported")
            entries.push({ id: "applet-settings", title: "Applet-Einstellungen", description: "Funktionen wie Badge, Vorschau oder Wiedergabesteuerung konfigurieren.", label: "Öffnen", danger: false })
        if (app.installed === true) {
            entries.push({ id: "setup", title: "Firefox-Profil & Berechtigungen", description: "WebApp-Profil erneut einrichten und benötigte Firefox-Berechtigungen vorbereiten.", label: "Einrichten", danger: false })
            entries.push({ id: "repair", title: "WebApp reparieren", description: "Installation prüfen und verwaltete Dateien sowie Metadaten erneut herstellen.", label: "Reparieren", danger: false })
        }
        if (app.source === "user")
            entries.push({ id: "edit", title: "Eigene WebApp bearbeiten", description: "Name, URL, Kategorie und Icon der eigenen WebApp ändern.", label: "Bearbeiten", danger: false })
        entries.push({
            id: "remove",
            title: app.installed === true ? "WebApp deinstallieren" : "Aus dem Katalog entfernen",
            description: app.installed === true ? "Die installierte WebApp nach einer Bestätigung entfernen." : "Diese eigene WebApp aus dem lokalen Katalog entfernen.",
            label: app.installed === true ? "Deinstallieren" : "Entfernen",
            danger: true
        })
        return entries
    }

    function runActionMenuEntry(entry) {
        const app = root.actionMenuApp
        if (!app || !entry)
            return
        root.closeActionMenu()
        if (entry.id === "applet-settings")
            root.openAppletSettings(app)
        else if (entry.id === "edit")
            root.openEditWizard(app)
        else if (entry.id === "remove")
            root.requestUninstall(app)
        else if (entry.id === "setup")
            root.runAction("setup", app)
        else if (entry.id === "repair")
            root.runAction("repair", app)
    }

    function openAppletSettings(app) {
        root.appletSettingsApp = app
        root.appletSettingsItems = []
        root.appletSettingsError = ""
        root.appletSettingsOpen = true
        root.mainPage = "applet-settings"
        root.appletSettingsBusy = true
        appletSettingsProcess.command = [root.projectRoot + "/bin/caelestia-webapps", "applet-settings", app.id]
        appletSettingsProcess.running = true
    }

    function closeAppletSettings() {
        if (root.appletSettingsBusy)
            return
        root.appletSettingsOpen = false
        root.appletSettingsItems = []
        root.appletSettingsError = ""
        root.actionMenuApp = root.appletSettingsApp
        root.actionMenuOpen = root.actionMenuApp !== null
        root.mainPage = root.actionMenuOpen ? "actions" : "catalog"
    }

    function consumeAppletSettings(text) {
        try {
            const payload = JSON.parse(text)
            if (payload.apiVersion !== 1 || payload.ok !== true || payload.command !== "applet-settings")
                throw new Error("Unerwartete Applet-Settings-Antwort")
            const app = payload.data?.apps?.[0] ?? null
            if (!app || !root.appletSettingsApp || app.appId !== root.appletSettingsApp.id)
                throw new Error("Applet-Settings fehlen")
            const values = app.settings || ({})
            root.appletSettingsItems = (app.capabilities || []).map(function(cap) {
                return ({ name: cap, enabled: values[cap] !== false })
            })
            root.appletSettingsError = ""
        } catch (e) {
            root.appletSettingsError = "Applet-Einstellungen konnten nicht gelesen werden."
        }
        root.appletSettingsBusy = false
    }

    function toggleAppletCapability(capability, currentlyEnabled) {
        if (!root.appletSettingsApp || root.appletSettingsBusy)
            return
        root.appletSettingsBusy = true
        root.appletSettingsError = ""
        appletSettingSetProcess.command = [
            root.projectRoot + "/bin/caelestia-webapps",
            "applet-setting-set",
            root.appletSettingsApp.id,
            capability,
            currentlyEnabled ? "off" : "on"
        ]
        appletSettingSetProcess.running = true
    }

    function consumeRuntime(text) {
        try {
            const payload = JSON.parse(text)
            if (payload.apiVersion !== 1 || payload.ok !== true || payload.command !== "runtime")
                throw new Error("Unerwartete Runtime-Antwort")
            const data = payload.data || ({})
            runtimeByApp = data.apps || ({})
            runtimeStateAvailable = data.runtimeAvailable === true
            runtimeStatusText = runtimeStateAvailable ? "Runtime live" : "Runtime nicht verfügbar"
        } catch (e) {
            runtimeByApp = ({})
            runtimeStateAvailable = false
            runtimeStatusText = "Runtime-Status konnte nicht gelesen werden"
        }
    }

    function refreshRuntimeSoon() {
        if (!runtimeRefreshDelay.running)
            runtimeRefreshDelay.start()
    }

    function slugify(text) {
        return text.toLowerCase()
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/^-+|-+$/g, "")
    }

    function openCreateWizard() {
        if (root.actionBusy)
            return
        root.wizardEditing = false
        root.wizardEditingId = ""
        root.wizardName = ""
        root.wizardId = ""
        root.wizardUrl = ""
        root.wizardCategory = root.categories.length > 0 ? root.categories[0].id : "ai"
        root.wizardIconMode = "auto"
        root.wizardIconUrl = ""
        root.wizardIconFile = ""
        root.wizardAutoIconId = ""
        root.wizardError = ""
        root.wizardOpen = true
        root.mainPage = "wizard"
        wizardFocusTimer.restart()
    }

    function openEditWizard(app) {
        if (root.actionBusy || !app || app.source !== "user")
            return
        root.wizardEditing = true
        root.wizardEditingId = app.id
        root.wizardName = app.name
        root.wizardId = app.id
        root.wizardUrl = app.url
        root.wizardCategory = app.category
        root.wizardIconMode = app.iconMode || ((app.iconLocal || "").length > 0 ? "local" : "url")
        root.wizardIconUrl = app.iconUrl || ""
        root.wizardIconFile = (app.iconLocal || "").length > 0 ? "file://" + app.iconLocal : ""
        root.wizardAutoIconId = app.id
        root.wizardError = ""
        root.wizardOpen = true
        root.mainPage = "wizard"
        wizardFocusTimer.restart()
    }

    function closeWizard() {
        if (root.actionBusy)
            return
        root.wizardOpen = false
        root.wizardError = ""
        if (root.wizardEditing && root.actionMenuApp) {
            root.actionMenuOpen = true
            root.mainPage = "actions"
        } else {
            root.mainPage = "catalog"
        }
    }

    function submitWizard() {
        if (root.actionBusy)
            return

        const id = root.wizardEditing ? root.wizardEditingId : root.wizardId.trim()
        if (root.wizardName.trim().length === 0) {
            root.wizardError = "Name darf nicht leer sein."
            return
        }
        if (id.length === 0) {
            root.wizardError = "App-ID darf nicht leer sein."
            return
        }
        if (!/^https?:\/\/.+/.test(root.wizardUrl.trim())) {
            root.wizardError = "Bitte eine vollständige http(s)-URL eingeben."
            return
        }

        const payload = JSON.stringify({
            "id": id,
            "name": root.wizardName.trim(),
            "url": root.wizardUrl.trim(),
            "category": root.wizardCategory,
            "iconMode": root.wizardIconMode,
            "iconUrl": root.wizardIconUrl.trim(),
            "iconFile": root.wizardIconFile,
            "genericName": "Web Application",
            "comment": root.wizardName.trim(),
            "notificationMatch": root.wizardName.trim()
        })

        root.actionBusy = true
        root.actionCommand = root.wizardEditing ? "user-update" : "user-create"
        root.actionAppId = id
        root.actionError = false
        root.actionStatusText = root.wizardEditing
            ? "WebApp wird aktualisiert…"
            : "WebApp wird angelegt…"
        actionProcess.command = root.wizardEditing
            ? [root.projectRoot + "/bin/caelestia-webapps", "user-update", root.wizardEditingId, payload]
            : [root.projectRoot + "/bin/caelestia-webapps", "user-create", payload]
        actionProcess.running = true
    }

    function commandLabel(command) {
        const labels = {
            "launch": "Öffnen",
            "setup": "Setup",
            "install": "Installieren",
            "repair": "Reparieren",
            "uninstall": "Deinstallieren",
            "uninstall-close": "Schließen & deinstallieren",
            "applet-set": "Applet",
            "user-create": "Anlegen",
            "user-update": "Speichern",
            "user-delete": "Aus Katalog entfernen"
        }
        return labels[command] || command
    }

    function runAction(command, app) {
        if (root.actionBusy || !app || !app.id)
            return

        if (command === "launch") {
            if (!app.installed)
                return
            Quickshell.execDetached([root.projectRoot + "/bin/caelestia-webapps", "launch", app.id])
            root.actionStatusText = root.appRunning(app.id)
                ? app.name + " wird fokussiert…"
                : app.name + " wird geöffnet…"
            root.actionError = false
            root.refreshRuntimeSoon()
            actionNoticeTimer.restart()
            return
        }

        root.actionBusy = true
        root.actionCommand = command
        root.actionAppId = app.id
        root.actionError = false
        root.actionStatusText = root.commandLabel(command) + ": " + app.name + "…"
        actionProcess.command = [root.projectRoot + "/bin/caelestia-webapps", command, app.id]
        actionProcess.running = true
    }

    function toggleApplet(app) {
        if (root.actionBusy || !app || !app.id || !app.installed)
            return
        if (app.applet?.available !== true || app.applet?.support !== "supported")
            return
        const enabled = !root.appletEnabled(app.id)
        root.actionBusy = true
        root.actionCommand = "applet-set"
        root.actionAppId = app.id
        root.actionError = false
        root.actionStatusText = (enabled ? "Applet aktivieren: " : "Applet deaktivieren: ") + app.name + "…"
        actionProcess.command = [
            root.projectRoot + "/bin/caelestia-webapps",
            "applet-set",
            app.id,
            enabled ? "on" : "off"
        ]
        actionProcess.running = true
    }

    function consumeAction(text) {
        try {
            const payload = JSON.parse(text)
            const expected = root.actionCommand
            if (payload.apiVersion !== 1 || payload.command !== expected)
                throw new Error("Unerwartete API-Antwort")

            if (payload.ok === true) {
                const app = root.apps.find(function(candidate) {
                    return candidate.id === root.actionAppId
                })
                const name = app ? app.name : root.actionAppId
                root.actionStatusText = root.commandLabel(expected) + " abgeschlossen: " + name
                root.actionError = false
                if (expected === "applet-set") {
                    const next = Object.assign({}, root.appletEnabledByApp)
                    next[root.actionAppId] = payload.data?.enabled === true
                    root.appletEnabledByApp = next
                    root.appletStateAvailable = true
                    root.actionStatusText = (payload.data?.enabled === true ? "Applet aktiviert: " : "Applet deaktiviert: ") + name
                }
                if (expected === "user-create" || expected === "user-update") {
                    root.wizardOpen = false
                    root.wizardError = ""
                    root.actionMenuOpen = false
                    root.mainPage = "catalog"
                }

                if ((expected === "uninstall" || expected === "uninstall-close")
                        && root.chainedCatalogRemoval) {
                    root.chainedCatalogRemoval = false
                    root.continuationScheduled = true
                    root.actionCommand = "user-delete"
                    root.actionStatusText = "Aus Katalog entfernen: " + name + "…"
                    actionProcess.command = [
                        root.projectRoot + "/bin/caelestia-webapps",
                        "user-delete",
                        root.actionAppId
                    ]
                    Qt.callLater(function() {
                        actionProcess.running = true
                    })
                    return
                }
            } else {
                const error = payload.error || ({})
                root.actionStatusText = error.message || (root.commandLabel(expected) + " fehlgeschlagen")
                root.actionError = true
                if (expected === "user-create" || expected === "user-update")
                    root.wizardError = root.actionStatusText
            }
        } catch (e) {
            root.actionStatusText = "Ungültige Antwort der WebApps-API"
            root.actionError = true
        }
    }

    function finishAction() {
        if (root.continuationScheduled) {
            root.continuationScheduled = false
            return
        }

        root.actionBusy = false
        root.chainedCatalogRemoval = false
        root.refreshCatalog()
        root.refreshRuntimeSoon()
        root.refreshAppletState()
        actionNoticeTimer.restart()
    }

    function requestUninstall(app) {
        if (root.actionBusy)
            return
        root.removeFromCatalogAfterUninstall = false
        root.pendingUninstallApp = app
    }

    function cancelUninstall() {
        root.pendingUninstallApp = null
        root.removeFromCatalogAfterUninstall = false
    }

    function confirmUninstall() {
        const app = root.pendingUninstallApp
        root.pendingUninstallApp = null
        if (!app)
            return

        if (!app.installed && app.source === "user") {
            root.removeFromCatalogAfterUninstall = false
            root.runAction("user-delete", app)
            return
        }

        root.chainedCatalogRemoval = app.source === "user"
            && root.removeFromCatalogAfterUninstall
        root.removeFromCatalogAfterUninstall = false
        root.runAction(root.appRunning(app.id) ? "uninstall-close" : "uninstall", app)
    }

    Process {
        id: catalogProcess
        command: [root.projectRoot + "/bin/caelestia-webapps", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.consumeCatalog(text)
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.catalogReady = false
                root.catalogError = true
                if (!root.startupReady) {
                    root.startupError = true
                    root.startupLabel = "Start fehlgeschlagen"
                    root.startupDetail = "Katalog-CLI konnte nicht abgeschlossen werden"
                    root.startupProgress = 1.0
                }
            }
        }
    }

    Process {
        id: startupProcess
        command: [root.projectRoot + "/scripts/manager_preflight.sh"]
        running: true
        stdout: SplitParser {
            onRead: data => root.consumeStartup(data)
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.startupError = true
                root.startupLabel = "Start fehlgeschlagen"
                root.startupDetail = "Preflight konnte nicht abgeschlossen werden"
                root.startupProgress = 1.0
            }
        }
    }

    Timer {
        id: startupFinishDelay
        // Give the compositor one stable frame to present the completed
        // startup surface before handing over to the main manager window.
        interval: 500
        repeat: false
        onTriggered: root.startupReady = true
    }

    FileDialog {
        id: iconFileDialog
        title: "WebApp-Icon auswählen"
        nameFilters: ["Icons (*.svg *.png)"]
        onAccepted: { root.wizardIconFile = selectedFile.toString(); root.wizardIconMode = "local" }
    }

    Process {
        id: runtimeProcess
        command: [root.projectRoot + "/bin/caelestia-webapps", "runtime"]
        stdout: StdioCollector {
            onStreamFinished: root.consumeRuntime(text)
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.runtimeByApp = ({})
                root.runtimeStateAvailable = false
                root.runtimeStatusText = "Runtime-Abfrage fehlgeschlagen"
            }
        }
    }

    Process {
        id: appletStateProcess
        command: [root.projectRoot + "/bin/caelestia-webapps", "applet-state"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: root.consumeAppletState(text)
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.appletStateAvailable = false
                if (!root.startupReady && root.startupPreflightDone) {
                    root.startupError = true
                    root.startupLabel = "Start fehlgeschlagen"
                    root.startupDetail = "Applet-Status konnte nicht geladen werden"
                    root.startupProgress = 1.0
                }
            }
        }
    }

    Process {
        id: appletSettingsProcess
        stdout: StdioCollector {
            onStreamFinished: root.consumeAppletSettings(text)
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.appletSettingsBusy = false
                root.appletSettingsError = "Applet-Einstellungen konnten nicht geladen werden."
            }
        }
    }

    Process {
        id: appletSettingSetProcess
        stdout: StdioCollector {
            onStreamFinished: {
                // Reload through the read command so the UI always reflects
                // persisted state rather than optimistic local state.
            }
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0) {
                root.appletSettingsBusy = false
                root.appletSettingsError = "Applet-Einstellung konnte nicht gespeichert werden."
                return
            }
            if (root.appletSettingsApp) {
                appletSettingsProcess.command = [root.projectRoot + "/bin/caelestia-webapps", "applet-settings", root.appletSettingsApp.id]
                appletSettingsProcess.running = true
            }
        }
    }

    Process {
        id: actionProcess
        stdout: StdioCollector {
            onStreamFinished: root.consumeAction(text)
        }
        onExited: function(exitCode, exitStatus) {
            if (exitCode !== 0 && !root.actionError) {
                root.actionStatusText = root.commandLabel(root.actionCommand) + " fehlgeschlagen"
                root.actionError = true
            }
            root.finishAction()
        }
    }

    Timer {
        id: actionNoticeTimer
        interval: 4500
        repeat: false
        onTriggered: {
            if (!root.actionBusy) {
                root.actionStatusText = ""
                root.actionError = false
            }
        }
    }

    Timer {
        id: wizardFocusTimer
        interval: 0
        repeat: false
        onTriggered: wizardName.forceActiveFocus()
    }

    Timer {
        interval: 1500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!runtimeProcess.running)
                runtimeProcess.running = true
        }
    }

    Timer {
        id: runtimeRefreshDelay
        interval: 350
        repeat: false
        onTriggered: {
            if (!runtimeProcess.running)
                runtimeProcess.running = true
        }
    }

    FloatingWindow {
        id: startupWindow
        visible: !root.startupReady
        title: "Caelestia WebApps"
        implicitWidth: 590
        implicitHeight: 188
        minimumSize.width: 590
        minimumSize.height: 188
        maximumSize.width: 590
        maximumSize.height: 188
        color: Style.Theme.background

        Rectangle {
            anchors.fill: parent
            color: Style.Theme.background

            // Compact Caelestia-like top-bar surface. The palette comes from
            // the public scheme bridge; shape/motion are standalone tokens.
            Rectangle {
                id: startupBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                height: 54
                radius: 20
                color: Style.Theme.toolbarSurface
                border.width: 1
                border.color: Style.Theme.toolbarBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: Style.Tokens.spaceLg

                    Rectangle {
                        implicitWidth: 34
                        implicitHeight: 34
                        radius: 17
                        color: Style.Theme.categoryActive
                        border.width: 1
                        border.color: Style.Theme.categoryBorder

                        Text {
                            anchors.centerIn: parent
                            text: "\ue30a"
                            color: Style.Theme.primary
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 20
                            font.weight: Font.Medium
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "Caelestia WebApps"
                            color: Style.Theme.textPrimary
                            font.pixelSize: Style.Tokens.fontSubtitle
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: root.startupLabel
                            color: root.startupError ? Style.Theme.error : Style.Theme.accentText
                            font.pixelSize: Style.Tokens.fontBodySmall
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        implicitWidth: progressText.implicitWidth + 18
                        implicitHeight: 28
                        radius: 14
                        color: Style.Theme.categoryActive
                        Text {
                            id: progressText
                            anchors.centerIn: parent
                            text: Math.round(root.startupProgress * 100) + "%"
                            color: Style.Theme.accentText
                            font.pixelSize: Style.Tokens.fontBodySmall
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: startupBar.bottom
                anchors.bottom: parent.bottom
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                anchors.topMargin: 18
                anchors.bottomMargin: 18
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: root.startupDetail
                    color: root.startupError ? Style.Theme.error : Style.Theme.textSecondary
                    font.pixelSize: Style.Tokens.fontBody
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 8
                    radius: 4
                    color: Style.Theme.surfaceRaised
                    clip: true

                    Rectangle {
                        width: parent.width * root.startupProgress
                        height: parent.height
                        radius: parent.radius
                        color: root.startupError ? Style.Theme.error : Style.Theme.primary
                        Behavior on width {
                            NumberAnimation { duration: Style.Tokens.motionEmphasized; easing.type: Easing.OutCubic }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: root.startupError
                            ? "Bitte Manager aus einem Terminal starten und Log prüfen."
                            : "Theme · Icons · Katalog · Runtime"
                        color: Style.Theme.textMuted
                        font.pixelSize: Style.Tokens.fontLabel
                    }
                    Text {
                        text: Style.Theme.caelestiaThemeAvailable ? "Caelestia Theme" : "Theme wird geladen"
                        color: Style.Theme.hint
                        font.pixelSize: Style.Tokens.fontLabel
                    }
                }
            }
        }
    }

    FloatingWindow {
        id: window
        visible: root.startupReady
        title: "Caelestia WebApps"
        implicitWidth: 1180
        implicitHeight: 760
        minimumSize.width: 920
        minimumSize.height: 600
        color: Style.Theme.background

        onVisibleChanged: {
            if (!visible)
                Qt.quit()
        }

        Shortcut {
            sequence: "Ctrl+Q"
            onActivated: Qt.quit()
        }

        Shortcut {
            sequence: "Ctrl+F"
            onActivated: managerSearch.forceSearchFocus()
        }

        Shortcut {
            sequence: "Escape"
            enabled: root.pendingUninstallApp !== null
            onActivated: root.cancelUninstall()
        }

        Shortcut {
            sequence: "Escape"
            enabled: root.wizardOpen && root.pendingUninstallApp === null && !root.appletSettingsOpen
            onActivated: root.closeWizard()
        }

        Shortcut {
            sequence: "Escape"
            enabled: root.actionMenuOpen && root.pendingUninstallApp === null && !root.wizardOpen && !root.appletSettingsOpen
            onActivated: root.closeActionMenu()
        }

        Shortcut {
            sequence: "Escape"
            enabled: root.appletSettingsOpen && root.pendingUninstallApp === null && !root.wizardOpen && !root.actionMenuOpen
            onActivated: root.closeAppletSettings()
        }

        Rectangle {
            anchors.fill: parent
            color: Style.Theme.navigationSurface

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: Math.min(Style.Tokens.navigationWidth, window.width * 0.34)
                    Layout.fillHeight: true
                    radius: Style.Tokens.radiusMainSurface
                    color: Style.Theme.navigationSurface

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: Style.Tokens.space2xl

                        Style.SearchField {
                            id: managerSearch
                            Layout.fillWidth: true
                            text: root.searchQuery
                            placeholderText: "WebApps durchsuchen…"
                            onChanged: function(value) { root.searchQuery = value }
                        }

                        Flickable {
                            id: navigationScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentHeight: navigationColumn.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: navigationColumn
                                width: navigationScroll.width
                                spacing: Style.Tokens.spaceXs

                                Repeater {
                                    model: [
                                        { id: "featured", label: "Featured" },
                                        { id: "all", label: "Alle WebApps" },
                                        { id: "installed", label: "Installiert" }
                                    ]

                                    delegate: Style.NavigationItem {
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        label: modelData.label
                                        description: root.categoryCount(modelData.id) + " · " + root.categoryDescription(modelData.id)
                                        icon: root.categoryIcon(modelData.id)
                                        selected: root.selectedCategory === modelData.id
                                        firstInGroup: index === 0
                                        lastInGroup: index === 2
                                        onClicked: root.selectCategory(modelData.id, 1)
                                    }
                                }

                                Item { Layout.preferredHeight: Style.Tokens.spaceMd }

                                Repeater {
                                    model: root.categories

                                    delegate: Style.NavigationItem {
                                        required property var modelData
                                        required property int index
                                        Layout.fillWidth: true
                                        label: modelData.label
                                        description: modelData.count + " · " + root.categoryDescription(modelData.id)
                                        icon: root.categoryIcon(modelData.id)
                                        selected: root.selectedCategory === modelData.id
                                        firstInGroup: index === 0
                                        lastInGroup: index === root.categories.length - 1
                                        onClicked: root.selectCategory(modelData.id, 1)
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.Tokens.spaceMd

                            Style.IconButton {
                                icon: "\ue40a"
                                active: Style.Theme.caelestiaThemeAvailable
                                interactive: false
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text { text: "Caelestia WebApps"; color: Style.Theme.textPrimary; font.pixelSize: Style.Tokens.fontBody; font.weight: Font.DemiBold }
                                Text { text: root.runtimeStatusText; color: Style.Theme.textMuted; font.pixelSize: Style.Tokens.fontLabel }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Style.Tokens.radiusMainSurface
                    color: Style.Theme.mainSurface
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 26
                        spacing: Style.Tokens.space2xl

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.Tokens.spaceXl

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Style.Tokens.spaceXxs

                                Text {
                                    text: root.categoryLabel(root.selectedCategory)
                                    color: Style.Theme.textPrimaryAlt
                                    font.pixelSize: Style.Tokens.fontDisplay
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: root.actionStatusText.length > 0
                                        ? root.actionStatusText
                                        : root.categoryCount(root.selectedCategory) + " WebApps · " + root.categoryDescription(root.selectedCategory)
                                    color: (root.catalogError || root.actionError) ? Style.Theme.error
                                        : (root.actionBusy ? Style.Theme.accentText : Style.Theme.statusIdle)
                                    font.pixelSize: Style.Tokens.fontBody
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                visible: root.actionBusy
                                implicitWidth: busyText.implicitWidth + 24
                                implicitHeight: Style.Tokens.controlHeightCompact
                                radius: Style.Tokens.radiusControl
                                color: Style.Theme.toolbarSurface

                                Text {
                                    id: busyText
                                    anchors.centerIn: parent
                                    text: "●  " + root.commandLabel(root.actionCommand)
                                    color: Style.Theme.accentText
                                    font.pixelSize: Style.Tokens.fontBodySmall
                                    font.weight: Font.DemiBold
                                }
                            }

                            Style.ActionButton {
                                minimumWidth: 126
                                primary: true
                                icon: "\ue145"
                                label: "WebApp"
                                interactive: !root.actionBusy
                                onClicked: root.openCreateWizard()
                            }

                        }

                        Item {
                            id: contentPane
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            transform: Translate { id: contentTranslate }

                            Flickable {
                                id: scroll
                                anchors.fill: parent
                                clip: true
                                contentHeight: listColumn.implicitHeight
                                boundsBehavior: Flickable.StopAtBounds

                                ColumnLayout {
                                    id: listColumn
                                    width: scroll.width
                                    spacing: Style.Tokens.spaceXs

                                    Repeater {
                                        model: root.visibleApps()

                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            implicitHeight: Style.Tokens.appRowHeight
                                            radius: Style.Tokens.radiusLg
                                            color: Style.Theme.surfaceAlt

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 10
                                                spacing: Style.Tokens.spaceLg

                                                Rectangle {
                                                    implicitWidth: Style.Tokens.appIconSurface
                                                    implicitHeight: Style.Tokens.appIconSurface
                                                    radius: width / 2
                                                    color: Style.Theme.sourceSurface

                                                    Image {
                                                        anchors.centerIn: parent
                                                        width: Style.Tokens.appIconSize
                                                        height: Style.Tokens.appIconSize
                                                        source: root.iconSource(modelData)
                                                        fillMode: Image.PreserveAspectFit
                                                        asynchronous: true
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    Layout.minimumWidth: 110
                                                    spacing: Style.Tokens.spaceXxs

                                                    Text {
                                                        id: appNameText
                                                        text: modelData.name
                                                        color: Style.Theme.textPrimary
                                                        font.pixelSize: Style.Tokens.fontSubtitle
                                                        font.weight: Font.DemiBold
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }

                                                    Rectangle {
                                                        implicitWidth: sourceTypeContent.implicitWidth + 12
                                                        implicitHeight: Style.Tokens.sourceIconSize
                                                        radius: Style.Tokens.radiusSource
                                                        color: Style.Theme.sourceSurface
                                                        border.width: 1
                                                        border.color: modelData.source === "user" ? Style.Theme.userSourceBorder : Style.Theme.catalogSourceBorder

                                                        RowLayout {
                                                            id: sourceTypeContent
                                                            anchors.centerIn: parent
                                                            spacing: Style.Tokens.spaceXxs

                                                            Text {
                                                                text: modelData.source === "user" ? "\ue7fd" : "\ue865"
                                                                color: modelData.source === "user" ? Style.Theme.userSource : Style.Theme.textSecondary
                                                                font.family: "Material Symbols Rounded"
                                                                font.pixelSize: Style.Tokens.fontBodyLarge
                                                                font.weight: Font.Medium
                                                            }

                                                            Text {
                                                                text: modelData.source === "user" ? "Eigene App" : "Katalog-App"
                                                                color: Style.Theme.textSecondary
                                                                font.pixelSize: Style.Tokens.fontLabel
                                                            }
                                                        }
                                                    }

                                                    Text {
                                                        text: modelData.comment || modelData.genericName
                                                        color: Style.Theme.textSubtle
                                                        font.pixelSize: Style.Tokens.fontBodySmall
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }
                                                }

                                                Rectangle {
                                                    visible: modelData.installed && root.appRunning(modelData.id)
                                                    implicitWidth: 9
                                                    implicitHeight: 9
                                                    radius: Style.Tokens.radiusStatusDot
                                                    color: Style.Theme.running
                                                    border.width: 1
                                                    border.color: Style.Theme.runningBorder
                                                }

                                                RowLayout {
                                                    visible: modelData.installed
                                                    spacing: Style.Tokens.spaceXs

                                                    Style.ActionButton {
                                                        minimumWidth: root.appRunning(modelData.id) ? 108 : 86
                                                        primary: true
                                                        icon: root.appRunning(modelData.id) ? "\ue8a0" : "\ue89e"
                                                        label: root.appRunning(modelData.id) ? "Fokussieren" : "Öffnen"
                                                        interactive: !root.actionBusy
                                                        onClicked: root.runAction("launch", modelData)
                                                    }
                                                    Style.ActionButton {
                                                        visible: modelData.applet?.available === true && modelData.applet?.support === "supported"
                                                        minimumWidth: 82
                                                        label: root.appletEnabled(modelData.id) ? "Applet an" : "Applet aus"
                                                        interactive: !root.actionBusy && root.appletStateAvailable
                                                        onClicked: root.toggleApplet(modelData)
                                                    }
                                                    Style.ActionButton {
                                                        minimumWidth: 88
                                                        icon: "\ue5d3"
                                                        label: "Aktionen"
                                                        interactive: !root.actionBusy
                                                        onClicked: root.openActionMenu(modelData)
                                                    }
                                                }
                                                Style.ActionButton {
                                                    visible: !modelData.installed && modelData.source === "user"
                                                    minimumWidth: 88
                                                    icon: "\ue5d3"
                                                    label: "Aktionen"
                                                    interactive: !root.actionBusy
                                                    onClicked: root.openActionMenu(modelData)
                                                }
                                                Style.ActionButton {
                                                    visible: !modelData.installed
                                                    minimumWidth: 108
                                                    primary: true
                                                    icon: "\ue2c4"
                                                    label: root.actionBusy && root.actionAppId === modelData.id ? "Bitte warten…" : "Installieren"
                                                    interactive: !root.actionBusy
                                                    onClicked: root.runAction("install", modelData)
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        visible: root.catalogReady && root.visibleApps().length === 0
                                        Layout.fillWidth: true
                                        implicitHeight: Style.Tokens.emptyStateHeight
                                        color: "transparent"

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: Style.Tokens.spaceMd

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: root.searchQuery.length > 0 ? "\ue8b6" : "\ue5d5"
                                                color: Style.Theme.textDisabled
                                                font.family: "Material Symbols Rounded"
                                                font.pixelSize: 30
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: root.searchQuery.length > 0
                                                    ? "Keine passenden WebApps"
                                                    : (root.selectedCategory === "installed"
                                                        ? "Keine WebApps installiert"
                                                        : "In dieser Kategorie gibt es keine WebApps")
                                                color: Style.Theme.textMuted
                                                font.pixelSize: Style.Tokens.fontBodyLarge
                                                font.weight: Font.Medium
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: root.searchQuery.length > 0
                                                    ? "Suche anpassen oder mit Esc leeren"
                                                    : (root.selectedCategory === "installed"
                                                        ? "Installiere eine WebApp aus dem Katalog"
                                                        : "Wähle eine andere Kategorie oder lege eine eigene WebApp an")
                                                color: Style.Theme.textSubtle
                                                font.pixelSize: Style.Tokens.fontBodySmall
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ParallelAnimation {
                        id: contentSwitch
                        Style.EffectAnimation { target: contentPane; property: "opacity"; from: 0; to: 1 }
                        Style.SpatialAnimation { target: contentTranslate; property: "y"; to: 0 }
                    }
                }
            }

            Style.WindowCloseDock {
                anchors.top: parent.top
                anchors.right: parent.right
                z: 100
                onClicked: Qt.quit()
            }

            Rectangle {
                x: 24 + Math.min(Style.Tokens.navigationWidth, window.width * 0.34)
                y: 12
                width: parent.width - x - 12
                height: parent.height - 24
                visible: true
                enabled: root.mainPage === "wizard"
                opacity: enabled ? 1 : 0
                radius: Style.Tokens.radiusMainSurface
                color: Style.Theme.mainSurface
                clip: true
                z: enabled ? 60 : -1

                Behavior on opacity { Style.EffectAnimation {} }
                transform: Translate {
                    x: root.mainPage === "wizard" ? 0 : Style.Tokens.space2xl
                    Behavior on x { Style.SpatialAnimation {} }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeWizard()
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 26
                    color: "transparent"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: function(mouse) { mouse.accepted = true }
                    }

                    ColumnLayout {
                        id: wizardColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 0
                        spacing: Style.Tokens.spaceLg

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.Tokens.spaceLg

                            Style.IconButton {
                                icon: "\ue5c4"
                                interactive: !root.actionBusy
                                onClicked: root.closeWizard()
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.wizardEditing ? "WebApp bearbeiten" : "WebApp hinzufügen"
                                color: Style.Theme.textPrimaryAlt
                                font.pixelSize: Style.Tokens.fontDisplay
                                font.weight: Font.DemiBold
                            }

                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.wizardEditing
                                ? "Die App-ID bleibt unverändert. Änderungen werden als User-Definition gespeichert."
                                : "Eigene Apps werden getrennt unter ~/.config/caelestia-webapps/apps gespeichert."
                            wrapMode: Text.WordWrap
                            color: Style.Theme.labelMuted
                            font.pixelSize: Style.Tokens.fontBodySmall
                        }

                        Text { text: "Name"; color: Style.Theme.textSecondary; font.pixelSize: Style.Tokens.fontBodySmall }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Style.Tokens.fieldHeight
                            radius: Style.Tokens.radiusMd
                            color: Style.Theme.surfaceLow
                            border.width: 1
                            border.color: wizardName.activeFocus ? Style.Theme.focus : Style.Theme.fieldBorder
                            TextInput {
                                id: wizardName
                                anchors.fill: parent
                                anchors.margins: 10
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.wizardName
                                color: Style.Theme.textPrimary
                                selectByMouse: true
                                activeFocusOnTab: true
                                KeyNavigation.tab: wizardId
                                KeyNavigation.backtab: wizardSaveButton
                                Keys.onEscapePressed: root.closeWizard()
                                onTextEdited: {
                                    root.wizardName = text
                                    if (!root.wizardEditing && root.wizardId.length === 0)
                                        root.wizardId = root.slugify(text)
                                }
                            }
                        }

                        Text { text: "App-ID"; color: Style.Theme.textSecondary; font.pixelSize: Style.Tokens.fontBodySmall }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Style.Tokens.fieldHeight
                            radius: Style.Tokens.radiusMd
                            color: Style.Theme.surfaceLow
                            border.width: 1
                            border.color: wizardId.activeFocus ? Style.Theme.focus : Style.Theme.fieldBorder
                            opacity: root.wizardEditing ? 0.55 : 1
                            TextInput {
                                id: wizardId
                                anchors.fill: parent
                                anchors.margins: 10
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.wizardId
                                readOnly: root.wizardEditing
                                color: Style.Theme.textPrimary
                                selectByMouse: true
                                activeFocusOnTab: true
                                KeyNavigation.tab: wizardUrl
                                KeyNavigation.backtab: wizardName
                                Keys.onEscapePressed: root.closeWizard()
                                onTextEdited: root.wizardId = text.toLowerCase()
                                onEditingFinished: root.wizardAutoIconId = root.wizardId.trim()
                            }
                        }

                        Text { text: "URL"; color: Style.Theme.textSecondary; font.pixelSize: Style.Tokens.fontBodySmall }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Style.Tokens.fieldHeight
                            radius: Style.Tokens.radiusMd
                            color: Style.Theme.surfaceLow
                            border.width: 1
                            border.color: wizardUrl.activeFocus ? Style.Theme.focus : Style.Theme.fieldBorder
                            TextInput {
                                id: wizardUrl
                                anchors.fill: parent
                                anchors.margins: 10
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.wizardUrl
                                color: Style.Theme.textPrimary
                                selectByMouse: true
                                activeFocusOnTab: true
                                KeyNavigation.tab: root.wizardIconMode === "url" ? wizardIcon : wizardSaveButton
                                KeyNavigation.backtab: wizardId
                                Keys.onEscapePressed: root.closeWizard()
                                onTextEdited: root.wizardUrl = text
                            }
                        }

                        Text { text: "Kategorie"; color: Style.Theme.textSecondary; font.pixelSize: Style.Tokens.fontBodySmall }
                        Flow {
                            Layout.fillWidth: true
                            spacing: Style.Tokens.spaceSm
                            Repeater {
                                model: root.categories
                                delegate: Rectangle {
                                    required property var modelData
                                    implicitWidth: catText.implicitWidth + 24
                                    implicitHeight: Style.Tokens.controlHeightCompact
                                    radius: Style.Tokens.radiusControl
                                    color: root.wizardCategory === modelData.id ? Style.Theme.primary : Style.Theme.controlSurface
                                    Text {
                                        id: catText
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: root.wizardCategory === modelData.id ? Style.Theme.primaryContent : Style.Theme.controlText
                                        font.pixelSize: Style.Tokens.fontLabel
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.wizardCategory = modelData.id
                                    }
                                }
                            }
                        }

                        Text { text: "Icon"; color: Style.Theme.textSecondary; font.pixelSize: Style.Tokens.fontBodySmall }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Style.Tokens.spaceSm
                            Repeater {
                                model: [{ id: "auto", label: "Automatisch" }, { id: "url", label: "URL" }, { id: "local", label: "Lokale Datei" }]
                                delegate: Rectangle {
                                    required property var modelData
                                    implicitWidth: iconModeText.implicitWidth + 24
                                    implicitHeight: Style.Tokens.controlHeightCompact
                                    radius: Style.Tokens.radiusControl
                                    color: root.wizardIconMode === modelData.id ? Style.Theme.primary : Style.Theme.controlSurface
                                    Text { id: iconModeText; anchors.centerIn: parent; text: modelData.label; color: root.wizardIconMode === modelData.id ? Style.Theme.primaryContent : Style.Theme.controlText; font.pixelSize: Style.Tokens.fontLabel }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.wizardIconMode = modelData.id
                                            if (modelData.id === "auto")
                                                root.wizardAutoIconId = root.wizardId.trim()
                                        }
                                    }
                                }
                            }
                        }

                        Text { visible: root.wizardIconMode === "auto"; Layout.fillWidth: true; text: "Automatisch verwendet die Dashboard-Icons-Adresse passend zur App-ID."; wrapMode: Text.WordWrap; color: Style.Theme.hint; font.pixelSize: Style.Tokens.fontLabel }

                        Rectangle {
                            visible: root.wizardIconMode === "url"
                            Layout.fillWidth: true
                            implicitHeight: Style.Tokens.fieldHeight
                            radius: Style.Tokens.radiusMd
                            color: Style.Theme.surfaceLow
                            border.width: 1
                            border.color: wizardIcon.activeFocus ? Style.Theme.focus : Style.Theme.fieldBorder
                            TextInput {
                                id: wizardIcon
                                anchors.fill: parent
                                anchors.margins: 10
                                verticalAlignment: TextInput.AlignVCenter
                                text: root.wizardIconUrl
                                color: Style.Theme.textPrimary
                                selectByMouse: true
                                activeFocusOnTab: true
                                KeyNavigation.tab: wizardSaveButton
                                KeyNavigation.backtab: wizardUrl
                                Keys.onEscapePressed: root.closeWizard()
                                onTextEdited: root.wizardIconUrl = text
                            }
                        }

                        RowLayout {
                            visible: root.wizardIconMode === "local"
                            Layout.fillWidth: true
                            spacing: Style.Tokens.spaceMd
                            Rectangle {
                                Layout.fillWidth: true; implicitHeight: Style.Tokens.fieldHeight; radius: Style.Tokens.radiusMd; color: Style.Theme.surfaceLow; border.width: 1; border.color: Style.Theme.fieldBorder
                                Text { anchors.fill: parent; anchors.margins: 10; verticalAlignment: Text.AlignVCenter; elide: Text.ElideMiddle; text: root.wizardIconFile.length > 0 ? root.wizardIconFile : "Keine Datei ausgewählt"; color: root.wizardIconFile.length > 0 ? Style.Theme.controlText : Style.Theme.textDisabled; font.pixelSize: Style.Tokens.fontLabel }
                            }
                            Rectangle {
                                implicitWidth: 98; implicitHeight: Style.Tokens.fieldHeight; radius: Style.Tokens.radiusControl; color: iconPickHover.hovered ? Style.Theme.pickerHover : Style.Theme.controlSurface
                                HoverHandler { id: iconPickHover }
                                Text { anchors.centerIn: parent; text: "Auswählen…"; color: Style.Theme.pickerText; font.pixelSize: Style.Tokens.fontLabel }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: iconFileDialog.open() }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            visible: root.wizardIconPreview().length > 0
                            spacing: Style.Tokens.spaceLg
                            Rectangle {
                                implicitWidth: 54; implicitHeight: 54; radius: Style.Tokens.radiusPill; color: Style.Theme.surfaceLow; border.width: 1; border.color: Style.Theme.fieldBorder
                                Image { anchors.fill: parent; anchors.margins: 8; source: root.wizardIconPreview(); fillMode: Image.PreserveAspectFit; asynchronous: true; cache: false }
                            }
                            Text { Layout.fillWidth: true; text: "Icon-Vorschau"; color: Style.Theme.labelMuted; font.pixelSize: Style.Tokens.fontLabel }
                        }

                        Text {
                            visible: root.wizardError.length > 0
                            Layout.fillWidth: true
                            text: root.wizardError
                            wrapMode: Text.WordWrap
                            color: Style.Theme.error
                            font.pixelSize: Style.Tokens.fontBodySmall
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: Style.Tokens.spaceMd
                            Style.ActionButton {
                                id: wizardCancelButton
                                minimumWidth: 96
                                label: "Abbrechen"
                                interactive: !root.actionBusy
                                onClicked: root.closeWizard()
                            }
                            Style.ActionButton {
                                id: wizardSaveButton
                                minimumWidth: 112
                                primary: true
                                icon: root.wizardEditing ? "\ue161" : "\ue145"
                                label: root.actionBusy ? "Bitte warten…" : (root.wizardEditing ? "Speichern" : "Anlegen")
                                interactive: !root.actionBusy
                                onClicked: root.submitWizard()
                            }
                        }
                    }
                }
            }

            Rectangle {
                x: 24 + Math.min(Style.Tokens.navigationWidth, window.width * 0.34)
                y: 12
                width: parent.width - x - 12
                height: parent.height - 24
                visible: true
                enabled: root.mainPage === "actions"
                opacity: enabled ? 1 : 0
                radius: Style.Tokens.radiusMainSurface
                color: Style.Theme.mainSurface
                clip: true
                z: enabled ? 54 : -1

                Behavior on opacity { Style.EffectAnimation {} }
                transform: Translate {
                    x: root.mainPage === "actions" ? 0 : Style.Tokens.space2xl
                    Behavior on x { Style.SpatialAnimation {} }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeActionMenu()
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 26
                    color: "transparent"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: function(mouse) { mouse.accepted = true }
                    }

                    ColumnLayout {
                        id: actionMenuColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 0
                        spacing: Style.Tokens.spaceLg

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.Tokens.spaceLg

                            Style.IconButton {
                                icon: "\ue5c4"
                                interactive: !root.actionBusy
                                onClicked: root.closeActionMenu()
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Style.Tokens.spaceXxs

                                Text {
                                    Layout.fillWidth: true
                                    text: root.actionMenuApp ? root.actionMenuApp.name : "WebApp"
                                    color: Style.Theme.textPrimaryAlt
                                    font.pixelSize: Style.Tokens.fontDisplay
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Weitere Aktionen und Einstellungen für diese WebApp."
                                    wrapMode: Text.WordWrap
                                    color: Style.Theme.labelMuted
                                    font.pixelSize: Style.Tokens.fontBodySmall
                                }
                            }

                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Style.Tokens.spaceXs

                            Repeater {
                                model: root.actionMenuEntries()

                                delegate: Style.SettingsAction {
                                    required property var modelData
                                    required property int index
                                    Layout.fillWidth: true
                                    title: modelData.title
                                    description: modelData.description
                                    actionLabel: modelData.label
                                    danger: modelData.danger === true
                                    interactive: !root.actionBusy
                                    firstInGroup: index === 0
                                    lastInGroup: index === root.actionMenuEntries().length - 1
                                    onClicked: root.runActionMenuEntry(modelData)
                                }
                            }
                        }

                    }
                }
            }

            Rectangle {
                x: 24 + Math.min(Style.Tokens.navigationWidth, window.width * 0.34)
                y: 12
                width: parent.width - x - 12
                height: parent.height - 24
                visible: true
                enabled: root.mainPage === "applet-settings"
                opacity: enabled ? 1 : 0
                radius: Style.Tokens.radiusMainSurface
                color: Style.Theme.mainSurface
                clip: true
                z: enabled ? 55 : -1

                Behavior on opacity { Style.EffectAnimation {} }
                transform: Translate {
                    x: root.mainPage === "applet-settings" ? 0 : Style.Tokens.space2xl
                    Behavior on x { Style.SpatialAnimation {} }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeAppletSettings()
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 26
                    color: "transparent"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: function(mouse) { mouse.accepted = true }
                    }

                    ColumnLayout {
                        id: settingsColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 0
                        spacing: Style.Tokens.spaceLg

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Style.Tokens.spaceLg

                            Style.IconButton {
                                icon: "\ue5c4"
                                interactive: !root.appletSettingsBusy
                                onClicked: root.closeAppletSettings()
                            }

                            Text {
                                Layout.fillWidth: true
                                text: !root.appletSettingsApp ? "Applet-Einstellungen" : root.appletSettingsApp.name + " · Applet"
                                color: Style.Theme.textPrimaryAlt
                                font.pixelSize: Style.Tokens.fontDisplay
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Nur Capabilities aus der Runtime-Registry werden angeboten. Änderungen werden sofort vom Applet übernommen."
                            wrapMode: Text.WordWrap
                            color: Style.Theme.labelMuted
                            font.pixelSize: Style.Tokens.fontBodySmall
                        }

                        Text {
                            visible: root.appletSettingsBusy && root.appletSettingsItems.length === 0
                            text: "Einstellungen werden geladen…"
                            color: Style.Theme.textMuted
                            font.pixelSize: Style.Tokens.fontBodySmall
                        }

                        Repeater {
                            model: root.appletSettingsItems

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 58
                                radius: Style.Tokens.radiusMd
                                color: Style.Theme.surfaceLow
                                border.width: 1
                                border.color: Style.Theme.fieldBorder

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 12
                                    spacing: Style.Tokens.spaceMd

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            Layout.fillWidth: true
                                            text: root.capabilityLabel(modelData.name)
                                            color: Style.Theme.textPrimary
                                            font.pixelSize: Style.Tokens.fontBodyLarge
                                            font.weight: Font.Medium
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: root.capabilityDescription(modelData.name)
                                            color: Style.Theme.textMuted
                                            font.pixelSize: Style.Tokens.fontBodySmall
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Rectangle {
                                        width: 42
                                        height: 24
                                        radius: 12
                                        opacity: root.appletSettingsBusy ? 0.55 : 1
                                        color: modelData.enabled ? Style.Theme.switchOn : Style.Theme.switchOff
                                        border.width: 1
                                        border.color: modelData.enabled ? Style.Theme.switchBorderOn : Style.Theme.switchBorderOff

                                        Rectangle {
                                            width: 18
                                            height: 18
                                            radius: 9
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: modelData.enabled ? parent.width - width - 3 : 3
                                            color: modelData.enabled ? Style.Theme.primaryContent : Style.Theme.switchThumbOff
                                            Behavior on x { NumberAnimation { duration: Style.Tokens.motionFast } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: !root.appletSettingsBusy
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.toggleAppletCapability(modelData.name, modelData.enabled)
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: root.appletSettingsError.length > 0
                            Layout.fillWidth: true
                            text: root.appletSettingsError
                            wrapMode: Text.WordWrap
                            color: Style.Theme.error
                            font.pixelSize: Style.Tokens.fontBodySmall
                        }

                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: root.pendingUninstallApp !== null
                color: Style.Theme.scrimSoft
                z: 50

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.cancelUninstall()
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 80, 470)
                    implicitHeight: confirmColumn.implicitHeight + 42
                    radius: Style.Tokens.radiusDialog
                    color: Style.Theme.surfaceAlt
                    border.width: 1
                    border.color: Style.Theme.dialogBorder

                    MouseArea {
                        anchors.fill: parent
                        onClicked: function(mouse) { mouse.accepted = true }
                    }

                    ColumnLayout {
                        id: confirmColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 21
                        spacing: Style.Tokens.spaceXl

                        Text {
                            text: !root.pendingUninstallApp
                                ? ""
                                : (!root.pendingUninstallApp.installed && root.pendingUninstallApp.source === "user"
                                    ? root.pendingUninstallApp.name + " aus dem Katalog entfernen?"
                                    : (root.appRunning(root.pendingUninstallApp.id)
                                        ? root.pendingUninstallApp.name + " läuft noch"
                                        : "WebApp deinstallieren?"))
                            color: Style.Theme.textPrimary
                            font.pixelSize: Style.Tokens.fontTitle
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: !root.pendingUninstallApp
                                ? ""
                                : (!root.pendingUninstallApp.installed && root.pendingUninstallApp.source === "user"
                                    ? "Die User-App-Definition und ein verwaltetes User-Icon werden dauerhaft aus deinem Katalog entfernt."
                                    : (root.appRunning(root.pendingUninstallApp.id)
                                        ? "Zum Deinstallieren muss das laufende WebApp-Fenster zuerst regulär geschlossen werden. Erst danach wird " + root.pendingUninstallApp.name + " deinstalliert."
                                        : root.pendingUninstallApp.name + " wird deinstalliert. Das Firefox-Profil dieser WebApp wird dabei gemäß Engine-Regeln behandelt."))
                            color: Style.Theme.dialogMuted
                            font.pixelSize: Style.Tokens.fontBody
                        }

                        RowLayout {
                            visible: root.pendingUninstallApp
                                && root.pendingUninstallApp.installed
                                && root.pendingUninstallApp.source === "user"
                            Layout.fillWidth: true
                            spacing: Style.Tokens.spaceLg

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Style.Tokens.spaceXxs

                                Text {
                                    text: "Aus dem Katalog entfernen"
                                    color: Style.Theme.sliderLabel
                                    font.pixelSize: Style.Tokens.fontBody
                                    font.weight: Font.Medium
                                }

                                Text {
                                    text: "Löscht anschließend auch die User-App-Definition."
                                    color: Style.Theme.textSubtle
                                    font.pixelSize: Style.Tokens.fontLabel
                                }
                            }

                            Rectangle {
                                id: removeCatalogSwitch
                                implicitWidth: 46
                                implicitHeight: Style.Tokens.switchHeight
                                radius: Style.Tokens.radiusSwitch
                                color: root.removeFromCatalogAfterUninstall ? Style.Theme.switchOn : Style.Theme.switchOff
                                border.width: activeFocus ? Style.Tokens.focusRingWidth : 1
                                border.color: activeFocus
                                    ? Style.Theme.focusStrong
                                    : (root.removeFromCatalogAfterUninstall ? Style.Theme.switchBorderOn : Style.Theme.switchBorderOff)
                                scale: switchPointer.pressed ? Style.Tokens.pressedScale : 1.0
                                activeFocusOnTab: true

                                Keys.onReturnPressed: root.removeFromCatalogAfterUninstall = !root.removeFromCatalogAfterUninstall
                                Keys.onEnterPressed: root.removeFromCatalogAfterUninstall = !root.removeFromCatalogAfterUninstall
                                Keys.onSpacePressed: root.removeFromCatalogAfterUninstall = !root.removeFromCatalogAfterUninstall

                                Behavior on scale { NumberAnimation { duration: Style.Tokens.motionPress; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: Style.Tokens.radiusSm
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: root.removeFromCatalogAfterUninstall ? parent.width - width - 3 : 3
                                    color: root.removeFromCatalogAfterUninstall ? Style.Theme.primaryContent : Style.Theme.switchThumbOff

                                    Behavior on x {
                                        NumberAnimation { duration: Style.Tokens.motionFast }
                                    }
                                }

                                MouseArea {
                                    id: switchPointer
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.removeFromCatalogAfterUninstall = !root.removeFromCatalogAfterUninstall
                                }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: Style.Tokens.spaceMd
                            Style.ActionButton {
                                minimumWidth: 96
                                label: "Abbrechen"
                                onClicked: root.cancelUninstall()
                            }
                            Style.ActionButton {
                                minimumWidth: root.pendingUninstallApp && (!root.pendingUninstallApp.installed || root.appRunning(root.pendingUninstallApp.id)) ? 184 : 118
                                danger: true
                                icon: root.pendingUninstallApp && root.appRunning(root.pendingUninstallApp.id) ? "\ue5cd" : "\ue872"
                                label: !root.pendingUninstallApp ? "" : (!root.pendingUninstallApp.installed && root.pendingUninstallApp.source === "user" ? "Aus Katalog entfernen" : (root.appRunning(root.pendingUninstallApp.id) ? "Schließen & deinstallieren" : "Deinstallieren"))
                                onClicked: root.confirmUninstall()
                            }
                        }
                    }
                }
            }
        }
    }
}
