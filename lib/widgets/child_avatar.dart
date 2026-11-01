import 'package:flutter/material.dart';

class ChildAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? gender;
  final double size;

  const ChildAvatar({super.key, this.avatarUrl, this.gender, this.size = 68});

  @override
  Widget build(BuildContext context) {
    final normalizedGender = gender?.trim().toLowerCase();

    final isGirl =
        normalizedGender == 'girl' ||
        normalizedGender == 'female' ||
        normalizedGender == 'perempuan';

    final icon = isGirl ? Icons.face_3_rounded : Icons.face_rounded;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFFFE7D2),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
            ? Image.network(
                avatarUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  icon,
                  size: size * 0.62,
                  color: const Color(0xFFFF8A3D),
                ),
              )
            : Icon(icon, size: size * 0.62, color: const Color(0xFFFF8A3D)),
      ),
    );
  }
}
