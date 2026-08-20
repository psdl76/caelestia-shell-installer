#!/usr/bin/env python3
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

with tempfile.TemporaryDirectory() as td:
    temp = Path(td)
    project = temp / "project"
    (project / "apps").mkdir(parents=True)
    (project / "config").mkdir(parents=True)
    data = temp / "data"

    for src in (ROOT / "apps").glob("*.conf"):
        (project / "apps" / src.name).write_bytes(src.read_bytes())
    (project / "config" / "categories.json").write_bytes(
        (ROOT / "config" / "categories.json").read_bytes()
    )

    out = temp / "catalog.json"
    subprocess.run(
        ["python3", "-S", str(ROOT / "scripts/generate_catalog.py"),
         str(project / "apps"), str(data), str(out)],
        check=True,
    )
    catalog = json.loads(out.read_text())

labels = {item["id"]: item["label"] for item in catalog["categories"]}

def visible(category="all", query=""):
    query = str(query).lower().strip()
    result = []
    for app in catalog["apps"]:
        if category != "all" and app["category"] != category:
            continue
        if query:
            values = [
                app.get("name", ""),
                app.get("id", ""),
                app.get("genericName", ""),
                app.get("comment", ""),
                app.get("category", ""),
                labels.get(app.get("category", ""), app.get("category", "")),
            ]
            if query not in " ".join(map(str, values)).lower():
                continue
        result.append(app)
    return result

assert visible("ai"), "AI category should contain apps"
assert all(a["category"] == "ai" for a in visible("ai"))
assert any(a["id"] == "gemini" for a in visible("all", "gemini"))
assert any(a["id"] == "gemini" for a in visible("ai", "google"))
assert not visible("streaming", "gemini")
assert len(visible("all", "")) == len(catalog["apps"])

print("PASS: v8 search/category filter logic works against the generated catalog")
