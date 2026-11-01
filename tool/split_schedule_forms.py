#!/usr/bin/env python3
"""Split the five activity forms out of schedule_page.dart.

Each form keeps its State class in the same file. schedule_page.dart imports
them afterwards.

    python tool/split_schedule_forms.py
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
SOURCE = ROOT / "lib" / "features" / "schedule" / "schedule_page.dart"
FORMS = ROOT / "lib" / "features" / "schedule" / "forms"

HEADER = (
    "import 'dart:async';\n"
    "\n"
    "import 'package:flutter/material.dart';\n"
    "\n"
    "import '../../../data/store.dart';\n"
    "import '../../../models/activity_models.dart';\n"
    "import '../../../models/family_models.dart';\n"
    "import '../../../services/bagi_message.dart';\n"
    "import '../../../theme/bag2school_tokens.dart';\n"
    "import '../../../widgets/app_notification.dart';\n"
    "import '../../../widgets/bagi_character.dart';\n"
    "import '../../../widgets/child_avatar.dart';\n"
    "\n"
)

GROUPS = [
    ("school_activity_form.dart", "SchoolActivityForm", "_SchoolActivityFormState", 900),
    ("lesson_activity_form.dart", "LessonActivityForm", "_LessonActivityFormState", 1000),
    ("exam_activity_form.dart", "ExamActivityForm", "_ExamActivityFormState", 500),
    ("event_activity_form.dart", "EventActivityForm", "_EventActivityFormState", 500),
    (
        "extracurricular_activity_form.dart",
        "ExtracurricularActivityForm",
        "_ExtracurricularActivityFormState",
        1000,
    ),
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
    lines = SOURCE.read_text(encoding="utf-8").split("\n")
    spans: list[tuple[int, int]] = []
    outputs: list[tuple[str, list[str]]] = []

    for filename, widget, state, limit in GROUPS:
        blocks = []
        for name in (widget, state):
            start, end = find_class(lines, name)
            size = end - start + 1
            if size > limit:
                raise SystemExit(f"{name}: {size} lines exceeds the {limit} guard")
            spans.append((start, end))
            blocks.append("\n".join(lines[start : end + 1]))
        outputs.append((filename, blocks))
        print(f"  {filename:42} {sum(len(b.splitlines()) for b in blocks):5} lines")

    for start, end in sorted(spans, reverse=True):
        del lines[start : end + 1]
        if start < len(lines) and lines[start] == "":
            del lines[start]

    import_block = "\n".join(
        f"import 'forms/{filename}';" for filename, _ in outputs
    )
    text = "\n".join(lines).rstrip() + "\n"
    anchor = "import '../homework/homework_page.dart';"
    if anchor not in text:
        raise SystemExit("anchor import not found")
    text = text.replace(anchor, anchor + "\n" + import_block, 1)
    SOURCE.write_text(text, encoding="utf-8")

    FORMS.mkdir(parents=True, exist_ok=True)
    for filename, blocks in outputs:
        (FORMS / filename).write_text(
            HEADER + "\n".join(blocks) + "\n", encoding="utf-8"
        )

    print(f"\nschedule_page.dart now {SOURCE.read_text(encoding='utf-8').count(chr(10)) + 1} lines")
    print(f"forms written: {len(outputs)}")


if __name__ == "__main__":
    main()
