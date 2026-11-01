import 'package:flutter/material.dart';

// Small reusable row widgets and Bagi's tip card. Extracted from
// lib/main.dart.

class ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  const ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        splashColor: color.withValues(alpha: 0.18),
        highlightColor: color.withValues(alpha: 0.10),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}

class ScheduleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final Color backgroundColor;
  final Color iconColor;

  const ScheduleItem({
    super.key,
    required this.icon,
    required this.title,
    required this.time,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 25),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          Text(
            time,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),

          const SizedBox(width: 5),

          const Icon(Icons.chevron_right, color: Colors.black45),
        ],
      ),
    );
  }
}

class TodoItem extends StatelessWidget {
  final String title;
  final bool checked;
  final ValueChanged<bool> onChanged;

  const TodoItem({
    super.key,
    required this.title,
    required this.checked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: checked ? const Color(0xFFEAF7EF) : Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: checked ? const Color(0xFFB8DFC7) : const Color(0xFFF1E5DD),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: (value) {
              onChanged(value ?? false);
            },
            activeColor: const Color(0xFF59A66F),
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: checked
                        ? const Color(0xFF3F7652)
                        : const Color(0xFF302722),
                  ),
                ),

                if (checked)
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      'Ready! ✓',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4E9565),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BagiTip extends StatelessWidget {
  const BagiTip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E8),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: const Color(0xFFFFD8B8)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎒', style: TextStyle(fontSize: 30)),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bagi's Tip",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B1A),
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  "Put your child's sports shoes "
                  "near the door tonight so you "
                  "won't forget them tomorrow morning. 👟",
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF625851),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
