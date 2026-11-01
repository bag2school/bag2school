#!/usr/bin/env python3
"""Step 5b-1: move three independent screens out of main.dart.

FamilyActivityPage, LocalAccountPage and HomeworkHistoryPage do not reference
the other screens, so they can leave first.

    python tool/move_pages_1.py
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"

COMMON_HEADER = (
    "import 'package:flutter/material.dart';\n"
    "\n"
    "import '../../data/store.dart';\n"
    "import '../../models/activity_models.dart';\n"
    "import '../../models/family_models.dart';\n"
    "import '../../widgets/app_notification.dart';\n"
    "\n"
)

GROUPS = [
    (
        "lib/features/family/family_activity_page.dart",
        ["FamilyActivityPage", "_FamilyActivityPageState"],
        COMMON_HEADER + "// Family activity inbox. Extracted from lib/main.dart.\n",
    ),
    (
        "lib/features/settings/local_account_page.dart",
        ["LocalAccountPage", "_LocalAccountPageState"],
        COMMON_HEADER + "// Account screen reached from Settings.\n",
    ),
    (
        "lib/features/homework/homework_history_page.dart",
        ["HomeworkHistoryPage"],
        COMMON_HEADER + "// Completed and overdue homework list.\n",
    ),
]


def find_class(lines: list[str], name: str) -> tuple[int, int]:
    pattern = re.compile(rf"^(?:abstract\s+)?class\s+{re.escape(name)}\b")
    for index, line in enumerate(lines):
        if pattern.match(line):
            for end in range(index, len(lines)):
                if lines[end] == "}":
                    return index, end
            raise SystemExit(f"{name}: no closing brace")
    raise SystemExit(f"{name}: not found")


def main() -> None:
    for target, classes, header in GROUPS:
        lines = MAIN.read_text(encoding="utf-8").split("\n")
        spans = [find_class(lines, name) for name in classes]
        blocks = ["\n".join(lines[start : end + 1]) for start, end in spans]

        for start, end in sorted(spans, reverse=True):
            del lines[start : end + 1]
            if start < len(lines) and lines[start] == "":
                del lines[start]

        MAIN.write_text("\n".join(lines), encoding="utf-8")

        path = ROOT / target
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(header + "\n" + "\n\n".join(blocks) + "\n", encoding="utf-8")
        print(f"wrote {target}: {len(blocks)} declarations")

    text = MAIN.read_text(encoding="utf-8")
    anchor = "import 'widgets/month_calendar.dart';"
    additions = [
        "import 'features/family/family_activity_page.dart';",
        "import 'features/homework/homework_history_page.dart';",
        "import 'features/settings/local_account_page.dart';",
    ]
    if anchor in text:
        text = text.replace(anchor, anchor + "\n" + "\n".join(additions), 1)
        MAIN.write_text(text, encoding="utf-8")

    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
