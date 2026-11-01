#!/usr/bin/env python3
"""Build a lightweight knowledge graph of the Bag2School Flutter code.

Stdlib only, regex based. It answers "what talks to what" without reading the
code into an LLM:

  graph/nodes.json                     machine readable nodes + edges
  graph/imports.dot                    Graphviz file level dependency graph
  docs/generated/architecture-map.md   tables and Mermaid diagrams

Run from the project root:

    python tool/build_knowledge_graph.py
"""

from __future__ import annotations

import json
import posixpath
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
GRAPH_DIR = ROOT / "graph"
DOCS_DIR = ROOT / "docs" / "generated"

CLASS_RE = re.compile(r"^(?:abstract\s+)?class\s+(\w+)([^{]*)\{", re.MULTILINE)
STATE_RE = re.compile(r"extends\s+State<(\w+)>")
METHOD_RE = re.compile(
    r"^  (?:static\s+)?(?:Future<[^>\n]*>|void|Widget|bool|String|int|double|"
    r"List<[^>\n]*>|Map<[^>\n]*>|Set<[^>\n]*>|\w+)\s+(\w+)\s*\(",
    re.MULTILINE,
)
IMPORT_RE = re.compile(r"^import\s+'([^']+)'", re.MULTILINE)
PAGE_RE = re.compile(r"\b(\w+Page)\b")
FROM_RE = re.compile(r"\.from\(\s*'([\w]+)'")
RPC_RE = re.compile(r"\.rpc\(\s*'([\w]+)'")
STORE_RE = re.compile(r"Bag2SchoolStore\.(\w+)")
PERMISSION_RE = re.compile(
    r"LocalAuthorization\.(canView|canEdit|canEditActive|authorizedView|"
    r"showDenied|requestViewAccess)"
)
DIALOG_RE = re.compile(r"showDialog|showModalBottomSheet|showGeneralDialog")
PREFS_RE = re.compile(r"SharedPreferences")
NAV_RE = re.compile(r"Navigator\.(?:push|pushReplacement|pushAndRemoveUntil)")


def strip_noise(text: str) -> str:
    """Remove comments and string bodies so brace counting stays sane."""
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    text = re.sub(r"//[^\n]*", "", text)
    return text


def brace_end(text: str, start: int) -> int:
    depth = 0
    for index in range(start, len(text)):
        char = text[index]
        if char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
    return len(text) - 1


def line_of(text: str, index: int) -> int:
    return text.count("\n", 0, index) + 1


def analyse_file(path: Path) -> dict:
    raw = path.read_text(encoding="utf-8", errors="replace")
    clean = strip_noise(raw)
    relative = path.relative_to(ROOT).as_posix()

    classes = []
    for match in CLASS_RE.finditer(clean):
        name = match.group(1)
        header = match.group(2)
        start = match.start()
        end = brace_end(clean, match.end() - 1)
        body = clean[start : end + 1]
        extends_state = STATE_RE.search(header.strip())

        classes.append(
            {
                "name": name,
                "file": relative,
                "startLine": line_of(clean, start),
                "endLine": line_of(clean, end),
                "lines": line_of(clean, end) - line_of(clean, start) + 1,
                "widgetOf": extends_state.group(1) if extends_state else None,
                "methods": METHOD_RE.findall(body),
                "methodLines": [
                    {"name": item.group(1), "line": line_of(clean, start + item.start())}
                    for item in METHOD_RE.finditer(body)
                ],
                "storeRefs": len(STORE_RE.findall(body)),
                "dialogs": len(DIALOG_RE.findall(body)),
                "permissions": len(PERMISSION_RE.findall(body)),
                "navigations": sorted(
                    {
                        page
                        for nav in NAV_RE.finditer(body)
                        for page in PAGE_RE.findall(
                            body[nav.start() : nav.start() + 400]
                        )
                        if page != name
                    }
                ),
                "supabaseTables": sorted(set(FROM_RE.findall(body))),
                "supabaseRpc": sorted(set(RPC_RE.findall(body))),
            }
        )

    imports = [
        target
        for target in IMPORT_RE.findall(raw)
        if not target.startswith(("dart:", "package:flutter", "package:supabase"))
        and not target.startswith("package:shared_preferences")
        and not target.startswith("package:app_links")
    ]

    return {
        "path": relative,
        "lines": raw.count("\n") + 1,
        "kb": round(path.stat().st_size / 1024),
        "classes": classes,
        "imports": imports,
        "usesPrefs": bool(PREFS_RE.search(raw)),
        "tables": sorted(set(FROM_RE.findall(raw))),
        "rpc": sorted(set(RPC_RE.findall(raw))),
    }


