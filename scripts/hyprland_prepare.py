#!/usr/bin/env python3
import argparse
import re
import sys
from pathlib import Path

MARK = "Caelestia WebApps"


def info(msg): print(f"INFO|{msg}")
def ok(msg): print(f"OK|{msg}")
def warn(msg): print(f"WARN|{msg}")
def conflict(msg):
    print(f"CONFLICT|{msg}", file=sys.stderr)
    raise SystemExit(3)


def find_rule(text, tag):
    pat = re.compile(
        r'(tagged_rule\(' + re.escape(tag) + r'\s*,\s*\{\n)(.*?)(\n\}\s*,\s*"class"\s*\)[^\n]*)',
        re.S,
    )
    return pat.search(text)


def member_lines(body, klass):
    out=[]
    rx=re.compile(r'^\s*"' + re.escape(klass) + r'"\s*,?\s*(?:--\s*(.*))?$')
    for i,line in enumerate(body.splitlines()):
        m=rx.match(line)
        if m: out.append((i,line,(m.group(1) or '').strip()))
    return out


def add_member(text, tag, klass, app_name, label, owner):
    m=find_rule(text,tag)
    if not m:
        if owner == 'native':
            warn(f"Native Caelestia-Regel {tag} fehlt; {app_name} wird dort nicht automatisch ergänzt.")
            return text
        conflict(f"Verwaltete Regel {tag} fehlt unerwartet.")
    header,body,footer=m.groups()
    matches=member_lines(body,klass)
    if len(matches)>1:
        conflict(f"{klass} kommt mehrfach in {tag} vor; automatische Änderung abgebrochen.")
    if matches:
        comment=matches[0][2]
        if MARK in comment or comment == app_name or not comment:
            info(f"{app_name} ist bereits in {tag} eingetragen.")
        else:
            warn(f"{klass} existiert bereits unverwaltet in {tag}; vorhandener Eintrag bleibt unangetastet.")
        return text
    line=f'    "{klass}", -- Caelestia WebApps: {app_name} ({label})'
    new=header+line+("\n"+body if body else "")+footer
    text=text[:m.start()]+new+text[m.end():]
    ok(f"{app_name} wurde in {tag} ergänzt.")
    return text


def ensure_after_line(text, anchor_rx, exact_line, semantic_rx, name):
    sm=re.search(semantic_rx,text,re.M)
    if sm:
        existing=sm.group(0)
        if existing.strip() == exact_line.strip() or MARK in existing:
            info(f"{name} ist bereits vorhanden.")
            return text
        conflict(f"{name} existiert bereits, gehört aber nicht eindeutig Caelestia WebApps: {existing.strip()}")
    m=re.search(anchor_rx,text,re.M)
    if not m: conflict(f"Sicherer Einfügeanker für {name} wurde nicht gefunden.")
    pos=m.end()
    text=text[:pos]+"\n"+exact_line+text[pos:]
    ok(f"{name} wurde ergänzt.")
    return text


def ensure_streaming_rule(text):
    m=find_rule(text,'streaming_app_tag')
    if m:
        if MARK not in m.group(3):
            conflict("streaming_app_tag-Regel existiert ohne Caelestia-WebApps-Marker.")
        info("Streaming tagged_rule ist bereits vorhanden.")
        return text
    anchor=find_rule(text,'communication_app_tag')
    if not anchor: conflict("communication_app_tag-Anker fehlt; Streaming-Regel kann nicht sicher ergänzt werden.")
    block='tagged_rule(streaming_app_tag, {\n}, "class") -- Caelestia WebApps: streaming\n'
    text=text[:anchor.start()]+block+text[anchor.start():]
    ok("Streaming tagged_rule wurde ergänzt.")
    return text


