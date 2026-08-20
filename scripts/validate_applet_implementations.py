#!/usr/bin/env python3
from __future__ import annotations
import json, sys
from pathlib import Path
from typing import Any


def main() -> int:
    if len(sys.argv) != 4:
        print('usage: validate_applet_implementations.py REGISTRY MANIFEST PLUGIN_ROOT', file=sys.stderr)
        return 2
    registry_path, manifest_path, plugin_root = map(Path, sys.argv[1:])
    errors: list[str] = []
    try:
        registry = json.loads(registry_path.read_text(encoding='utf-8'))
        manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    except (OSError, json.JSONDecodeError) as exc:
        print(json.dumps({'ok': False, 'errors': [str(exc)]}))
        return 1

    apps = [x for x in registry.get('apps', []) if isinstance(x, dict)]
    supported = sorted(str(x['id']) for x in apps if x.get('support') == 'supported')
    experimental = sorted(str(x['id']) for x in apps if x.get('support') == 'experimental')
    entries = [x for x in manifest.get('entryPoints', []) if isinstance(x, dict)]

    dedicated: dict[str, dict[str, str]] = {}
    orphan_names: list[str] = []
    for entry in entries:
        props = entry.get('properties') if isinstance(entry.get('properties'), dict) else {}
        name = str(props.get('name') or props.get('entry') or '')
        if not name.startswith('webapp-'):
            continue
        app_id = name[len('webapp-'):]
        bucket = dedicated.setdefault(app_id, {})
        etype = str(entry.get('type', ''))
        source = str(entry.get('source', ''))
        if etype == 'bar-entry':
            bucket['barEntry'] = source
        elif etype == 'bar-popout':
            bucket['popout'] = source
        if source and not (plugin_root / source).is_file():
            errors.append(f'{app_id}: manifest source missing: {source}')

    for app_id in supported:
        mapping = dedicated.get(app_id, {})
        if not mapping.get('barEntry'):
            errors.append(f'{app_id}: supported app missing dedicated bar-entry')
        if not mapping.get('popout'):
            errors.append(f'{app_id}: supported app missing dedicated bar-popout')

    allowed = set(supported)
    for app_id in sorted(dedicated):
        if app_id not in allowed:
            orphan_names.append(app_id)
            errors.append(f'{app_id}: dedicated runtime implementation exists but registry support != supported')

    mapped = sorted(app_id for app_id in supported if app_id in dedicated and dedicated[app_id].get('barEntry') and dedicated[app_id].get('popout'))
    data: dict[str, Any] = {
        'registryApps': len(apps),
        'supported': len(supported),
        'experimental': len(experimental),
        'implementedSupported': len(mapped),
        'supportedAppIds': supported,
        'implementedAppIds': mapped,
        'orphanImplementations': orphan_names,
        'consistent': not errors,
    }
    print(json.dumps({'ok': not errors, 'data': data, 'errors': errors}, ensure_ascii=False, indent=2))
    return 0 if not errors else 1

if __name__ == '__main__':
    raise SystemExit(main())
