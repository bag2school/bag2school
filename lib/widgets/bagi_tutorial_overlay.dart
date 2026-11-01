import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'bagi_character.dart';

const _bagiOrange = Color(0xFFFF7A21);
const _bagiInk = Color(0xFF302722);
const _bagiCream = Color(0xFFFFFCF8);
const _bagiMuted = Color(0xFF756B65);

Future<bool?> showBagiTutorialWelcome(
  BuildContext context, {
  bool includeChildSetup = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: _bagiCream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 92, height: 92, child: BagiCharacter()),
          const SizedBox(height: 10),
          const Text(
            'Hi! I’m BAGI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _bagiInk,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            includeChildSetup
                ? 'Let’s set up your child’s profile and take a friendly tour of Bag2School together.'
                : 'Let’s take a friendly tour of Bag2School and see how your family can stay organized together.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _bagiMuted, height: 1.45),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Skip tutorial'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _bagiOrange,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Let’s begin'),
        ),
      ],
    ),
  );
}

Future<bool?> showBagiTutorialChoiceDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String continueLabel,
  String skipLabel = 'Skip tutorial',
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: _bagiCream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 78, height: 78, child: BagiCharacter()),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _bagiInk,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _bagiMuted, height: 1.45),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(skipLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _bagiOrange,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(continueLabel),
        ),
      ],
    ),
  );
}

enum BagiTutorialAction { continueTutorial, targetTapped, back, skip }

class BagiTutorialTargetActions {
  static String? _activeId;
  static VoidCallback? _onTargetTap;

  static void register(String id, VoidCallback callback) {
    _activeId = id;
    _onTargetTap = callback;
  }

  static void activate(String id) {
    if (_activeId == id) _onTargetTap?.call();
  }

  static void clear(String id) {
    if (_activeId == id) {
      _activeId = null;
      _onTargetTap = null;
    }
  }
}

Future<BagiTutorialAction> showBagiTutorialSpotlight({
  required BuildContext context,
  GlobalKey? targetKey,
  GlobalKey? navigationBarKey,
  int? navigationItemIndex,
  int navigationItemCount = 5,
  required String stepLabel,
  required String title,
  required String message,
  bool showBack = false,
  String? targetActionId,
  TextEditingController? requireNonEmptyController,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final overlayContext = overlay.context;
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted || !overlayContext.mounted) {
    return BagiTutorialAction.skip;
  }

  final overlayObject = overlayContext.findRenderObject();
  if (overlayObject is! RenderBox) return BagiTutorialAction.skip;

  Rect? targetRect;
  if (navigationBarKey != null && navigationItemIndex != null) {
    final targetObject = navigationBarKey.currentContext?.findRenderObject();
    if (targetObject is RenderBox && targetObject.hasSize) {
      final origin = targetObject.localToGlobal(
        Offset.zero,
        ancestor: overlayObject,
      );
      final itemWidth = targetObject.size.width / navigationItemCount;
      final itemHeight = math.min(targetObject.size.height, 84.0);
      targetRect = Rect.fromLTWH(
        origin.dx + itemWidth * navigationItemIndex,
        origin.dy + targetObject.size.height - itemHeight,
        itemWidth,
        itemHeight,
      );
    }
  } else if (targetKey != null) {
    final targetObject = targetKey.currentContext?.findRenderObject();
    if (targetObject is RenderBox && targetObject.hasSize) {
      final origin = targetObject.localToGlobal(
        Offset.zero,
        ancestor: overlayObject,
      );
      targetRect = origin & targetObject.size;
    }
  }

  if (targetRect == null) return BagiTutorialAction.skip;

  targetRect = targetRect.intersect(Offset.zero & overlayObject.size);

  final result = Completer<BagiTutorialAction>();
  var finished = false;
  late final OverlayEntry entry;
  void finish(BagiTutorialAction action) {
    if (finished) return;
    finished = true;
    if (targetActionId != null) BagiTutorialTargetActions.clear(targetActionId);
    entry.remove();
    result.complete(action);
  }

  if (targetActionId != null) {
    BagiTutorialTargetActions.register(
      targetActionId,
      () => finish(BagiTutorialAction.targetTapped),
    );
  }

  entry = OverlayEntry(
    builder: (overlayContext) => _TickingRebuild(
      builder: (overlayContext) => _BagiTutorialSpotlight(
        targetRect: targetRect!,
        targetKey: targetKey,
        overlayObject: overlayObject,
        allowTargetInteraction:
            targetActionId != null || requireNonEmptyController != null,
        stepLabel: stepLabel,
        title: title,
        message: message,
        showBack: showBack,
        onBack: () => finish(BagiTutorialAction.back),
        onContinue: () => finish(BagiTutorialAction.continueTutorial),
        onSkip: () => finish(BagiTutorialAction.skip),
        requireNonEmptyController: requireNonEmptyController,
      ),
    ),
  );
  overlay.insert(entry);
  return result.future;
}

