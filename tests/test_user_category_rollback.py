#!/usr/bin/env python3
from __future__ import annotations

import json
import os
import shlex
import shutil
import subprocess
import tempfile
from pathlib import Path


SOURCE = Path(__file__).resolve().parent.parent


def invoke(cli: Path, env: dict[str, str], *args: str, expected: int = 0) -> dict:
    proc = subprocess.run([str(cli), *args], env=env, text=True, capture_output=True)
    if proc.returncode != expected:
        raise AssertionError(f"{args}: rc={proc.returncode}\n{proc.stdout}\n{proc.stderr}")
    return json.loads(proc.stdout)


with tempfile.TemporaryDirectory(prefix="caelestia-category-rollback-") as raw:
    temp = Path(raw)
    checkout = temp / "checkout"
    shutil.copytree(
        SOURCE,
        checkout,
        ignore=shutil.ignore_patterns(".git", "__pycache__", ".pytest_cache"),
    )
    home = temp / "home"
    config = temp / "config"
    runtime = temp / "runtime"
    home.mkdir()
    config.mkdir()
    runtime.mkdir()
    env = os.environ.copy()
    env.update({"HOME": str(home), "XDG_CONFIG_HOME": str(config), "XDG_RUNTIME_DIR": str(runtime)})
    cli = checkout / "bin" / "caelestia-webapps"

    invoke(cli, env, "list")
    invoke(cli, env, "user-category-create", json.dumps({"label": "Smart Home", "icon": "home"}))
    category_file = config / "caelestia-webapps" / "categories.json"
    before = category_file.read_bytes()

    catalog = checkout / "catalog.sh"
    real_catalog = checkout / "catalog-real.sh"
    catalog.rename(real_catalog)
    marker = temp / "failed-once"
    catalog.write_text(
        "#!/usr/bin/env bash\n"
        "set -Eeuo pipefail\n"
        f"if [[ ! -e {shlex.quote(str(marker))} ]]; then\n"
        f"  touch {shlex.quote(str(marker))}\n"
        "  echo 'injected category rebuild failure' >&2\n"
        "  exit 42\n"
        "fi\n"
        f"exec {shlex.quote(str(real_catalog))} \"$@\"\n",
        encoding="utf-8",
    )
    catalog.chmod(0o755)

    failed = invoke(
        cli,
        env,
        "user-category-update",
        "smart-home",
        json.dumps({"label": "Changed", "icon": "devices"}),
        expected=20,
    )
    assert failed["error"]["code"] == "catalog_error"
    assert category_file.read_bytes() == before
    listed = invoke(cli, env, "list")["data"]
    category = next(item for item in listed["availableCategories"] if item["id"] == "smart-home")
    assert category["label"] == "Smart Home" and category["icon"] == "home"

print("PASS: failed category metadata rebuild restores the previous user category file")
