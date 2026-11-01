#!/usr/bin/env python3
"""Move top-level declarations between Dart files and rename them.

Used by the staged split of lib/main.dart. A declaration is matched at column
zero and ends at the first line that is exactly `}`. References across lib/ are
renamed at the same time, so nothing is left pointing at the old name.

    python tool/move_declarations.py
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"

# target file -> {old name: new name}
MOVES: dict[str, dict[str, str]] = {
    "lib/data/serializers.dart": {
        "_preparationToJson": "preparationToJson",
        "_preparationFromJson": "preparationFromJson",
        "_homeworkToJson": "homeworkToJson",
        "_homeworkFromJson": "homeworkFromJson",
        "_activityToJson": "activityToJson",
        "_activityFromJson": "activityFromJson",
        "_sameCalendarDay": "sameCalendarDay",
        "_twoDigits": "twoDigits",
    },
}

HEADERS = {
    "lib/data/serializers.dart": (
        "import 'package:flutter/foundation.dart';\n"
        "\n"
        "import '../models/activity_models.dart';\n"
        "\n"
        "// Extracted from lib/main.dart: JSON (de)serialisation for the models.\n"
        "// Part of the staged split described in docs/knowledge-graph.md.\n"
    ),
}


def find_block(lines: list[str], name: str) -> tuple[int, int] | None:
    """1-based inclusive line range of a top-level declaration."""
    pattern = re.compile(rf"^[A-Za-z_][\w<>,\?\[\]\s]*\s{re.escape(name)}\s*\(")

    for index, line in enumerate(lines):
        if not pattern.match(line):
            continue

        # Expression bodied: ends with `;` (maybe across lines).
        if "=>" in line or line.rstrip().endswith(";"):
            for end in range(index, len(lines)):
                if lines[end].rstrip().endswith(";"):
                    return index + 1, end + 1
            return None

        # Block bodied: ends with `}` at column zero.
        if line.rstrip().endswith(";"):
            return index + 1, index + 1
        for end in range(index + 1, len(lines)):
            if lines[end] == "}":
                return index + 1, end + 1
        return None

    return None


def rename_everywhere(old: str, new: str) -> list[str]:
    changed = []
    pattern = re.compile(rf"\b{re.escape(old)}\b")

    for path in (ROOT / "lib").rglob("*.dart"):
        text = path.read_text(encoding="utf-8")
        updated = pattern.sub(new, text)
        if updated != text:
            path.write_text(updated, encoding="utf-8")
            changed.append(path.relative_to(ROOT).as_posix())

    return changed


def main() -> None:
    text = MAIN.read_text(encoding="utf-8")
    lines = text.split("\n")

    for target, mapping in MOVES.items():
        blocks: list[str] = []
        ranges: list[tuple[int, int]] = []

        for old in mapping:
            span = find_block(lines, old)
            if span is None:
                raise SystemExit(f"{old} not found as a top-level declaration")
            start, end = span
            ranges.append((start, end))
            blocks.append("\n".join(lines[start - 1 : end]))

        # Remove from the bottom so earlier indexes stay valid.
        for start, end in sorted(ranges, reverse=True):
            del lines[start - 1 : end]
            # Drop the blank line the block left behind.
            if start - 1 < len(lines) and lines[start - 1] == "":
                del lines[start - 1]

        MAIN.write_text("\n".join(lines), encoding="utf-8")

        body = "\n\n".join(blocks) + "\n"
        for old, new in mapping.items():
            body = re.sub(rf"\b{re.escape(old)}\b", new, body)

        path = ROOT / target
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(HEADERS.get(target, "") + "\n" + body, encoding="utf-8")

        for old, new in mapping.items():
            touched = rename_everywhere(old, new)
            print(f"renamed {old} -> {new} in {len(touched)} file(s)")

        print(f"wrote {target}: {len(blocks)} declarations")

    # Import the new file from main.dart.
    main_text = MAIN.read_text(encoding="utf-8")
    marker = "import 'models/activity_models.dart';"
    if marker in main_text:
        main_text = main_text.replace(
            marker, marker + "\nimport 'data/serializers.dart';", 1
        )
        MAIN.write_text(main_text, encoding="utf-8")

    print(f"main.dart now {main_text.count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
