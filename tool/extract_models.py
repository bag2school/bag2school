#!/usr/bin/env python3
"""Move top level declarations out of lib/main.dart into model files.

One-off helper for the "split main.dart" plan. It matches declarations with
brace counting, copies them into the target file, and removes them from
main.dart. Nothing else is touched; run `dart format` and `dart analyze`
afterwards to catch anything that still needs a hand.

    python tool/extract_models.py
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"

DECL = re.compile(r"^(?:abstract\s+)?(class|enum|mixin)\s+(\w+)", re.MULTILINE)

TARGETS = {
    "lib/models/family_models.dart": [
        "LocalPermissionFeature",
        "AccessRequestStatus",
        "FamilyMemberRole",
        "ChildAccessMode",
        "LocalAccount",
        "FamilyMember",
        "FamilyAccessGrant",
        "ChildAccessSettings",
        "LocalAccessRequest",
        "LocalFamilyNotification",
        "LocalFamilyActivity",
    ],
    "lib/models/activity_models.dart": [
        "ActivityType",
        "RecurrenceType",
        "ActivityIndicatorType",
        "IndicatorType",
        "TimeOfDayData",
        "ActivityRecurrence",
        "HomeworkDetails",
        "BagActivity",
        "PreparationItem",
        "HomeworkItem",
        "ActivityConflict",
        "ActivityConflictDetector",
        "CalendarIndicator",
        "ChildDayData",
    ],
}


def declaration_spans(text: str) -> dict[str, tuple[int, int]]:
    """Name -> (start, end) character offsets of the whole declaration."""
    spans: dict[str, tuple[int, int]] = {}

    for match in DECL.finditer(text):
        brace = text.find("{", match.end())
        if brace == -1:
            continue

        depth = 0
        for index in range(brace, len(text)):
            char = text[index]
            if char == "{":
                depth += 1
            elif char == "}":
                depth -= 1
                if depth == 0:
                    end = index + 1
                    # Swallow a trailing newline so we do not leave blank gaps.
                    while end < len(text) and text[end] in "\r\n":
                        end += 1
                    spans[match.group(2)] = (match.start(), end)
                    break

    return spans


def main() -> None:
    text = MAIN.read_text(encoding="utf-8")
    spans = declaration_spans(text)

    wanted: dict[str, str] = {}
    for path, names in TARGETS.items():
        for name in names:
            wanted[name] = path

    missing = [name for name in wanted if name not in spans]
    if missing:
        raise SystemExit(f"Not found in main.dart: {', '.join(missing)}")

    collected: dict[str, list[str]] = {path: [] for path in TARGETS}
    for name, path in wanted.items():
        start, end = spans[name]
        collected[path].append(text[start:end].rstrip() + "\n")

    # Remove the declarations, back to front so offsets stay valid.
    cuts = sorted((spans[name] for name in wanted), reverse=True)
    for start, end in cuts:
        text = text[:start] + text[end:]

    for path, blocks in collected.items():
        target = ROOT / path
        target.parent.mkdir(parents=True, exist_ok=True)
        header = (
            f"// Extracted from lib/main.dart ({len(blocks)} declarations).\n"
            "// Part of the staged split described in docs/knowledge-graph.md.\n\n"
        )
        target.write_text(header + "\n".join(blocks), encoding="utf-8")
        print(f"wrote {path}: {len(blocks)} declarations")

    imports = "\n".join(f"import '{Path(path).relative_to('lib').as_posix()}';"
                        for path in TARGETS)
    marker = "import 'theme/bag2school_tokens.dart';"
    if marker in text:
        text = text.replace(marker, marker + "\n" + imports, 1)
    else:
        raise SystemExit("Import marker not found; add the model imports by hand.")

    MAIN.write_text(text, encoding="utf-8")
    print(f"main.dart now {text.count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
