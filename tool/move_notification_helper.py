#!/usr/bin/env python3
"""Move _showSuccessNotification out of main.dart into a widget helper.

The store needs it, and the store must not import main.dart, so it becomes a
small shared widget helper with a public name.

    python tool/move_notification_helper.py
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"
TARGET = ROOT / "lib" / "widgets" / "app_notification.dart"

OLD = "_showSuccessNotification"
NEW = "showAppNotification"

HEADER = (
    "import 'package:flutter/material.dart';\n"
    "\n"
    "// Extracted from lib/main.dart: the shared success/notice dialog.\n"
)


def main() -> None:
    lines = MAIN.read_text(encoding="utf-8").split("\n")

    start = None
    for index, line in enumerate(lines):
        if line.startswith(f"void {OLD}("):
            start = index
            break

    if start is None:
        raise SystemExit(f"{OLD} not found")

    end = None
    for index in range(start + 1, len(lines)):
        if lines[index] == "}":
            end = index
            break

    if end is None:
        raise SystemExit("closing brace not found")

    body = "\n".join(lines[start : end + 1])
    body = re.sub(rf"\b{OLD}\b", NEW, body)

    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(HEADER + "\n" + body + "\n", encoding="utf-8")

    del lines[start : end + 1]
    if start < len(lines) and lines[start] == "":
        del lines[start]

    text = "\n".join(lines)
    text = re.sub(rf"\b{OLD}\b", NEW, text)

    anchor = "import 'data/store.dart';"
    if anchor not in text:
        raise SystemExit("store import anchor not found")
    text = text.replace(anchor, anchor + "\nimport 'widgets/app_notification.dart';", 1)

    MAIN.write_text(text, encoding="utf-8")

    store = ROOT / "lib" / "data" / "store.dart"
    store_text = store.read_text(encoding="utf-8")
    store_text = re.sub(rf"\b{OLD}\b", NEW, store_text)
    if "widgets/app_notification.dart" not in store_text:
        store_text = store_text.replace(
            "import '../services/family_access_defaults.dart';",
            "import '../services/family_access_defaults.dart';\n"
            "import '../widgets/app_notification.dart';",
            1,
        )
    if "services/bagi_local_auth_service.dart" not in store_text:
        store_text = store_text.replace(
            "import '../services/bagi_family_service.dart';",
            "import '../services/bagi_family_service.dart';\n"
            "import '../services/bagi_local_auth_service.dart';",
            1,
        )
    store.write_text(store_text, encoding="utf-8")

    print(f"wrote {TARGET.relative_to(ROOT)}")
    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
