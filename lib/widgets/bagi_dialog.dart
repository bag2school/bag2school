import 'package:flutter/material.dart';

import 'bagi_character.dart';

/// A warm, rounded dialog in Bagi's voice.
///
/// Every confirmation, error and success message should go through this so the
/// app feels like one friendly character talking, instead of system alerts.
Future<T?> showBagiDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  String? primaryLabel,
  VoidCallback? onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  bool destructive = false,
  bool barrierDismissible = true,
  BagiMood mood = BagiMood.success,
}) {
  final primaryColor = destructive
      ? const Color(0xFFC95757)
      : const Color(0xFFFF7A21);

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF8),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF3E4D6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 28,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEEDA),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: BagiCharacter(mood: mood),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18.5,
                              height: 1.25,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF302722),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: Color(0xFF6B5F58),
                      ),
                    ),
                  ],
                  if (content != null) ...[
                    const SizedBox(height: 14),
                    content,
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (secondaryLabel != null)
                        TextButton(
                          onPressed:
                              onSecondary ?? () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF756B65),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(secondaryLabel),
                        ),
                      if (primaryLabel != null) ...[
                        const SizedBox(width: 6),
                        FilledButton(
                          onPressed:
                              onPrimary ?? () => Navigator.pop(dialogContext),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          child: Text(primaryLabel),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
