#!/usr/bin/env python3
"""Step 5b-4: move PreparationPage out of main.dart.

Also extracts _settleDialogFocus into lib/utils/focus.dart because the page
needs it and it is private to main.dart.

PreparationPage still references SchedulePage and HomeworkPage, which live in
main.dart for now, so it imports main.dart temporarily. That import disappears
once those two screens move.

    python tool/move_preparation.py
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"

FOCUS_TARGET = ROOT / "lib" / "utils" / "focus.dart"
FOCUS_HEADER = (
    "import 'package:flutter/widgets.dart';\n"
    "\n"
    "// Unfocus helper used before closing a dialog or sheet.\n"
)

PREP_TARGET = ROOT / "lib" / "features" / "preparation" / "preparation_page.dart"
PREP_HEADER = (
    "import 'dart:async';\n"
    "import 'dart:math';\n"
    "\n"
    "import 'package:flutter/material.dart';\n"
    "\n"
    "import '../../data/store.dart';\n"
    "import '../../main.dart';\n"
    "import '../../models/activity_models.dart';\n"
    "import '../../models/family_models.dart';\n"
    "import '../../services/bagi_message.dart';\n"
    "import '../../services/preparation_defaults.dart';\n"
    "import '../../theme/bag2school_tokens.dart';\n"
    "import '../../utils/controllers.dart';\n"
    "import '../../utils/focus.dart';\n"
    "import '../../widgets/app_notification.dart';\n"
    "import '../../widgets/bagi_character.dart';\n"
    "import '../../widgets/bubble_tail_painters.dart';\n"
    "import '../settings/settings_page.dart';\n"
    "\n"
    "// Preparation screen: today, tomorrow and upcoming readiness.\n"
    "// Extracted from lib/main.dart (step 5b).\n"
)

PREP_CLASSES = [("PreparationPage", 60), ("_PreparationPageState", 2600)]


def find_decl(lines: list[str], name: str, kind: str) -> tuple[int, int]:
    if kind == "class":
        pattern = re.compile(rf"^(?:abstract\s+)?class\s+{re.escape(name)}\b")
    else:
        pattern = re.compile(rf"^(?:[\w<>,\?\[\]\(\)\s]*\s)?{re.escape(name)}\s*\(.*\{{\s*$")

    matches = [i for i, line in enumerate(lines) if pattern.match(line)]
    if len(matches) != 1:
        raise SystemExit(f"{name}: expected one declaration, found {len(matches)}")

    index = matches[0]
    for end in range(index, len(lines)):
        if lines[end] == "}":
            return index, end
    raise SystemExit(f"{name}: closing brace not found")


def extract(items, target: pathlib.Path, header: str) -> None:
    lines = MAIN.read_text(encoding="utf-8").split("\n")
    spans = []

    for name, kind, limit in items:
        start, end = find_decl(lines, name, kind)
        size = end - start + 1
        if size > limit:
            raise SystemExit(f"{name}: {size} lines exceeds the {limit} guard")
        spans.append((start, end))
        print(f"  {name:26} {start + 1:6}-{end + 1:6} ({size} lines)")

    blocks = ["\n".join(lines[start : end + 1]) for start, end in spans]

    for start, end in sorted(spans, reverse=True):
        del lines[start : end + 1]
        if start < len(lines) and lines[start] == "":
            del lines[start]

    MAIN.write_text("\n".join(lines), encoding="utf-8")
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(header + "\n" + "\n\n".join(blocks) + "\n", encoding="utf-8")
    print(f"wrote {target.relative_to(ROOT)}\n")


def rename(old: str, new: str) -> None:
    for path in (ROOT / "lib").rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        updated = re.sub(rf"\b{re.escape(old)}\b", new, text)
        if updated != text:
            path.write_text(updated, encoding="utf-8")


def main() -> None:
    print("extracting focus helper:")
    lines = MAIN.read_text(encoding="utf-8")
    lines = lines.replace("_settleDialogFocus", "settleDialogFocus")
    MAIN.write_text(lines, encoding="utf-8")
    extract([("settleDialogFocus", "func", 20)], FOCUS_TARGET, FOCUS_HEADER)

    print("extracting preparation:")
    extract(
        [(name, "class", limit) for name, limit in PREP_CLASSES],
        PREP_TARGET,
        PREP_HEADER,
    )

    text = MAIN.read_text(encoding="utf-8")
    anchor = "import 'utils/controllers.dart';"
    if anchor in text and "utils/focus.dart" not in text:
        text = text.replace(anchor, anchor + "\nimport 'utils/focus.dart';", 1)
    anchor2 = "import 'features/settings/settings_page.dart';"
    if anchor2 in text and "features/preparation/preparation_page.dart" not in text:
        text = text.replace(
            anchor2,
            anchor2 + "\nimport 'features/preparation/preparation_page.dart';",
            1,
        )
    MAIN.write_text(text, encoding="utf-8")

    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
