import 'package:flutter/material.dart';

class ChildAvatar extends StatelessWidget {
  final String? gender;
  final double size;

  const ChildAvatar({
    super.key,
    this.gender,
    this.size = 68,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedGender = gender?.toLowerCase().trim();

    final bool isGirl =
        normalizedGender == 'girl' ||
        normalizedGender == 'female' ||
        normalizedGender == 'perempuan';

    final String emoji = isGirl ? '👧🏻' : '👦🏻';

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE7D2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.58),
      ),
    );
  }
}