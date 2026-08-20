#!/usr/bin/env bash
set -Eeuo pipefail

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_file() { [[ -f "$1" ]] || fail "Datei fehlt: $1"; }
assert_dir() { [[ -d "$1" ]] || fail "Verzeichnis fehlt: $1"; }
assert_contains() { grep -Fq -- "$2" "$1" || fail "$1 enthält nicht: $2"; }
assert_not_contains() { ! grep -Fq -- "$2" "$1" || fail "$1 enthält unerwartet: $2"; }
assert_eq() { [[ "$1" == "$2" ]] || fail "Erwartet '$2', erhalten '$1'"; }
