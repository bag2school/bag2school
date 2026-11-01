#!/usr/bin/env python3
"""Step 5b-2: move FamilySettingsPage out of main.dart."""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"
TARGET = ROOT / "lib" / "features" / "family" / "family_settings_page.dart"

CLASSES = ["FamilySettingsPage", "_FamilySettingsPageState"]

HEADER = (
    "import 'package:flutter/material.dart';\n"
    "import 'package:supabase_flutter/supabase_flutter.dart';\n"
    "\n"
    "import '../../data/store.dart';\n"
    "import '../../models/activity_models.dart';\n"
    "import '../../models/child_profile.dart';\n"
    "import '../../models/family_models.dart';\n"
    "import '../../services/bagi_family_service.dart';\n"
    "import '../../services/bagi_message.dart';\n"
    "import '../../services/family_access_defaults.dart';\n"
    "import '../../utils/controllers.dart';\n"
    "import '../../widgets/app_notification.dart';\n"
    "import '../../widgets/bagi_character.dart';\n"
    "import '../../widgets/child_avatar.dart';\n"
    "\n"
    "// Family members, roles, invitations and child access.\n"
    "// Extracted from lib/main.dart (step 5b).\n"
)


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
    lines = MAIN.read_text(encoding="utf-8").split("\n")
    spans = [find_class(lines, name) for name in CLASSES]
    blocks = ["\n".join(lines[start : end + 1]) for start, end in spans]

    for start, end in sorted(spans, reverse=True):
        del lines[start : end + 1]
        if start < len(lines) and lines[start] == "":
            del lines[start]

    MAIN.write_text("\n".join(lines), encoding="utf-8")

    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(HEADER + "\n" + "\n\n".join(blocks) + "\n", encoding="utf-8")

    text = MAIN.read_text(encoding="utf-8")
    anchor = "import 'features/family/family_activity_page.dart';"
    if anchor in text:
        text = text.replace(
            anchor,
            anchor + "\nimport 'features/family/family_settings_page.dart';",
            1,
        )
        MAIN.write_text(text, encoding="utf-8")

    print(f"wrote {TARGET.relative_to(ROOT)}")
    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
