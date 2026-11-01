class BagiGreetingService {
  BagiGreetingService._();

  /// Returns the title Bagi should use when addressing the parent.
  ///
  /// Examples:
  /// Dad, Mom, Papa, Mama, Daddy, Mommy, etc.
  ///
  /// Mom remains the safe fallback for existing local/demo data.
  static String parentTitle({String? preferredTitle}) {
    final value = preferredTitle?.trim();

    if (value == null || value.isEmpty) {
      return 'Mom';
    }

    return value;
  }

  static String greeting({required String message, String? preferredTitle}) {
    final title = parentTitle(preferredTitle: preferredTitle);

    return message.replaceAll('{parent}', title);
  }

  static String morning({required String childName, String? preferredTitle}) {
    final title = parentTitle(preferredTitle: preferredTitle);

    return 'Good morning, $title! '
        "Let's get $childName ready for a great day. 😊";
  }

  static String afternoon({required String childName, String? preferredTitle}) {
    final title = parentTitle(preferredTitle: preferredTitle);

    return 'Good afternoon, $title! '
        "Let's see how $childName is doing today. 😊";
  }

  static String evening({required String childName, String? preferredTitle}) {
    final title = parentTitle(preferredTitle: preferredTitle);

    return 'Good evening, $title! '
        "Let's get $childName ready for tomorrow. 🌙";
  }

  static String current({
    required String childName,
    String? preferredTitle,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    final hour = time.hour;

    if (hour >= 5 && hour < 12) {
      return morning(childName: childName, preferredTitle: preferredTitle);
    }

    if (hour >= 12 && hour < 18) {
      return afternoon(childName: childName, preferredTitle: preferredTitle);
    }

    if (hour >= 18 && hour < 21) {
      return evening(childName: childName, preferredTitle: preferredTitle);
    }

    return night(childName: childName, preferredTitle: preferredTitle);
  }

  static String night({required String childName, String? preferredTitle}) {
    final title = parentTitle(preferredTitle: preferredTitle);

    return 'Good night, $title! '
        '$childName can rest once tomorrow is ready. 🌙';
  }
}
