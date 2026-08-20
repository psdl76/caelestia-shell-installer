#!/usr/bin/env python3
from pathlib import Path
import ast
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
CLI = ROOT / 'bin/caelestia-webapps'
source = CLI.read_text(encoding='utf-8')
module = ast.parse(source)
node = next(n for n in module.body if isinstance(n, ast.FunctionDef) and n.name == '_normalise_host')
ns = {'urlparse': urlparse}
exec(compile(ast.Module(body=[node], type_ignores=[]), str(CLI), 'exec'), ns)
normalise = ns['_normalise_host']

cases = {
    'youtube.com': 'youtube.com',
    'www.youtube.com': 'youtube.com',
    'https://www.youtube.com/watch?v=abc': 'youtube.com',
    'music.youtube.com': 'music.youtube.com',
    'https://music.youtube.com/': 'music.youtube.com',
    'accounts.youtube.com': 'accounts.youtube.com',
    '': '',
}
for raw, expected in cases.items():
    actual = normalise(raw)
    assert actual == expected, f'{raw!r}: expected {expected!r}, got {actual!r}'

# Guard the exact regression: registry matchHosts are bare hosts, so they must
# survive normalization and match the host extracted from a real context URL.
registry_host = normalise('youtube.com')
context_host = normalise('https://www.youtube.com/watch?v=TRfnRVwaNVo')
assert registry_host == context_host == 'youtube.com'

print('PASS: Phase16.3 registry3-fix3 bare-host normalization')
