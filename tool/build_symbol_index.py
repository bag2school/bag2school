#!/usr/bin/env python3
"""Build docs/SYMBOL_INDEX.md from graph/nodes.json.

A compact lookup table: method name -> class + line. Designed to be grepped
instead of loading the whole JSON.

    python tool/build_knowledge_graph.py
    python tool/build_symbol_index.py
"""

from __future__ import annotations

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
DATA = ROOT / "graph" / "nodes.json"
TARGET = ROOT / "docs" / "SYMBOL_INDEX.md"


def main() -> None:
    data = json.loads(DATA.read_text(encoding="utf-8"))

    rows = 0
    out = [
        "# Symbol index (generated)",
        "",
        "Tabel `method -> class -> baris`. Hasil generate `tool/build_symbol_index.py`;",
        "jangan diedit manual. Gunakan `grep` untuk mencari, bukan membuka JSON.",
        "",
        f"**{len(data['files'])} berkas · "
        f"{sum(len(entry['classes']) for entry in data['files'])} class**",
        "",
    ]

    for entry in sorted(data["files"], key=lambda item: item["path"]):
        classes = sorted(entry["classes"], key=lambda item: item["startLine"])
        if not any(cls["methods"] for cls in classes):
            continue

        out.append(f"## `{entry['path']}`")
        out.append("")
        out.append("| Method | Class | Baris |")
        out.append("|---|---|---:|")
        for cls in classes:
            for line in cls["methodLines"]:
                out.append(f"| `{line['name']}` | `{cls['name']}` | {line['line']} |")
                rows += 1
        out.append("")

    TARGET.write_text("\n".join(out) + "\n", encoding="utf-8")
    kb = TARGET.stat().st_size / 1024
    print(f"wrote docs/SYMBOL_INDEX.md: {rows} methods, {kb:.1f} KB")


if __name__ == "__main__":
    main()
