#!/usr/bin/env python3
"""Step 5b-6: move the schedule screen and its activity forms out of main.dart.

Also relocates PreparationChecklistItem into the preparation feature, because
both Schedule and Preparation use it.

    python tool/move_schedule.py
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"

SCHEDULE_TARGET = ROOT / "lib" / "features" / "schedule" / "schedule_page.dart"
SCHEDULE_CLASSES = [
    ("SchedulePage", 60),
    ("_SchedulePageState", 3600),
    ("ScheduleTimelineItem", 60),
    ("_ScheduleTimelineItemState", 400),
    ("_BagiConflictCard", 300),
    ("SchoolActivityForm", 60),
    ("_SchoolActivityFormState", 900),
    ("LessonActivityForm", 60),
    ("_LessonActivityFormState", 1000),
    ("ExamActivityForm", 60),
    ("_ExamActivityFormState", 500),
    ("EventActivityForm", 60),
    ("_EventActivityFormState", 500),
    ("ExtracurricularActivityForm", 60),
    ("_ExtracurricularActivityFormState", 1000),
]

PREP_TARGET = ROOT / "lib" / "features" / "preparation" / "preparation_page.dart"
PREP_CLASSES = [
    ("PreparationChecklistItem", 60),
    ("_PreparationChecklistItemState", 300),
]

SCHEDULE_HEADER = (
    "import 'dart:async';\n"
    "import 'dart:math';\n"
    "\n"
    "import 'package:flutter/material.dart';\n"
    "\n"
    "import '../../data/store.dart';\n"
    "import '../../main.dart';\n"
    "import '../../models/activity_models.dart';\n"
    "import '../../models/child_profile.dart';\n"
    "import '../../models/family_models.dart';\n"
    "import '../../services/bagi_greeting_service.dart';\n"
    "import '../../services/bagi_message.dart';\n"
    "import '../../theme/bag2school_tokens.dart';\n"
    "import '../../utils/controllers.dart';\n"
    "import '../../utils/focus.dart';\n"
    "import '../../widgets/app_notification.dart';\n"
    "import '../../widgets/bagi_character.dart';\n"
    "import '../../widgets/bagi_tutorial_overlay.dart';\n"
    "import '../../widgets/bubble_tail_painters.dart';\n"
    "import '../../widgets/child_avatar.dart';\n"
    "import '../../widgets/list_items.dart';\n"
    "import '../../widgets/month_calendar.dart';\n"
    "import '../homework/homework_page.dart';\n"
    "import '../preparation/preparation_page.dart';\n"
    "import '../settings/settings_page.dart';\n"
    "\n"
    "// Schedule screen: timeline, calendar entry point and the five activity\n"
    "// forms. Extracted from lib/main.dart (step 5b).\n"
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


def extract(classes: list[tuple[str, int]]) -> tuple[list[str], list[tuple[int, int]]]:
    lines = MAIN.read_text(encoding="utf-8").split("\n")
    spans = []
    blocks = []

    for name, limit in classes:
        start, end = find_class(lines, name)
        size = end - start + 1
        if size > limit:
            raise SystemExit(f"{name}: {size} lines exceeds the {limit} guard")
        spans.append((start, end))
        blocks.append("\n".join(lines[start : end + 1]))
        print(f"  {name:34} {start + 1:6}-{end + 1:6} ({size} lines)")

    for start, end in sorted(spans, reverse=True):
        del lines[start : end + 1]
        if start < len(lines) and lines[start] == "":
            del lines[start]

    MAIN.write_text("\n".join(lines), encoding="utf-8")
    return blocks, spans


def main() -> None:
    print("extracting schedule:")
    schedule_blocks, _ = extract(SCHEDULE_CLASSES)

    print("\nextracting preparation checklist:")
    prep_blocks, _ = extract(PREP_CLASSES)

    SCHEDULE_TARGET.parent.mkdir(parents=True, exist_ok=True)
    SCHEDULE_TARGET.write_text(
        SCHEDULE_HEADER + "\n" + "\n\n".join(schedule_blocks) + "\n",
        encoding="utf-8",
    )

    prep_text = PREP_TARGET.read_text(encoding="utf-8").rstrip()
    PREP_TARGET.write_text(
        prep_text + "\n\n" + "\n\n".join(prep_blocks) + "\n", encoding="utf-8"
    )

    text = MAIN.read_text(encoding="utf-8")
    anchor = "import 'features/homework/homework_page.dart';"
    if anchor in text and "features/schedule/schedule_page.dart" not in text:
        text = text.replace(
            anchor,
            anchor + "\nimport 'features/preparation/preparation_page.dart';"
            + "\nimport 'features/schedule/schedule_page.dart';",
            1,
        )
        MAIN.write_text(text, encoding="utf-8")

    print(f"\nwrote {SCHEDULE_TARGET.relative_to(ROOT)}")
    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
