#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export HOME="$TMP/home"
export XDG_CONFIG_HOME="$TMP/config"
export XDG_STATE_HOME="$TMP/state"
mkdir -p "$XDG_STATE_HOME/caelestia"
cat >"$XDG_STATE_HOME/caelestia/scheme.json" <<'JSON'
{"name":"dynamic","flavour":"default","mode":"dark","variant":"tonalspot","colours":{
"background":"101112","surface":"121314","surfaceContainerLowest":"0d0e0f",
"surfaceContainerLow":"171819","surfaceContainer":"1b1c1d","surfaceContainerHigh":"202122",
"surfaceContainerHighest":"292a2b","onSurface":"e5e6e7","onSurfaceVariant":"c1c2c3",
"outline":"8a8b8c","outlineVariant":"414243","primary":"aabbcc","onPrimary":"102030",
"secondary":"bbccee","secondaryContainer":"334455","onSecondaryContainer":"ddeeff",
"tertiary":"99ddaa","error":"ffb4ab","onError":"690005","errorContainer":"93000a",
"onErrorContainer":"ffdad6","scrim":"000000"}}
JSON
"$ROOT/scripts/caelestia_theme_bridge.py"
test -f "$XDG_CONFIG_HOME/caelestia/templates/caelestia-webapps.json"
test -f "$XDG_STATE_HOME/caelestia/theme/caelestia-webapps.json"
python3 - "$XDG_STATE_HOME/caelestia/theme/caelestia-webapps.json" <<'PY'
import json,sys
p=json.load(open(sys.argv[1]))
assert p["mode"]=="dark"
assert p["primary"]=="#aabbcc"
assert p["onPrimary"]=="#102030"
PY
grep -Fq '"primary": "#{{ primary.hex }}"' "$XDG_CONFIG_HOME/caelestia/templates/caelestia-webapps.json"
grep -Fq '"mode": "{{ mode }}"' "$XDG_CONFIG_HOME/caelestia/templates/caelestia-webapps.json"
echo "PASS: Caelestia user-template bridge hydrates current Material palette"
