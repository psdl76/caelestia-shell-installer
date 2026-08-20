#!/usr/bin/env python3
from pathlib import Path
import json
import os
import shutil
import sys
import time

config_root = Path.home() / '.config/quickshell/caelestia-plugin-test'
if len(sys.argv) > 1:
    config_root = Path(sys.argv[1]).expanduser()

bar = config_root / 'modules/bar/Bar.qml'
interactions = config_root / 'modules/drawers/Interactions.qml'

for path in (bar, interactions):
    if not path.exists():
        raise SystemExit(f'ERROR: required test-shell file not found: {path}')

state_root = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'caelestia-webapps'
state_root.mkdir(parents=True, exist_ok=True)
pins_file = state_root / 'pins.json'
if not pins_file.exists():
    pins_file.write_text(json.dumps({'pins': {}}, indent=2) + '\n', encoding='utf-8')

bar_text = bar.read_text()
interactions_text = interactions.read_text()

marker_bar = 'caelestia-webapps pin-filewatch fix7'
marker_interactions = 'caelestia-webapps pin-local-filewatch fix7'

if marker_bar in bar_text and marker_interactions in interactions_text:
    print(f'Already patched (fix7): {config_root}')
    raise SystemExit(0)

# BAR.QML: keep the FileView state local to Bar.qml for checkPopout().
bar_text = bar_text.replace('caelestia-webapps pin-filewatch fix6', marker_bar)

old_guard_1 = '        if (root.webappsYoutubePinned && popouts.currentName === "webapp-youtube")\n            return;\n'
old_guard_2 = '        // caelestia-webapps pin-close-guard fix5b\n        if (root.webappsYoutubePinned\n                && popouts.hasCurrent\n                && popouts.currentName === "webapp-youtube")\n            return;\n'
bar_text = bar_text.replace(old_guard_1, '')
bar_text = bar_text.replace(old_guard_2, '')

check_anchor = '    function checkPopout(y: real): void {\n'
if check_anchor not in bar_text:
    raise SystemExit('ERROR: Bar.checkPopout() not found.')
if 'property bool webappsYoutubePinned' not in bar_text:
    raise SystemExit('ERROR: expected fix6 Bar FileView pin state missing.')

# Remove any previous fix6/fix7 check guard first to avoid duplicates.
old_fix6_guard = '    function checkPopout(y: real): void {\n        // caelestia-webapps pin-filewatch fix6\n        if (root.webappsYoutubePinned\n                && popouts.hasCurrent\n                && popouts.currentName === "webapp-youtube")\n            return;\n'
old_fix7_guard = '    function checkPopout(y: real): void {\n        // caelestia-webapps pin-filewatch fix7\n        if (root.webappsYoutubePinned\n                && popouts.hasCurrent\n                && popouts.currentName === "webapp-youtube")\n            return;\n'
bar_text = bar_text.replace(old_fix6_guard, check_anchor)
bar_text = bar_text.replace(old_fix7_guard, check_anchor)

guard = '    function checkPopout(y: real): void {\n        // caelestia-webapps pin-filewatch fix7\n        if (root.webappsYoutubePinned\n                && popouts.hasCurrent\n                && popouts.currentName === "webapp-youtube")\n            return;\n'
bar_text = bar_text.replace(check_anchor, guard, 1)

# INTERACTIONS.QML: local pin FileView. `bar` is a BarWrapper, not inner Bar.qml.
if 'required property Bar.BarWrapper bar' not in interactions_text:
    raise SystemExit('ERROR: expected required property Bar.BarWrapper bar not found.')

if 'import Quickshell.Io' not in interactions_text:
    lines = interactions_text.splitlines()
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith('import '):
            insert_at = i + 1
    lines.insert(insert_at, 'import Quickshell.Io')
    interactions_text = '\n'.join(lines) + ('\n' if interactions_text.endswith('\n') else '')

# Normalize previous close guards back to original close statements.
variants = [
('''                // caelestia-webapps pin-filewatch fix6
                if (!(bar.webappsYoutubePinned
                        && popouts.hasCurrent
                        && popouts.currentName === "webapp-youtube"))
                    popouts.hasCurrent = false;
''', '''                popouts.hasCurrent = false;
'''),
('''            // caelestia-webapps pin-filewatch fix6
            if (!(bar.webappsYoutubePinned
                    && popouts.hasCurrent
                    && popouts.currentName === "webapp-youtube"))
                popouts.hasCurrent = false;
''', '''            popouts.hasCurrent = false;
'''),
('''                // caelestia-webapps pin-close-guard fix5b
                if (!(bar.webappsYoutubePinned
                        && popouts.hasCurrent
                        && popouts.currentName === "webapp-youtube"))
                    popouts.hasCurrent = false;
''', '''                popouts.hasCurrent = false;
'''),
('''            // caelestia-webapps pin-close-guard fix5b
            if (!(bar.webappsYoutubePinned
                    && popouts.hasCurrent
                    && popouts.currentName === "webapp-youtube"))
                popouts.hasCurrent = false;
''', '''            popouts.hasCurrent = false;
''')]
for old, new in variants:
    interactions_text = interactions_text.replace(old, new)

