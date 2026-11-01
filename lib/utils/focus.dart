import 'package:flutter/widgets.dart';

// Unfocus helper used before closing a dialog or sheet.

Future<void> settleDialogFocus() async {
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(const Duration(milliseconds: 120));
}
