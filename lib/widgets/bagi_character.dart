import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum BagiMood { idle, success, failed }

/// Three-pose BAGI sprite with a small looping motion.
///
/// The artwork is a temporary sprite-sheet source for the final Rive rig.
/// Keep the public mood API so Rive can replace the renderer without changing
/// call sites throughout the app.
class BagiCharacter extends StatefulWidget {
  const BagiCharacter({super.key, this.mood = BagiMood.idle});

  final BagiMood mood;

  @override
  State<BagiCharacter> createState() => _BagiCharacterState();
}

class _BagiCharacterState extends State<BagiCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  ui.Image? _sheet;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSheet());
  }

  Future<void> _loadSheet() async {
    try {
      final data = await rootBundle.load('assets/bagi/bagi_mood_sheet.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _sheet = frame.image);
    } catch (error) {
      debugPrint('[BAGI] Could not load character artwork: $error');
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _sheet?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheet = _sheet;
    if (sheet == null) {
      return const SizedBox.expand(
        child: Center(
          child: Icon(Icons.backpack_rounded, color: Color(0xFFFF7A21)),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _motion,
      builder: (context, child) {
        final progress = _motion.value;
        final lift = switch (widget.mood) {
          BagiMood.idle => progress * 3.0,
          BagiMood.success => progress * 7.0,
          BagiMood.failed => progress * 1.5,
        };
        final tilt = widget.mood == BagiMood.success
            ? (progress - .5) * .07
            : widget.mood == BagiMood.failed
            ? (progress - .5) * .018
            : 0.0;

        return Transform.translate(
          offset: Offset(0, -lift),
          child: Transform.rotate(
            angle: tilt,
            child: CustomPaint(
              painter: _BagiSpritePainter(sheet: sheet, mood: widget.mood),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _BagiSpritePainter extends CustomPainter {
  const _BagiSpritePainter({required this.sheet, required this.mood});

  final ui.Image sheet;
  final BagiMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = sheet.width / 3;
    final frame = switch (mood) {
      BagiMood.idle => 0,
      BagiMood.success => 1,
      BagiMood.failed => 2,
    };
    final source = Rect.fromLTWH(
      frameWidth * frame,
      0,
      frameWidth,
      sheet.height.toDouble(),
    );

    // Fit the frame inside the box instead of stretching it to the box, so a
    // non-square parent can never distort the artwork.
    final frameHeight = sheet.height.toDouble();
    final scale = math.min(size.width / frameWidth, size.height / frameHeight);
    final destination = Rect.fromLTWH(
      (size.width - frameWidth * scale) / 2,
      (size.height - frameHeight * scale) / 2,
      frameWidth * scale,
      frameHeight * scale,
    );

    canvas.drawImageRect(
      sheet,
      source,
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_BagiSpritePainter oldDelegate) =>
      oldDelegate.sheet != sheet || oldDelegate.mood != mood;
}
