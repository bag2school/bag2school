#!/usr/bin/env python3
"""Move the small self contained widgets out of main.dart (step 4).

    python tool/move_small_widgets.py
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"

GROUPS: dict[str, tuple[list[tuple[str, str]], str]] = {
    "lib/widgets/bubble_tail_painters.dart": (
        [
            ("_BagiBubbleTailPainter", "BagiBubbleTailPainter"),
            ("_BagiHomeBubbleTailPainter", "BagiHomeBubbleTailPainter"),
            ("_OrangeBubbleTailPainter", "OrangeBubbleTailPainter"),
            ("_PreparationBubbleTailPainter", "PreparationBubbleTailPainter"),
        ],
        "import 'package:flutter/material.dart';\n\n"
        "// Speech bubble tails used by Bagi's bubbles on Home, Schedule,\n"
        "// Homework and Preparation. Extracted from lib/main.dart.\n",
    ),
    "lib/widgets/list_items.dart": (
        [
            ("_ActionIconButton", "ActionIconButton"),
            ("ScheduleItem", "ScheduleItem"),
            ("TodoItem", "TodoItem"),
            ("BagiTip", "BagiTip"),
        ],
        "import 'package:flutter/material.dart';\n\n"
        "// Small reusable row widgets and Bagi's tip card. Extracted from\n"
        "// lib/main.dart.\n",
    ),
}


def find_class(lines: list[str], name: str) -> tuple[int, int]:
    pattern = re.compile(rf"^(?:abstract\s+)?class\s+{re.escape(name)}\b")
    for index, line in enumerate(lines):
        if pattern.match(line):
            for end in range(index, len(lines)):
                if lines[end] == "}":
                    return index, end
            raise SystemExit(f"{name}: no closing brace")
    raise SystemExit(f"{name}: not found")


def rename(old: str, new: str) -> None:
    for path in (ROOT / "lib").rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        updated = re.sub(rf"\b{re.escape(old)}\b", new, text)
        if updated != text:
            path.write_text(updated, encoding="utf-8")


def main() -> None:
    for target, (pairs, header) in GROUPS.items():
        lines = MAIN.read_text(encoding="utf-8").split("\n")
        spans = []
        blocks = []

        for old, new in pairs:
            start, end = find_class(lines, old)
            spans.append((start, end))
            block = "\n".join(lines[start : end + 1])
            blocks.append(re.sub(rf"\b{re.escape(old)}\b", new, block))

        for start, end in sorted(spans, reverse=True):
            del lines[start : end + 1]
            if start < len(lines) and lines[start] == "":
                del lines[start]

        MAIN.write_text("\n".join(lines), encoding="utf-8")

        path = ROOT / target
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(header + "\n" + "\n\n".join(blocks) + "\n", encoding="utf-8")

        for old, new in pairs:
            rename(old, new)

        print(f"wrote {target}: {len(pairs)} declarations")

    # main.dart no longer defines them, so import the new files.
    text = MAIN.read_text(encoding="utf-8")
    anchor = "import 'widgets/app_notification.dart';"
    if anchor in text and "widgets/list_items.dart" not in text:
        text = text.replace(
            anchor,
            anchor
            + "\nimport 'widgets/bubble_tail_painters.dart';"
            + "\nimport 'widgets/list_items.dart';",
            1,
        )
        MAIN.write_text(text, encoding="utf-8")

    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
