import 'package:bag_2_school/theme/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _builder = SoftPageTransitionsBuilder();

Widget app() {
  return MaterialApp(
    theme: ThemeData(pageTransitionsTheme: softPageTransitionsTheme),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Second page')),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

/// Builder output for a context whose MediaQuery carries [disableAnimations].
Widget transitionsFor(BuildContext context) {
  final route = MaterialPageRoute<void>(
    builder: (_) => const SizedBox.shrink(),
  );
  final controller = AnimationController(
    vsync: const TestVSync(),
    duration: const Duration(milliseconds: 300),
  )..value = 0.4;

  return _builder.buildTransitions<void>(
    route,
    context,
    controller,
    const AlwaysStoppedAnimation<double>(0),
    const Text('child'),
  );
}

Future<BuildContext> captureContext(
  WidgetTester tester, {
  required bool disableAnimations,
}) async {
  late BuildContext captured;

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(disableAnimations: disableAnimations),
        child: Builder(
          builder: (innerContext) {
            captured = innerContext;
            return child ?? const SizedBox.shrink();
          },
        ),
      ),
      home: const SizedBox.shrink(),
    ),
  );

  return captured;
}

void main() {
  testWidgets('the theme uses the soft builder on every platform', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    final context = tester.element(find.text('Open'));
    final theme = Theme.of(context);

    for (final platform in TargetPlatform.values) {
      expect(
        theme.pageTransitionsTheme.builders[platform],
        isA<SoftPageTransitionsBuilder>(),
        reason: 'missing builder for $platform',
      );
    }
  });

  testWidgets('the builder fades the incoming page in', (tester) async {
    final context = await captureContext(tester, disableAnimations: false);

    expect(transitionsFor(context), isA<FadeTransition>());
  });

  testWidgets('the builder steps aside when animations are disabled', (
    tester,
  ) async {
    final context = await captureContext(tester, disableAnimations: true);

    expect(transitionsFor(context), isA<Text>());
  });

  testWidgets('pushing a page shows the new screen', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Second page'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Second page'), findsOneWidget);
  });
}
