import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/widgets/particles/ambient_field.dart';

/// Widget tests for AmbientField — the procedural atmosphere backdrop
/// (god-rays / ash / runes / scanlines / abyss painter scenes).
///
/// The field runs a repeating AnimationController, so pump() with
/// finite durations is used instead of pumpAndSettle().
void main() {
  group('AmbientKind enum', () {
    test('has exactly 6 values starting with off', () {
      expect(AmbientKind.values.length, 6);
      expect(AmbientKind.values.first, AmbientKind.off);
    });

    test('labels cover every kind', () {
      for (final k in AmbientKind.values) {
        expect(k.label, isNotEmpty);
      }
    });
  });

  group('AmbientField widget', () {
    for (final kind in [
      AmbientKind.godRays,
      AmbientKind.ash,
      AmbientKind.runes,
      AmbientKind.scanlines,
      AmbientKind.abyss,
    ]) {
      testWidgets('renders $kind without crashing', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox.expand(
                child: AmbientField(
                  kind: kind,
                  primary: const Color(0xFF7C4DFF),
                  secondary: const Color(0xFF00E5FF),
                  tertiary: const Color(0xFFFFD54F),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(AmbientField), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('kind switch repaints without crash', (tester) async {
      Widget field(AmbientKind k) => MaterialApp(
        home: Scaffold(
          body: AmbientField(
            kind: k,
            primary: const Color(0xFF7C4DFF),
            secondary: const Color(0xFF00E5FF),
            tertiary: const Color(0xFFFFD54F),
          ),
        ),
      );
      await tester.pumpWidget(field(AmbientKind.ash));
      await tester.pump();
      await tester.pumpWidget(field(AmbientKind.runes));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced-motion renders a stable frame', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: AmbientField(
                kind: AmbientKind.godRays,
                primary: Color(0xFF7C4DFF),
                secondary: Color(0xFF00E5FF),
                tertiary: Color(0xFFFFD54F),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AmbientField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('GlowStyle additions', () {
    test('prism and ripple appended at end — persisted indices stable', () {
      expect(GlowStyle.values.length, 6);
      expect(GlowStyle.values[4], GlowStyle.prism);
      expect(GlowStyle.values[5], GlowStyle.ripple);
    });
  });
}
