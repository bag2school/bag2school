#!/usr/bin/env python3
"""Finish the Preparation extraction: move its private helper classes too."""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"
TARGET = ROOT / "lib" / "features" / "preparation" / "preparation_page.dart"

CLASSES = [
    ("_PreparationGroup", 60),
    ("_PreparationOfferCard", 60),
    ("_PreparationOfferCardState", 900),
]


def find_class(lines: list[str], name: str) -> tuple[int, int]:
    pattern = re.compile(rf"^(?:abstract\s+)?class\s+{re.escape(name)}\b")
    matches = [i for i, line in enumerate(lines) if pattern.match(line)]
    if len(matches) != 1:
        raise SystemExit(f"{name}: expected one declaration, found {len(matches)}")
    index = matches[0]
    for end in range(index, len(lines)):
        if lines[end] == "}":
            return index, end
    raise SystemExit(f"{name}: closing brace not found")


def main() -> None:
    lines = MAIN.read_text(encoding="utf-8").split("\n")
    spans = []
    blocks = []

    for name, limit in CLASSES:
        start, end = find_class(lines, name)
        size = end - start + 1
        if size > limit:
            raise SystemExit(f"{name}: {size} lines exceeds the {limit} guard")
        spans.append((start, end))
        blocks.append("\n".join(lines[start : end + 1]))
        print(f"  {name:30} {start + 1:6}-{end + 1:6} ({size} lines)")

    for start, end in sorted(spans, reverse=True):
        del lines[start : end + 1]
        if start < len(lines) and lines[start] == "":
            del lines[start]

    MAIN.write_text("\n".join(lines), encoding="utf-8")

    text = TARGET.read_text(encoding="utf-8")
    text = text.rstrip() + "\n\n" + "\n\n".join(blocks) + "\n"
    if "bagi_greeting_service.dart" not in text:
        text = text.replace(
            "import '../../services/bagi_message.dart';",
            "import '../../services/bagi_greeting_service.dart';\n"
            "import '../../services/bagi_message.dart';",
            1,
        )
    TARGET.write_text(text, encoding="utf-8")

    print(f"preparation_page.dart now {text.count(chr(10)) + 1} lines")
    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
