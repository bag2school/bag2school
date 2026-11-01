#!/usr/bin/env python3
"""Move _disposeControllersAfterRoute into lib/utils/controllers.dart.

The extracted pages need it, and a private top level function in main.dart
cannot be imported.

    python tool/move_controller_helper.py
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"
TARGET = ROOT / "lib" / "utils" / "controllers.dart"

OLD = "_disposeControllersAfterRoute"
NEW = "disposeControllersAfterRoute"

HEADER = (
    "import 'package:flutter/widgets.dart';\n"
    "\n"
    "// Shared controller disposal helper, extracted from lib/main.dart.\n"
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

    anchor = "import 'widgets/month_calendar.dart';"
    if anchor in text and "utils/controllers.dart" not in text:
        text = text.replace(anchor, anchor + "\nimport 'utils/controllers.dart';", 1)

    MAIN.write_text(text, encoding="utf-8")

    for path in (ROOT / "lib").rglob("*.dart"):
        content = path.read_text(encoding="utf-8")
        if f"{NEW}(" not in content or path == TARGET:
            continue
        if "utils/controllers.dart" in content or "controllers.dart" in content:
            continue
        depth = len(path.relative_to(ROOT / "lib").parts) - 1
        prefix = "../" * depth if depth else ""
        content = content.replace(
            "import '../../widgets/app_notification.dart';",
            "import '../../widgets/app_notification.dart';\n"
            f"import '{prefix}utils/controllers.dart';",
            1,
        )
        path.write_text(content, encoding="utf-8")

    print(f"wrote {TARGET.relative_to(ROOT)}")
    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
