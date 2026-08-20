import QtQuick
import Quickshell

QtObject {
    id: root

    readonly property string processPath: {
        const current = Quickshell.env("PATH") || "";
        const home = Quickshell.env("HOME") || "";
        if (home.length === 0)
            return current;

        const localBin = home + "/.local/bin";
        const entries = current.length > 0 ? current.split(":") : [];
        if (entries.indexOf(localBin) !== -1)
            return current;

        // Preserve caller PATH precedence. Rootless fallback is appended only.
        return current.length > 0 ? current + ":" + localBin : localBin;
    }

    function cliCommand(args) {
        return [
            "/usr/bin/env",
            "PATH=" + root.processPath,
            "caelestia-webapps"
        ].concat(args);
    }
}