def build_edges(files: list[dict]) -> list[dict]:
    edges = []

    def add(source: str, target: str, kind: str, count: int = 1) -> None:
        for edge in edges:
            if edge["from"] == source and edge["to"] == target and edge["kind"] == kind:
                edge["count"] += count
                return
        edges.append({"from": source, "to": target, "kind": kind, "count": count})

    by_path = {entry["path"]: entry for entry in files}

    def resolve(source: str, target: str) -> str | None:
        """Turn an import string into a lib/ path, or None."""
        if target.startswith("."):
            resolved = posixpath.normpath(
                posixpath.join(posixpath.dirname(source), target)
            )
        else:
            resolved = f"lib/{target}"
        return resolved if resolved in by_path else None

    for entry in files:
        for target in entry["imports"]:
            resolved = resolve(entry["path"], target)
            if resolved:
                add(entry["path"], resolved, "import")

        for cls in entry["classes"]:
            if cls["widgetOf"]:
                add(cls["name"], cls["widgetOf"], "state_of")
            for page in cls["navigations"]:
                add(cls["name"], page, "navigate")
            for table in cls["supabaseTables"]:
                add(cls["name"], f"table:{table}", "reads_table")
            for function in cls["supabaseRpc"]:
                add(cls["name"], f"rpc:{function}", "calls_rpc")
            if cls["storeRefs"]:
                add(cls["name"], "Bag2SchoolStore", "uses_state", cls["storeRefs"])

    return edges


def sanitize(name: str) -> str:
    return re.sub(r"\W", "_", name)


def mermaid_flow(nodes: list[str], edges: list[tuple[str, str]], direction: str = "TD") -> str:
    lines = [f"flowchart {direction}"]
    for node in nodes:
        lines.append(f'  {sanitize(node)}["{node}"]')
    for source, target in edges:
        lines.append(f"  {sanitize(source)} --> {sanitize(target)}")
    return "\n".join(lines)


