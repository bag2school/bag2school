import 'package:flutter/material.dart';

/// A softer page change than the default zoom.
///
/// The incoming page fades in while drifting up by a couple of pixels and
/// scaling from 99% to full size; the page underneath dims slightly instead of
/// jumping. It reads calmer on a kids app and keeps the back gesture cheap
/// because nothing is rebuilt, only composited.
class SoftPageTransitionsBuilder extends PageTransitionsBuilder {
  const SoftPageTransitionsBuilder();

  static const Duration _duration = Duration(milliseconds: 340);

  @override
  Duration get transitionDuration => _duration;

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Respect the system "remove animations" accessibility setting.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return child;
    }

    final enter = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final cover = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: enter,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.018),
          end: Offset.zero,
        ).animate(enter),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.992, end: 1).animate(enter),
          child: FadeTransition(
            // The page underneath settles back a little instead of staying
            // flat, which makes the change feel layered rather than abrupt.
            opacity: Tween<double>(begin: 1, end: 0.94).animate(cover),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Applies [SoftPageTransitionsBuilder] on every platform.
const PageTransitionsTheme softPageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: SoftPageTransitionsBuilder(),
    TargetPlatform.iOS: SoftPageTransitionsBuilder(),
    TargetPlatform.macOS: SoftPageTransitionsBuilder(),
    TargetPlatform.windows: SoftPageTransitionsBuilder(),
    TargetPlatform.linux: SoftPageTransitionsBuilder(),
    TargetPlatform.fuchsia: SoftPageTransitionsBuilder(),
  },
);
