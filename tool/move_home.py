#!/usr/bin/env python3
"""Step 6: move HomePage out of main.dart (the last screen)."""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"
TARGET = ROOT / "lib" / "features" / "home" / "home_page.dart"

CLASSES = [
    ("HomePage", 60),
    ("_HomePageState", 3600),
    ("Bag2SchoolLogo", 60),
]

HEADER = (
    "import 'dart:async';\n"
    "\n"
    "import 'package:flutter/material.dart';\n"
    "\n"
    "import '../../data/store.dart';\n"
    "import '../../models/activity_models.dart';\n"
    "import '../../models/family_models.dart';\n"
    "import '../../services/bagi_greeting_service.dart';\n"
    "import '../../services/bagi_message.dart';\n"
    "import '../../services/reminder_content.dart';\n"
    "import '../../services/reminder_service.dart';\n"
    "import '../../theme/bag2school_tokens.dart';\n"
    "import '../../utils/controllers.dart';\n"
    "import '../../utils/focus.dart';\n"
    "import '../../widgets/app_notification.dart';\n"
    "import '../../widgets/bagi_character.dart';\n"
    "import '../../widgets/bubble_tail_painters.dart';\n"
    "import '../../widgets/child_avatar.dart';\n"
    "import '../../widgets/list_items.dart';\n"
    "import '../family/family_activity_page.dart';\n"
    "import '../homework/homework_page.dart';\n"
    "import '../preparation/preparation_page.dart';\n"
    "import '../schedule/schedule_page.dart';\n"
    "import '../settings/settings_page.dart';\n"
    "\n"
    "// Home: today and tomorrow at a glance, readiness card and shortcuts.\n"
    "// Extracted from lib/main.dart (step 6).\n"
)


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
        print(f"  {name:24} {start + 1:6}-{end + 1:6} ({size} lines)")

    for start, end in sorted(spans, reverse=True):
        del lines[start : end + 1]
        if start < len(lines) and lines[start] == "":
            del lines[start]

    MAIN.write_text("\n".join(lines), encoding="utf-8")

    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(HEADER + "\n" + "\n\n".join(blocks) + "\n", encoding="utf-8")

    text = MAIN.read_text(encoding="utf-8")
    anchor = "import 'features/schedule/schedule_page.dart';"
    if anchor in text and "features/home/home_page.dart" not in text:
        text = text.replace(anchor, anchor + "\nimport 'features/home/home_page.dart';", 1)
        MAIN.write_text(text, encoding="utf-8")

    print(f"\nwrote {TARGET.relative_to(ROOT)}")
    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
