#!/usr/bin/env python3
"""Generate Obsidian assets from the knowledge graph.

Outputs:
  docs/features/*.md      one note per feature, with wiki links
  graph/bag2school.canvas Obsidian Canvas map of the code base

Run after tool/build_knowledge_graph.py:

    python tool/build_knowledge_graph.py
    python tool/build_obsidian.py
"""

from __future__ import annotations

import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
DATA = ROOT / "graph" / "nodes.json"
DOCS = ROOT / "docs"
FEATURES = DOCS / "features"
CANVAS = ROOT / "graph" / "bag2school.canvas"

# folder -> (title, canvas column, colour)
GROUPS = {
    "lib/models": ("Model data", 0, "6"),
    "lib/data": ("Store & serializer", 1, "6"),
    "lib/services": ("Service", 2, "5"),
    "lib/widgets": ("Widget bersama", 3, "5"),
    "lib/utils": ("Utilitas", 3, "5"),
    "lib/theme": ("Tema", 3, "5"),
    "lib/features/home": ("Home", 4, "4"),
    "lib/features/schedule": ("Schedule", 5, "1"),
    "lib/features/homework": ("Homework", 6, "1"),
    "lib/features/preparation": ("Preparation", 7, "1"),
    "lib/features/settings": ("Settings", 8, "3"),
    "lib/features/family": ("Family", 9, "3"),
    "": ("Aplikasi & auth", 10, "2"),
}

FEATURE_ORDER = [
    "home",
    "schedule",
    "homework",
    "preparation",
    "settings",
    "family",
]


def group_of(path: str) -> str:
    folder = pathlib.PurePosixPath(path).parent.as_posix()
    if folder in GROUPS:
        return folder
    if folder.startswith("lib/features"):
        return folder
    return ""


def load() -> dict:
    return json.loads(DATA.read_text(encoding="utf-8"))


def write_feature_notes(data: dict) -> None:
    FEATURES.mkdir(parents=True, exist_ok=True)

    edges = data["edges"]
    files = {entry["path"]: entry for entry in data["files"]}

    for feature in FEATURE_ORDER:
        folder = f"lib/features/{feature}"
        members = [entry for entry in data["files"] if entry["path"].startswith(folder + "/")]

        lines = [f"# {feature.title()}", ""]
        lines.append(
            "Layar dan widget untuk fitur ini. Dibuat otomatis oleh "
            "`tool/build_obsidian.py`; jangan diedit manual."
        )
        lines.append("")
        lines.append(f"Balik ke [[knowledge-graph]] · konteks AI: [[AI_CONTEXT]]")
        lines.append("")

        lines.append("## Berkas")
        lines.append("")
        lines.append("| Berkas | Baris | Class |")
        lines.append("|---|---:|---|")
        for entry in sorted(members, key=lambda item: -item["lines"]):
            names = ", ".join(f"`{cls['name']}`" for cls in entry["classes"])
            lines.append(
                f"| [[{entry['path']}]] | {entry['lines']:,} | {names or '-'} |"
            )
        lines.append("")

        used_by = set()
        depends_on = set()
        member_paths = {entry["path"] for entry in members}
        for edge in edges:
            if edge["kind"] != "import":
                continue
            source, target = edge["from"], edge["to"]
            if source in member_paths and target not in member_paths:
                depends_on.add(target)
            if target in member_paths and source not in member_paths:
                used_by.add(source)

        lines.append("## Bergantung pada")
        lines.append("")
        for path in sorted(depends_on):
            lines.append(f"- [[{path}]]")
        lines.append("")

        lines.append("## Dipakai oleh")
        lines.append("")
        for path in sorted(used_by):
            lines.append(f"- [[{path}]]")
        lines.append("")

        others = [name for name in FEATURE_ORDER if name != feature]
        lines.append("## Fitur lain")
        lines.append("")
        lines.append(" · ".join(f"[[features/{name}]]" for name in others))
        lines.append("")

        (FEATURES / f"{feature}.md").write_text("\n".join(lines), encoding="utf-8")
        print(f"wrote docs/features/{feature}.md")


def write_canvas(data: dict) -> None:
    nodes = []
    edges = []

    columns: dict[str, list[dict]] = {}
    for entry in data["files"]:
        columns.setdefault(group_of(entry["path"]), []).append(entry)

    file_node: dict[str, str] = {}
    counter = 0

    for folder, items in columns.items():
        title, column, colour = GROUPS.get(folder, ("Lainnya", 11, "5"))
        x = column * 420
        y = 0

        nodes.append(
            {
                "id": f"group-{column}",
                "type": "text",
                "text": f"**{title}**",
                "x": x,
                "y": y - 70,
                "width": 380,
                "height": 50,
                "color": colour,
            }
        )

        y += 10
        for entry in sorted(items, key=lambda item: -item["lines"]):
            counter += 1
            name = pathlib.PurePosixPath(entry["path"]).name
            classes = [cls["name"] for cls in entry["classes"]]
            preview = ", ".join(classes[:3])
            if len(classes) > 3:
                preview += f" +{len(classes) - 3}"
            text = f"**{name}**\n{entry['lines']:,} baris\n{preview}"

            node_id = f"n{counter}"
            file_node[entry["path"]] = node_id
            nodes.append(
                {
                    "id": node_id,
                    "type": "text",
                    "text": text,
                    "x": x,
                    "y": y,
                    "width": 380,
                    "height": 120,
                    "color": colour,
                }
            )
            y += 140

    index = 0
    for edge in data["edges"]:
        if edge["kind"] != "import":
            continue
        source = file_node.get(edge["from"])
        target = file_node.get(edge["to"])
        if not source or not target:
            continue
        index += 1
        edges.append(
            {
                "id": f"e{index}",
                "fromNode": source,
                "fromSide": "right",
                "toNode": target,
                "toSide": "left",
                "label": "",
            }
        )

    CANVAS.write_text(
        json.dumps({"nodes": nodes, "edges": edges}, indent=1), encoding="utf-8"
    )
    print(f"wrote {CANVAS.relative_to(ROOT)}: {len(nodes)} nodes, {len(edges)} edges")


def main() -> None:
    data = load()
    write_feature_notes(data)
    write_canvas(data)


if __name__ == "__main__":
    main()