def write_graphviz(files: list[dict]) -> None:
    by_path = {entry["path"]: entry for entry in files}
    lines = ["digraph bag2school {", "  rankdir=LR;", "  node [shape=box, fontsize=10];"]

    for entry in files:
        cls_count = len(entry["classes"])
        lines.append(
            f'  "{entry["path"]}" [label="{Path(entry["path"]).name}\\n'
            f'{entry["lines"]}L / {cls_count} classes"];'
        )

    for entry in files:
        for target in entry["imports"]:
            for candidate in by_path:
                if candidate.endswith(target):
                    lines.append(f'  "{entry["path"]}" -> "{candidate}";')
                    break

    lines.append("}")
    (GRAPH_DIR / "imports.dot").write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_markdown(files: list[dict], edges: list[dict]) -> None:
    classes = [cls for entry in files for cls in entry["classes"]]
    classes.sort(key=lambda cls: cls["lines"], reverse=True)

    files_sorted = sorted(files, key=lambda entry: entry["lines"], reverse=True)

    navigation = sorted(
        {(edge["from"], edge["to"]) for edge in edges if edge["kind"] == "navigate"}
    )
    import_edges = sorted(
        {(edge["from"], edge["to"]) for edge in edges if edge["kind"] == "import"}
    )

    heavy_state = sorted(classes, key=lambda cls: cls["storeRefs"], reverse=True)[:15]
    dialog_hotspots = sorted(classes, key=lambda cls: cls["dialogs"], reverse=True)[:10]

    tables: dict[str, set[str]] = {}
    for entry in files:
        for table in entry["tables"]:
            tables.setdefault(table, set()).add(Path(entry["path"]).name)

    out = []
    out.append("# Architecture map (generated)\n")
    out.append(
        "Dihasilkan oleh `tool/build_knowledge_graph.py`. Jangan mengedit manual; "
        "jalankan ulang script setelah kode berubah.\n"
    )
    out.append(
        f"**{len(files)} file Â· {sum(entry['lines'] for entry in files):,} baris Â· "
        f"{len(classes)} class Â· {len(edges)} edge**\n"
    )

    out.append("## 1. Berkas\n")
    out.append("| Berkas | Baris | KB | Class | Method | State refs | Dialog |")
    out.append("|---|---:|---:|---:|---:|---:|---:|")
    for entry in files_sorted:
        methods = sum(len(cls["methods"]) for cls in entry["classes"])
        refs = sum(cls["storeRefs"] for cls in entry["classes"])
        dialogs = sum(cls["dialogs"] for cls in entry["classes"])
        out.append(
            f"| `{entry['path']}` | {entry['lines']:,} | {entry['kb']} | "
            f"{len(entry['classes'])} | {methods} | {refs} | {dialogs} |"
        )
    out.append("")

    out.append("## 2. Class terbesar\n")
    out.append("| Class | Berkas | Baris | Method | State refs |")
    out.append("|---|---|---:|---:|---:|")
    for cls in classes[:20]:
        out.append(
            f"| `{cls['name']}` | `{Path(cls['file']).name}` | {cls['lines']} | "
            f"{len(cls['methods'])} | {cls['storeRefs']} |"
        )
    out.append("")

    out.append("## 3. Import antar berkas\n")
    out.append("```mermaid")
    out.append(
        mermaid_flow(
            sorted({path for pair in import_edges for path in pair}),
            import_edges,
            "LR",
        )
    )
    out.append("```\n")

    out.append("## 4. Navigasi (class â†’ halaman)\n")
    out.append("```mermaid")
    out.append(mermaid_flow(sorted({name for pair in navigation for name in pair}), navigation))
    out.append("```\n")

    out.append("## 5. Ketergantungan state global\n")
    out.append(
        "Semakin besar angkanya, semakin sulit class itu dipindah tanpa refactor.\n"
    )
    out.append("| Class | State refs | Dialog | Permission check |")
    out.append("|---|---:|---:|---:|")
    for cls in heavy_state:
        out.append(
            f"| `{cls['name']}` | {cls['storeRefs']} | {cls['dialogs']} | "
            f"{cls['permissions']} |"
        )
    out.append("")

    out.append("## 6. Hotspot dialog\n")
    out.append("| Class | Dialog / sheet |")
    out.append("|---|---:|")
    for cls in dialog_hotspots:
        out.append(f"| `{cls['name']}` | {cls['dialogs']} |")
    out.append("")

    out.append("## 7. Permukaan Supabase\n")
    out.append("| Tabel / RPC | Dipakai di |")
    out.append("|---|---|")
    for table in sorted(tables):
        out.append(f"| `{table}` | {', '.join(sorted(tables[table]))} |")
    rpcs: dict[str, set[str]] = {}
    for entry in files:
        for function in entry["rpc"]:
            rpcs.setdefault(function, set()).add(Path(entry["path"]).name)
    for function in sorted(rpcs):
        out.append(f"| `rpc:{function}` | {', '.join(sorted(rpcs[function]))} |")
    out.append("")

    (DOCS_DIR / "architecture-map.md").write_text("\n".join(out) + "\n", encoding="utf-8")


def main() -> None:
    GRAPH_DIR.mkdir(exist_ok=True)
    DOCS_DIR.mkdir(parents=True, exist_ok=True)

    files = [analyse_file(path) for path in sorted(LIB.rglob("*.dart"))]
    edges = build_edges(files)

    (GRAPH_DIR / "nodes.json").write_text(
        json.dumps({"files": files, "edges": edges}, indent=2)[:0]
        + json.dumps({"files": files, "edges": edges}, indent=1),
        encoding="utf-8",
    )
    write_graphviz(files)
    write_markdown(files, edges)

    classes = sum(len(entry["classes"]) for entry in files)
    print(f"files={len(files)} classes={classes} edges={len(edges)}")
    print(f"wrote {GRAPH_DIR / 'nodes.json'}")
    print(f"wrote {GRAPH_DIR / 'imports.dot'}")
    print(f"wrote {DOCS_DIR / 'architecture-map.md'}")


if __name__ == "__main__":
    main()
