#!/usr/bin/env python3
"""Finish the forms split: share the conflict card and the focus helper."""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
SCHEDULE = ROOT / "lib" / "features" / "schedule" / "schedule_page.dart"
CARD = ROOT / "lib" / "features" / "schedule" / "widgets" / "conflict_card.dart"
FORMS = ROOT / "lib" / "features" / "schedule" / "forms"

CARD_HEADER = (
    "import 'package:flutter/material.dart';\n"
    "\n"
    "import '../../../models/activity_models.dart';\n"
    "import '../../../theme/bag2school_tokens.dart';\n"
    "\n"
    "// Conflict banner shown by the activity forms.\n"
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


def rename(old: str, new: str) -> None:
    for path in (ROOT / "lib").rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        updated = re.sub(rf"\b{re.escape(old)}\b", new, text)
        if updated != text:
            path.write_text(updated, encoding="utf-8")


def main() -> None:
    lines = SCHEDULE.read_text(encoding="utf-8").split("\n")
    start, end = find_class(lines, "_BagiConflictCard")
    block = "\n".join(lines[start : end + 1])
    del lines[start : end + 1]
    if start < len(lines) and lines[start] == "":
        del lines[start]

    CARD.parent.mkdir(parents=True, exist_ok=True)
    CARD.write_text(CARD_HEADER + "\n" + block + "\n", encoding="utf-8")
    rename("_BagiConflictCard", "BagiConflictCard")

    # Imports in the page and in every form.
    schedule_text = SCHEDULE.read_text(encoding="utf-8")
    if "widgets/conflict_card.dart" not in schedule_text:
        schedule_text = schedule_text.replace(
            "import '../homework/homework_page.dart';",
            "import '../homework/homework_page.dart';\n"
            "import 'widgets/conflict_card.dart';",
            1,
        )
        SCHEDULE.write_text(schedule_text, encoding="utf-8")

    for path in sorted(FORMS.glob("*.dart")):
        text = path.read_text(encoding="utf-8")
        additions = []
        if "utils/focus.dart" not in text:
            additions.append("import '../../../utils/focus.dart';")
        if "widgets/conflict_card.dart" not in text:
            additions.append("import '../widgets/conflict_card.dart';")
        if additions:
            text = text.replace(
                "import '../../../widgets/child_avatar.dart';",
                "import '../../../widgets/child_avatar.dart';\n" + "\n".join(additions),
                1,
            )
            path.write_text(text, encoding="utf-8")

    print("conflict card extracted, imports added")


if __name__ == "__main__":
    main()
