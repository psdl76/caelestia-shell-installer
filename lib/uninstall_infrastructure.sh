#!/usr/bin/env bash

# Helpers for safe, metadata-driven removal of WebApp-owned Hyprland state.
# This file intentionally has no top-level side effects.

webapp_artifact_exists() {
    local id="$1"
    [[ -f "$DATA_ROOT/apps/$id/installed.conf" \
       || -d "$DATA_ROOT/apps/$id/profile" \
       || -f "$HOME/.local/bin/caelestia-webapp-$id" \
       || -f "$HOME/.local/share/applications/caelestia-webapp-$id.desktop" ]]
}

other_installed_app_uses_shared_tag() {
    local wanted_tag="$1" def id
    [[ -n "$wanted_tag" ]] || return 1
    for def in "$APP_DEF_DIR"/*.conf; do
        [[ -f "$def" ]] || continue
        id="$(basename "$def" .conf)"
        [[ "$id" != "$APP_ID" ]] || continue
        webapp_artifact_exists "$id" || continue
        if (
            unset HYPR_SHARED_TAG
            # shellcheck disable=SC1090
            source "$def"
            apply_app_category_defaults
            [[ "${HYPR_SHARED_TAG:-}" == "$wanted_tag" ]]
        ); then
            return 0
        fi
    done
    return 1
}

other_installed_app_uses_icon() {
    local wanted_icon="$1" def id
    [[ -n "$wanted_icon" ]] || return 1
    for def in "$APP_DEF_DIR"/*.conf; do
        [[ -f "$def" ]] || continue
        id="$(basename "$def" .conf)"
        [[ "$id" != "$APP_ID" ]] || continue
        webapp_artifact_exists "$id" || continue
        if (
            unset ICON_NAME
            # shellcheck disable=SC1090
            source "$def"
            apply_app_category_defaults
            [[ "${ICON_NAME:-}" == "$wanted_icon" ]]
        ); then
            return 0
        fi
    done
    return 1
}

remove_exact_managed_line_from_tmp() {
    local file="$1" exact="$2"
    [[ -f "$file" && -n "$exact" ]] || return 1
    local tmp
    tmp="$(mktemp "$TX_DIR/line.XXXXXX")" || die "Temporäre Datei konnte nicht erstellt werden."
    awk -v exact="$exact" '$0 != exact { print }' "$file" > "$tmp" || {
        rm -f -- "$tmp"
        die "Verwaltete Zeile konnte nicht verarbeitet werden."
    }
    if cmp -s -- "$file" "$tmp"; then
        rm -f -- "$tmp"
        return 1
    fi
    mv -- "$tmp" "$file"
    return 0
}

remove_app_line_from_tagged_rule_tmp() {
    local file="$1" tag="$2" class_name="$3" mode="${4:-shared}"
    [[ -f "$file" && -n "$tag" && -n "$class_name" ]] || return 1
    local tmp
    tmp="$(mktemp "$TX_DIR/tag.XXXXXX")" || die "Temporäre Datei für $tag konnte nicht erstellt werden."
    if ! python3 - "$file" "$tmp" "$class_name" "$tag" "$mode" <<'PY'
import re, sys
src, dst, app_class, tag_name, mode = sys.argv[1:]
text = open(src, encoding='utf-8').read()
pat = re.compile(r'(tagged_rule\(' + re.escape(tag_name) + r'\s*,\s*\{\n)(.*?)(\n\}\s*,\s*"class"\s*\)(?:[^\n]*)?)', re.S)
m = pat.search(text)
if not m:
    open(dst, 'w', encoding='utf-8').write(text)
    raise SystemExit(0)
header, body, footer = m.groups()
out=[]
for line in body.splitlines():
    q = re.match(r'^\s*"' + re.escape(app_class) + r'"\s*,?\s*(?:--\s*(.*))?$', line)
    if not q:
        out.append(line); continue
    comment=(q.group(1) or '').strip()
    if mode == 'opaque':
        # Opaque membership is removed only when it looks like the WebApps-installed entry.
        # Older versions used the display name as the comment.
        if comment:
            continue
        out.append(line)
    else:
        # Shared membership is the app/workspace association. Older messaging
        # installs may not carry a project marker, therefore exact class within
        # the selected tag is the ownership boundary.
        continue
replacement = header + '\n'.join(out) + footer
new = text[:m.start()] + replacement + text[m.end():]
open(dst, 'w', encoding='utf-8').write(new)
PY
    then
        rm -f -- "$tmp"
        die "Fehler beim Bearbeiten von $tag"
    fi
    if cmp -s -- "$file" "$tmp"; then
        rm -f -- "$tmp"
        return 1
    fi
    mv -- "$tmp" "$file"
    return 0
}

remove_project_owned_tagged_rule_tmp() {
    local file="$1" tag="$2" marker="$3"
    [[ -f "$file" && -n "$tag" && -n "$marker" ]] || return 1
    local tmp
    tmp="$(mktemp "$TX_DIR/rule.XXXXXX")" || die "Temporäre Datei für $tag konnte nicht erstellt werden."
    if ! python3 - "$file" "$tmp" "$tag" "$marker" <<'PY'
import re, sys
src,dst,tag,marker=sys.argv[1:]
text=open(src,encoding='utf-8').read()
pat=re.compile(r'tagged_rule\(' + re.escape(tag) + r'\s*,\s*\{.*?\n\}\s*,\s*"class"\s*\)[^\n]*' + re.escape(marker) + r'[^\n]*\n?', re.S)
new,n=pat.subn('',text,count=1)
open(dst,'w',encoding='utf-8').write(new if n else text)
PY
    then
        rm -f -- "$tmp"; die "Gemeinsame Regel $tag konnte nicht verarbeitet werden."
    fi
    if cmp -s -- "$file" "$tmp"; then rm -f -- "$tmp"; return 1; fi
    mv -- "$tmp" "$file"; return 0
}