/// Rebuilds its child continuously while the tutorial step is on screen.
///
/// The spotlight has to follow the target when the keyboard opens, the phone
/// rotates, or a Bagi dialog slides in. Measuring once at show time left the
/// highlight behind in all three cases.
class _TickingRebuild extends StatefulWidget {
  const _TickingRebuild({required this.builder});

  final WidgetBuilder builder;

  @override
  State<_TickingRebuild> createState() => _TickingRebuildState();
}

class _TickingRebuildState extends State<_TickingRebuild> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // ~30 fps is enough for a moving highlight and much cheaper than 60.
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

class _BagiTutorialSpotlight extends StatelessWidget {
  final Rect targetRect;
  final GlobalKey? targetKey;
  final RenderBox overlayObject;
  final bool allowTargetInteraction;
  final String stepLabel;
  final String title;
  final String message;
  final bool showBack;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSkip;
  final TextEditingController? requireNonEmptyController;

  const _BagiTutorialSpotlight({
    required this.targetRect,
    required this.targetKey,
    required this.overlayObject,
    required this.allowTargetInteraction,
    required this.stepLabel,
    required this.title,
    required this.message,
    required this.showBack,
    required this.onBack,
    required this.onContinue,
    required this.onSkip,
    required this.requireNonEmptyController,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final targetObject = targetKey?.currentContext?.findRenderObject();
    final currentTargetRect =
        targetObject is RenderBox &&
            targetObject.hasSize &&
            targetObject.attached
        ? (targetObject.localToGlobal(Offset.zero, ancestor: overlayObject) &
              targetObject.size)
        : targetRect;
    final spotlight = currentTargetRect
        .inflate(7)
        .intersect(Offset.zero & size);
    final cardWidth = math.min(420.0, size.width - 28);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeTop = MediaQuery.paddingOf(context).top + 8;
    final safeBottom = math.max(12.0, size.height - keyboardInset - 12);
    final availableHeight = math.max(120.0, safeBottom - safeTop);
    final estimatedCardHeight = math.min(
      showBack ? 260.0 : 235.0,
      availableHeight,
    );
    final below = spotlight.bottom + 14;
    final cardTop = below + estimatedCardHeight < safeBottom
        ? below
        : math.max(safeTop, spotlight.top - estimatedCardHeight - 14);
    final cardLeft = (size.width - cardWidth) / 2;
    return Stack(
      children: [
        ..._dimmedRegions(size, spotlight),
        if (!allowTargetInteraction)
          Positioned.fromRect(
            rect: spotlight,
            child: const AbsorbPointer(child: SizedBox.expand()),
          ),
        Positioned.fromRect(
          rect: spotlight,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: _bagiOrange, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        Positioned(
          left: cardLeft,
          top: cardTop,
          width: cardWidth,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: availableHeight),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _bagiCream,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stepLabel,
                        style: const TextStyle(
                          color: _bagiOrange,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 58,
                            height: 58,
                            child: BagiCharacter(),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: _bagiInk,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: const TextStyle(
                                    color: _bagiMuted,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (showBack)
                            TextButton(
                              onPressed: onBack,
                              child: const Text('Back'),
                            ),
                          TextButton(
                            onPressed: onSkip,
                            child: const Text('Skip tutorial'),
                          ),
                          if (requireNonEmptyController == null)
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _bagiOrange,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: onContinue,
                              child: const Text('Continue'),
                            )
                          else
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: requireNonEmptyController!,
                              builder: (context, value, _) => FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: _bagiOrange,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: value.text.trim().isEmpty
                                    ? null
                                    : onContinue,
                                child: const Text('Continue'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

List<Widget> _dimmedRegions(Size size, Rect hole) {
  Widget region(Rect rect) => Positioned.fromRect(
    rect: rect,
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: ColoredBox(color: Colors.black.withValues(alpha: .58)),
      ),
    ),
  );

  return [
    if (hole.top > 0) region(Rect.fromLTWH(0, 0, size.width, hole.top)),
    if (hole.bottom < size.height)
      region(
        Rect.fromLTWH(0, hole.bottom, size.width, size.height - hole.bottom),
      ),
    if (hole.left > 0)
      region(Rect.fromLTWH(0, hole.top, hole.left, hole.height)),
    if (hole.right < size.width)
      region(
        Rect.fromLTWH(
          hole.right,
          hole.top,
          size.width - hole.right,
          hole.height,
        ),
      ),
  ];
}
