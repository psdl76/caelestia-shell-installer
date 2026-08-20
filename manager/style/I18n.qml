pragma Singleton

import QtQuick
import Quickshell

QtObject {
    readonly property string requestedLanguage: {
        const override = Quickshell.env("CAELESTIA_WEBAPPS_LANGUAGE")
        if (override && override.length > 0)
            return override
        const lcAll = Quickshell.env("LC_ALL")
        if (lcAll && lcAll.length > 0)
            return lcAll
        const lcMessages = Quickshell.env("LC_MESSAGES")
        if (lcMessages && lcMessages.length > 0)
            return lcMessages
        return Quickshell.env("LANG") || "en"
    }
    readonly property string language: /^de([_.@-]|$)/i.test(requestedLanguage) ? "de" : "en"
    readonly property bool isGerman: language === "de"

    function choose(german, english) {
        return isGerman ? german : english
    }

    function appDescription(app) {
        if (!app)
            return ""
        if (isGerman || app.source === "user")
            return app.comment || app.genericName || app.name
        return app.genericName || app.comment || app.name
    }
}
