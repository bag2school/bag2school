import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Default "what should we get ready?" suggestions, per activity type.
///
/// The list starts from the built-in suggestions and then follows whatever the
/// parent keeps or adds, so the same items come back the next time a schedule
/// item of that type is saved.
class PreparationDefaults {
  PreparationDefaults._();

  static const String _storageKey = 'bag2school_preparation_defaults_v1';

  static const Map<String, List<String>> _builtIn = <String, List<String>>{
    'school': ['School uniform', 'Books', 'Water bottle', 'Lunch box'],
    'lesson': ['Books / workbook', 'Stationery', 'Water bottle'],
    'extracurricular': [
      'Equipment / gear',
      'Water bottle',
      'Towel',
      'Extra clothes',
    ],
    'exam': ['Study materials', 'Stationery', 'Calculator / exam tools'],
    'event': ['Event items', 'Uniform / outfit', 'Water bottle'],
    'default': ['Bag', 'Water bottle', 'Something important'],
  };

  static List<String> builtInFor(String type) =>
      List<String>.from(_builtIn[type] ?? _builtIn['default']!);

  static Future<List<String>> load(String type) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);
      if (raw == null || raw.isEmpty) return builtInFor(type);

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return builtInFor(type);

      final stored = decoded[type];
      if (stored is! List) return builtInFor(type);

      return stored.map((item) => item.toString()).toList();
    } catch (_) {
      return builtInFor(type);
    }
  }

  static Future<List<String>> add(String type, String item) async {
    final trimmed = item.trim();
    final current = await load(type);

    if (trimmed.isEmpty || current.contains(trimmed)) {
      return current;
    }

    final updated = [...current, trimmed];
    await _save(type, updated);

    return updated;
  }

  static Future<List<String>> remove(String type, String item) async {
    final current = await load(type);
    final updated = current.where((entry) => entry != item).toList();

    await _save(type, updated);

    return updated;
  }

  static Future<void> _save(String type, List<String> items) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final raw = preferences.getString(_storageKey);

      final map = <String, dynamic>{};
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          map.addAll(Map<String, dynamic>.from(decoded));
        }
      }

      map[type] = items;
      await preferences.setString(_storageKey, jsonEncode(map));
    } catch (_) {
      // Defaults are a convenience; failing to store them must not block saving.
    }
  }
}
