#!/usr/bin/env python3
"""Move LocalAuthorization, _ChildDataBundle and Bag2SchoolStore into
lib/data/store.dart (step 3 of the main.dart split).

The reminder refresh is inverted into a callback so the store does not need to
import main.dart, which would create an import cycle.

    python tool/move_store.py
"""

from __future__ import annotations

import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAIN = ROOT / "lib" / "main.dart"
TARGET = ROOT / "lib" / "data" / "store.dart"

HEADER = (
    "import 'dart:async';\n"
    "import 'dart:convert';\n"
    "\n"
    "import 'package:flutter/foundation.dart';\n"
    "import 'package:shared_preferences/shared_preferences.dart';\n"
    "import 'package:supabase_flutter/supabase_flutter.dart';\n"
    "\n"
    "import '../models/activity_models.dart';\n"
    "import '../models/child_profile.dart';\n"
    "import '../models/family_models.dart';\n"
    "import '../services/bagi_family_service.dart';\n"
    "import '../services/family_access_defaults.dart';\n"
    "import 'serializers.dart';\n"
    "\n"
    "// Extracted from lib/main.dart (step 3 of the split in\n"
    "// docs/knowledge-graph.md): the family store, its per-child bundle cache\n"
    "// and the client side authorization helper.\n"
)


def find_class(lines: list[str], name: str) -> tuple[int, int]:
    pattern = re.compile(rf"^(?:abstract\s+)?class\s+{re.escape(name)}\b")
    for index, line in enumerate(lines):
        if pattern.match(line):
            for end in range(index, len(lines)):
                if lines[end] == "}":
                    return index, end
            raise SystemExit(f"{name}: closing brace not found")
    raise SystemExit(f"{name}: declaration not found")


def main() -> None:
    lines = MAIN.read_text(encoding="utf-8").split("\n")

    authz_start, _ = find_class(lines, "LocalAuthorization")
    store_start, store_end = find_class(lines, "Bag2SchoolStore")

    block = "\n".join(lines[authz_start : store_end + 1])

    # Invert the reminder dependency.
    block = block.replace(
        "unawaited(refreshDailyReminder());",
        "unawaited(onDataPersisted?.call() ?? Future<void>.value());",
    )

    marker = "  static bool isOfflineData = false;"
    if marker not in block:
        raise SystemExit("isOfflineData marker not found in the store block")

    block = block.replace(
        marker,
        "  /// Set from main() so the store can refresh the daily reminder\n"
        "  /// without importing main.dart (which would create a cycle).\n"
        "  static Future<void> Function()? onDataPersisted;\n\n" + marker,
        1,
    )

    TARGET.parent.mkdir(parents=True, exist_ok=True)
    TARGET.write_text(HEADER + "\n" + block + "\n", encoding="utf-8")

    # Drop the block from main.dart.
    del lines[authz_start : store_end + 1]
    text = "\n".join(lines)

    # Import the new file from main.dart.
    anchor = "import 'data/serializers.dart';"
    if anchor not in text:
        raise SystemExit("serializers import anchor not found")
    text = text.replace(anchor, anchor + "\nimport 'data/store.dart';", 1)

    MAIN.write_text(text, encoding="utf-8")

    # Wire the callback right after runApp.
    text = MAIN.read_text(encoding="utf-8")
    run_app = "  runApp(const Bag2SchoolApp());"
    if run_app not in text:
        raise SystemExit("runApp anchor not found")
    text = text.replace(
        run_app,
        run_app
        + "\n\n  // The store refreshes the reminder after every data change.\n"
        "  Bag2SchoolStore.onDataPersisted = refreshDailyReminder;",
        1,
    )
    MAIN.write_text(text, encoding="utf-8")

    # Files that use the store now import it directly.
    for relative in ("lib/auth_gate.dart", "lib/create_family_page.dart"):
        path = ROOT / relative
        content = path.read_text(encoding="utf-8")
        if "data/store.dart" in content:
            continue
        depth = "../" if relative.count("/") == 1 else ""
        content = content.replace(
            "import 'main.dart';",
            "import 'main.dart';\n" + f"import '{depth}data/store.dart';",
            1,
        )
        path.write_text(content, encoding="utf-8")

    print(f"store.dart: {block.count(chr(10)) + 1} lines")
    print(f"main.dart now {MAIN.read_text(encoding='utf-8').count(chr(10)) + 1} lines")


if __name__ == "__main__":
    main()
