import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/services/goop_talk_engine.dart';

/// GoopText — plain-Text passthrough that applies the global font
/// weight bias + letter-spacing prefs.
void main() {
  setUp(() {
    VisualPrefs.notifier.value = const VisualPrefs();
  });
  tearDown(() {
    VisualPrefs.notifier.value = const VisualPrefs();
  });

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  Text rendered(WidgetTester tester) =>
      tester.widget<Text>(find.byType(Text).first);

  testWidgets('renders the text verbatim', (tester) async {
    await tester.pumpWidget(wrap(const GoopText('Hello Gungeon')));
    expect(find.text('Hello Gungeon'), findsOneWidget);
  });

  testWidgets('fontWeightBias shifts the weight by whole steps', (
    tester,
  ) async {
    VisualPrefs.notifier.value = const VisualPrefs(fontWeightBias: 1);
    await tester.pumpWidget(
      wrap(
        const GoopText('Bold', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
    // w600 is index 5; +1 step → index 6 → w700.
    expect(rendered(tester).style?.fontWeight, FontWeight.w700);
  });

  testWidgets('bias does not touch styles without a weight', (tester) async {
    VisualPrefs.notifier.value = const VisualPrefs(fontWeightBias: 2);
    await tester.pumpWidget(wrap(const GoopText('Plain')));
    expect(rendered(tester).style?.fontWeight, isNull);
  });

  testWidgets('fontLetterSpacing adds half-steps to letterSpacing', (
    tester,
  ) async {
    VisualPrefs.notifier.value = const VisualPrefs(fontLetterSpacing: 2);
    await tester.pumpWidget(
      wrap(const GoopText('Spaced', style: TextStyle(letterSpacing: 1))),
    );
    // spacing 2 × 0.5 = +1.0 on top of the base 1.0.
    expect(rendered(tester).style?.letterSpacing, 2.0);
  });

  testWidgets('maxLines/overflow/textAlign pass through', (tester) async {
    await tester.pumpWidget(
      wrap(
        const GoopText(
          'Clipped',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
    final t = rendered(tester);
    expect(t.maxLines, 1);
    expect(t.overflow, TextOverflow.ellipsis);
    expect(t.textAlign, TextAlign.center);
  });

  testWidgets('GoopAnimationManager progress is pinned at 1.0', (tester) async {
    // The scramble mechanic was removed — the manager must stay inert.
    expect(GoopAnimationManager.instance.progress.value, 1.0);
  });
}
