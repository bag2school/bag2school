import 'package:flutter/widgets.dart';

// Shared controller disposal helper, extracted from lib/main.dart.

void disposeControllersAfterRoute(Iterable<TextEditingController> controllers) {
  Future<void>.delayed(const Duration(milliseconds: 450), () {
    for (final controller in controllers) {
      controller.dispose();
    }
  });
}