# Remove old fix6/fix7 local bridge if rerun partially.
for marker in ['    // caelestia-webapps pin-local-filewatch fix7\n']:
    start = interactions_text.find(marker)
    if start >= 0:
        end = interactions_text.find('    required property ShellScreen screen\n', start)
        if end < 0:
            raise SystemExit('ERROR: could not safely delimit old Interactions bridge.')
        interactions_text = interactions_text[:start] + interactions_text[end:]

root_anchor = '    id: root\n'
if root_anchor not in interactions_text:
    raise SystemExit('ERROR: Interactions.qml root id not found.')

local_bridge = r'''
    // caelestia-webapps pin-local-filewatch fix7
    // `bar` is Bar.BarWrapper, not the inner Bar.qml. Keep pin state local.
    readonly property string webappsPinStatePath: {
        const xdg = Quickshell.env("XDG_STATE_HOME") || "";
        const home = Quickshell.env("HOME") || "";
        const stateRoot = xdg.length > 0 ? xdg : home + "/.local/state";
        return stateRoot + "/caelestia-webapps/pins.json";
    }
    property bool webappsYoutubePinned: false

    function refreshWebappsYoutubePin(): void {
        const raw = webappsPinFile.text().trim();
        if (raw.length === 0) {
            root.webappsYoutubePinned = false;
            return;
        }
        try {
            const payload = JSON.parse(raw);
            root.webappsYoutubePinned = payload?.pins?.youtube === true;
        } catch (e) {
            root.webappsYoutubePinned = false;
            console.warn("caelestia-webapps: Interactions pin file parse failed", e);
        }
    }

    FileView {
        id: webappsPinFile
        path: root.webappsPinStatePath
        watchChanges: true
        printErrors: false
        onLoaded: root.refreshWebappsYoutubePin()
        onFileChanged: reload()
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: webappsPinFile.reload()
    }

'''
interactions_text = interactions_text.replace(root_anchor, root_anchor + local_bridge, 1)

site1 = ('            if (!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) {\n'
         '                popouts.hasCurrent = false;\n'
         '                bar.closeTray();\n'
         '            }\n')
repl1 = ('            if (!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) {\n'
         '                // caelestia-webapps pin-local-filewatch fix7\n'
         '                if (!(root.webappsYoutubePinned\n'
         '                        && popouts.hasCurrent\n'
         '                        && popouts.currentName === "webapp-youtube"))\n'
         '                    popouts.hasCurrent = false;\n'
         '                bar.closeTray();\n'
         '            }\n')
if site1 not in interactions_text:
    raise SystemExit('ERROR: first Interactions close path not found.')
interactions_text = interactions_text.replace(site1, repl1, 1)

site2 = ('        } else if ((!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) && !inLeftPanel(panels.popoutsWrapper, x, y)) {\n'
         '            popouts.hasCurrent = false;\n'
         '            bar.closeTray();\n'
         '        }\n')
repl2 = ('        } else if ((!popouts.currentName.startsWith("traymenu") || ((popouts.current as StackView)?.depth ?? 0) <= 1) && !inLeftPanel(panels.popoutsWrapper, x, y)) {\n'
         '            // caelestia-webapps pin-local-filewatch fix7\n'
         '            if (!(root.webappsYoutubePinned\n'
         '                    && popouts.hasCurrent\n'
         '                    && popouts.currentName === "webapp-youtube"))\n'
         '                popouts.hasCurrent = false;\n'
         '            bar.closeTray();\n'
         '        }\n')
if site2 not in interactions_text:
    raise SystemExit('ERROR: second Interactions close path not found.')
interactions_text = interactions_text.replace(site2, repl2, 1)

if 'bar.webappsYoutubePinned' in interactions_text:
    raise SystemExit('ERROR: stale BarWrapper pin reference remains.')

stamp = time.strftime('%Y%m%d-%H%M%S')
for path in (bar, interactions):
    backup = path.with_name(path.name + f'.before-webapps-pin-fix7-{stamp}')
    shutil.copy2(path, backup)
    print(f'Backup : {backup}')

bar.write_text(bar_text)
interactions.write_text(interactions_text)
print(f'Patched Bar.qml         : {bar}')
print(f'Patched Interactions.qml: {interactions}')
print(f'Pin state file          : {pins_file}')