def prepare_rules(path, category, klass, app_name, use_opaque):
    text=Path(path).read_text(encoding='utf-8')
    if use_opaque:
        if 'local opaque_tag = "opaque"' not in text or not find_rule(text,'opaque_tag'):
            conflict("Erwartete native opaque_tag-Struktur fehlt.")
        text=add_member(text,'opaque_tag',klass,app_name,'opaque','native')
    if category == 'messaging':
        text=add_member(text,'communication_app_tag',klass,app_name,'Messaging','native')
        if 'create_tag(communication_app_tag' not in text:
            warn('Native create_tag(communication_app_tag, ...) fehlt; vorhandene Caelestia-Konfiguration wird nicht ersetzt.')
    elif category in {'video', 'music'}:
        exact_decl='local streaming_app_tag = "streaming_app" -- Caelestia WebApps'
        text=ensure_after_line(
            text,
            r'^local music_player_tag\s*=.*$',
            exact_decl,
            r'^local streaming_app_tag\s*=.*$',
            'streaming_app_tag-Deklaration',
        )
        text=ensure_streaming_rule(text)
        exact_ct='create_tag(streaming_app_tag, { workspace = "special:streaming", opaque = true, idle_inhibit = "always" }) -- Caelestia WebApps'
        text=ensure_after_line(
            text,
            r'^create_tag\(music_player_tag,.*$',
            exact_ct,
            r'^create_tag\(streaming_app_tag,.*$',
            'Streaming create_tag',
        )
        text=add_member(text,'streaming_app_tag',klass,app_name,'Streaming','project')
    Path(path).write_text(text,encoding='utf-8')


def literal_super_y_lines(text):
    rx=re.compile(r'^\s*create_bind\(\s*"SUPER\s*\+\s*Y".*$',re.M|re.I)
    return rx.findall(text)


def prepare_keybinds(path, category):
    if not path or not Path(path).exists():
        if category in {'video', 'music'}: warn('keybinds.lua fehlt; SUPER+Y kann nicht verwaltet werden.')
        return
    p=Path(path); text=p.read_text(encoding='utf-8')
    if 'create_bind(vars.kbMusicWs, fn.toggle("music"))' in text:
        info('Native Musik-Workspace-Bindung vorhanden (SUPER+M über Caelestia vars).')
    else:
        warn('Native Musik-Workspace-Bindung wurde nicht gefunden; SUPER+M wird nicht verändert.')
    if 'create_bind(vars.kbCommunicationWs, fn.toggle("communication"))' in text:
        info('Native Kommunikations-Workspace-Bindung vorhanden (SUPER+D über Caelestia vars).')
    else:
        warn('Native Kommunikations-Workspace-Bindung wurde nicht gefunden; SUPER+D wird nicht verändert.')
    if category not in {'video', 'music'}:
        p.write_text(text,encoding='utf-8'); return
    managed_y='create_bind("SUPER + Y", fn.toggle("streaming")) -- Caelestia WebApps: Streaming'
    managed_v='create_bind("SUPER + V", fn.toggle("streaming")) -- Caelestia WebApps: Streaming'
    y_lines=literal_super_y_lines(text)
    if managed_y in text:
        if len(y_lines) > 1: conflict('SUPER+Y ist mehrfach belegt; Streaming-Bind bleibt unverändert.')
        info('SUPER+Y toggelt bereits special:streaming.')
        p.write_text(text,encoding='utf-8'); return
    if y_lines:
        conflict(f'SUPER+Y ist bereits fremd belegt: {y_lines[0].strip()}')
    if managed_v in text:
        text=text.replace(managed_v,managed_y,1)
        ok('Verwalteter Streaming-Shortcut wurde von SUPER+V auf SUPER+Y migriert.')
        p.write_text(text,encoding='utf-8'); return
    custom=[ln for ln in text.splitlines() if 'fn.toggle("streaming")' in ln]
    if custom:
        warn(f'Ein nicht verwalteter Streaming-Shortcut existiert bereits und bleibt unangetastet: {custom[0].strip()}')
        p.write_text(text,encoding='utf-8'); return
    anchor='create_bind(vars.kbMusicWs, fn.toggle("music"))'
    if anchor not in text:
        conflict('Musik-Workspace-Bind als sicherer Einfügeanker für SUPER+Y fehlt.')
    text=text.replace(anchor,anchor+'\n'+managed_y,1)
    ok('SUPER+Y wurde als verwalteter Streaming-Shortcut ergänzt.')
    p.write_text(text,encoding='utf-8')


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--rules',required=True)
    ap.add_argument('--keybinds',default='')
    ap.add_argument('--category',required=True)
    ap.add_argument('--class-name',required=True)
    ap.add_argument('--app-name',required=True)
    ap.add_argument('--use-opaque',choices=['true','false'],required=True)
    a=ap.parse_args()
    prepare_rules(a.rules,a.category,a.class_name,a.app_name,a.use_opaque=='true')
    prepare_keybinds(a.keybinds,a.category)

if __name__=='__main__': main()
