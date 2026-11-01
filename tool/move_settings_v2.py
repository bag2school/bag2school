#!/usr/bin/env python3
"""Step 5b-3 (redone): move SettingsPage and the daily reminder tile.

Fixes the earlier bug: the function matcher also matched indented *calls*
(`await refreshDailyReminder();`), which cut the wrong block. Declarations must
now start at column zero, and every span is validated before writing.

    python tool/move_settings_v2.py
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"

CONTENT_TARGET = ROOT / "lib" / "services" / "reminder_content.dart"
CONTENT_HEADER = (
    "import 'dart:math';\n"
    "\n"
    "import 'package:flutter/foundation.dart';\n"
    "\n"
    "import '../data/serializers.dart';\n"
    "import '../data/store.dart';\n"
    "import 'bagi_message.dart';\n"
    "import 'reminder_service.dart';\n"
    "\n"
    "// Builds and schedules the single daily reminder. Extracted from\n"
    "// lib/main.dart so screens do not depend on the entrypoint file.\n"
)

SETTINGS_TARGET = ROOT / "lib" / "features" / "settings" / "settings_page.dart"
SETTINGS_HEADER = (
    "import 'dart:async';\n"
    "\n"
    "import 'package:flutter/material.dart';\n"
    "import 'package:supabase_flutter/supabase_flutter.dart';\n"
    "\n"
    "import '../../bagi_identity_settings_page.dart';\n"
    "import '../../data/store.dart';\n"
    "import '../../models/child_profile.dart';\n"
    "import '../../models/family_models.dart';\n"
    "import '../../services/bagi_family_service.dart';\n"
    "import '../../services/bagi_message.dart';\n"
    "import '../../services/family_access_defaults.dart';\n"
    "import '../../services/owner_tutorial_state.dart';\n"
    "import '../../services/reminder_content.dart';\n"
    "import '../../services/reminder_service.dart';\n"
    "import '../../theme/bag2school_tokens.dart';\n"
    "import '../../utils/controllers.dart';\n"
    "import '../../widgets/app_notification.dart';\n"
    "import '../../widgets/bagi_character.dart';\n"
    "import '../../widgets/bagi_tutorial_overlay.dart';\n"
    "import '../../widgets/child_avatar.dart';\n"
    "import '../family/family_activity_page.dart';\n"
    "import '../family/family_settings_page.dart';\n"
    "import 'local_account_page.dart';\n"
    "\n"
    "// Settings: account, child profiles, Bagi identity, language and the daily\n"
    "// reminder switch. Extracted from lib/main.dart (step 5b).\n"
)

CONTENT_FUNCS = [
    ("buildDailyReminderContent", 200),
    ("refreshDailyReminder", 60),
]

SETTINGS_CLASSES = [
    ("SettingsPage", 40),
    ("_SettingsPageState", 2000),
    ("_DailyReminderTile", 40),
    ("_DailyReminderTileState", 300),
]


def find_decl(lines: list[str], name: str, kind: str) -> tuple[int, int]:
    if kind == "class":
        pattern = re.compile(rf"^(?:abstract\s+)?class\s+{re.escape(name)}\b")
    else:
        # Column zero only, and the declaration line must open a block.
        pattern = re.compile(rf"^(?:[\w<>,\?\[\]\(\)\s]*\s)?{re.escape(name)}\s*\(.*\{{\s*$")

    matches = [i for i, line in enumerate(lines) if pattern.match(line)]
    if len(matches) != 1:
        raise SystemExit(f"{name}: expected one declaration, found {len(matches)}")

    index = matches[0]
    for end in range(index, len(lines)):
        if lines[end] == "}":
            return index, end
    raise SystemExit(f"{name}: closing brace not found")


def extract(items: list[tuple[str, str, int]], target: pathlib.Path, header: str) -> None:
    lines = MAIN.read_text(encoding="utf-8").split("\n")

    spans = []
    for name, kind, limit in items:
        start, end = find_decl(lines, name, kind)
        size = end - start + 1
        if size > limit:
            raise SystemExit(f"{name}: span {size} lines exceeds the {limit} guard")
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


def main() -> None:
    print("extracting reminder content:")
    extract(
        [(name, "func", limit) for name, limit in CONTENT_FUNCS],
        CONTENT_TARGET,
        CONTENT_HEADER,
    )

    print("extracting settings:")
    extract(
        [(name, "class", limit) for name, limit in SETTINGS_CLASSES],
        SETTINGS_TARGET,
        SETTINGS_HEADER,
    )

    text = MAIN.read_text(encoding="utf-8")
    anchor = "import 'services/reminder_service.dart';"
    if anchor in text and "services/reminder_content.dart" not in text:
        text = text.replace(
            anchor, "import 'services/reminder_content.dart';\n" + anchor, 1
        )
    anchor2 = "import 'features/settings/local_account_page.dart';"
    if anchor2 in text and "features/settings/settings_page.dart" not in text:
        text = text.replace(
            anchor2, anchor2 + "\nimport 'features/settings/settings_page.dart';", 1
        )
    MAIN.write_text(text, encoding="utf-8")

    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
