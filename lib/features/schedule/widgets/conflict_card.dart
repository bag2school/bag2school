import 'package:flutter/material.dart';

import '../../../models/activity_models.dart';
import '../../../services/bagi_message.dart';
import '../../../widgets/bagi_character.dart';

// Conflict banner shown by the activity forms.

class BagiConflictCard extends StatelessWidget {
  final ActivityConflict conflict;
  final VoidCallback onKeepBoth;
  final VoidCallback onAdjust;

  const BagiConflictCard({
    required this.conflict,
    required this.onKeepBoth,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFD7BF), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 64, height: 64, child: const BagiCharacter()),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(19),
                      bottomLeft: Radius.circular(19),
                      bottomRight: Radius.circular(19),
                    ),
                    border: Border.all(color: const Color(0xFFE0D9FF)),
                  ),
                  child: Text(
                    personalizeBagiMessage(
                      "Hey {parent}! I think these two are meeting at the same time. "
                      "No worries 😊 Want to keep both, or shall we find a "
                      "better spot for the new one?",
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4D445B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFAF6),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  color: Color(0xFFFF7A21),
                  size: 21,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    conflict.existingActivity.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF29231F),
                    ),
                  ),
                ),
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE0A52D),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onAdjust,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7A21),
                    side: const BorderSide(color: Color(0xFFFFC8A5)),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Let me adjust',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onKeepBoth,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7A21),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Keep both',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
