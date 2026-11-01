#!/usr/bin/env python3
"""Step 5a: move the month calendar and Bagi's message helpers out of main.dart.

    python tool/move_step5a.py
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"

CALENDAR_TARGET = ROOT / "lib" / "widgets" / "month_calendar.dart"
CALENDAR_HEADER = (
    "import 'package:flutter/material.dart';\n"
    "\n"
    "import '../data/store.dart';\n"
    "import '../models/activity_models.dart';\n"
    "\n"
    "// Month calendar with activity, homework and exam dots. Extracted from\n"
    "// lib/main.dart (step 5a of the split).\n"
)
CALENDAR_CLASSES = [
    "Bag2SchoolMonthCalendar",
    "_Bag2SchoolMonthCalendarState",
    "_CalendarWeekday",
    "_CalendarLegend",
]

MESSAGE_TARGET = ROOT / "lib" / "services" / "bagi_message.dart"
MESSAGE_HEADER = (
    "import 'package:supabase_flutter/supabase_flutter.dart';\n"
    "\n"
    "import '../data/store.dart';\n"
    "import '../models/family_models.dart';\n"
    "import 'bagi_identity_controller.dart';\n"
    "\n"
    "// Bagi's greeting helpers: who Bagi addresses and how {parent} is filled\n"
    "// in. Extracted from lib/main.dart (step 5a of the split).\n"
)
MESSAGE_FUNCS = [
    ("_bagiRoleFallbackName", "bagiRoleFallbackName"),
    ("_bagiNameFromEmail", "bagiNameFromEmail"),
    ("_bagiAccountAddressName", "bagiAccountAddressName"),
    ("_personalizeBagiMessage", "personalizeBagiMessage"),
]


def find_decl(lines: list[str], name: str, kind: str) -> tuple[int, int]:
    if kind == "class":
        pattern = re.compile(rf"^(?:abstract\s+)?class\s+{re.escape(name)}\b")
    else:
        pattern = re.compile(rf"^[A-Za-z_][\w<>,\?\[\]\s]*\s{re.escape(name)}\s*\(")

    for index, line in enumerate(lines):
        if not pattern.match(line):
            continue
        if kind == "func" and ("=>" in line or line.rstrip().endswith(";")):
            for end in range(index, len(lines)):
                if lines[end].rstrip().endswith(";"):
                    return index, end
        for end in range(index, len(lines)):
            if lines[end] == "}":
                return index, end
    raise SystemExit(f"{name}: declaration not found")


def rename(old: str, new: str) -> None:
    for path in (ROOT / "lib").rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        updated = re.sub(rf"\b{re.escape(old)}\b", new, text)
        if updated != text:
            path.write_text(updated, encoding="utf-8")


def extract(items: list[tuple[str, str, str]], target: pathlib.Path, header: str) -> None:
    """items: (old name, new name, kind)."""
    lines = MAIN.read_text(encoding="utf-8").split("\n")
    spans = []
    blocks = []

    for old, new, kind in items:
        start, end = find_decl(lines, old, kind)
        spans.append((start, end))
        block = "\n".join(lines[start : end + 1])
        blocks.append(re.sub(rf"\b{re.escape(old)}\b", new, block) if old != new else block)

    for start, end in sorted(spans, reverse=True):
        del lines[start : end + 1]
        if start < len(lines) and lines[start] == "":
            del lines[start]

    MAIN.write_text("\n".join(lines), encoding="utf-8")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(header + "\n" + "\n\n".join(blocks) + "\n", encoding="utf-8")

    for old, new, _ in items:
        if old != new:
            rename(old, new)

    print(f"wrote {target.relative_to(ROOT)}: {len(items)} declarations")


def main() -> None:
    extract(
        [(name, name, "class") for name in CALENDAR_CLASSES],
        CALENDAR_TARGET,
        CALENDAR_HEADER,
    )
    extract(
        [(old, new, "func") for old, new in MESSAGE_FUNCS],
        MESSAGE_TARGET,
        MESSAGE_HEADER,
    )

    text = MAIN.read_text(encoding="utf-8")
    anchor = "import 'widgets/list_items.dart';"
    if anchor in text:
        text = text.replace(
            anchor,
            anchor
            + "\nimport 'services/bagi_message.dart';"
            + "\nimport 'widgets/month_calendar.dart';",
            1,
        )
        MAIN.write_text(text, encoding="utf-8")

    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
