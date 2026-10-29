import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/widgets/particles/ambient_glow.dart';
import 'package:gungeon_mate/services/app_theme.dart';

/// Unit + widget tests for AmbientGlow — the animated background gradient
/// layer that sits behind all themed content.
///
/// AmbientGlow uses a repeating AnimationController (perpetual), so we
/// use pump() with finite durations rather than pumpAndSettle().
void main() {
  group('GlowStyle enum', () {
    test('has exactly 4 values', () {
      expect(GlowStyle.values.length, 4);
    });

    test('values are orbit, ember, halo, drip', () {
      expect(GlowStyle.values, containsAll([
        GlowStyle.orbit,
        GlowStyle.ember,
        GlowStyle.halo,
        GlowStyle.drip,
      ]));
    });
  });

  group('AmbientGlow widget', () {
    testWidgets('renders without crashing with orbit style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0x44FF0000),
              secondary: Color(0x2200FF00),
              style: GlowStyle.orbit,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientGlow), findsOneWidget);
    });

    testWidgets('renders without crashing with ember style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0x44FF0000),
              secondary: Color(0x2200FF00),
              style: GlowStyle.ember,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientGlow), findsOneWidget);
    });

    testWidgets('renders without crashing with halo style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0x44FF0000),
              secondary: Color(0x2200FF00),
              style: GlowStyle.halo,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientGlow), findsOneWidget);
    });

    testWidgets('renders without crashing with drip style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0x44FF0000),
              secondary: Color(0x2200FF00),
              style: GlowStyle.drip,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientGlow), findsOneWidget);
    });

    testWidgets('renders with tertiary color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0x44FF0000),
              secondary: Color(0x2200FF00),
              tertiary: Color(0x330000FF),
              style: GlowStyle.halo,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientGlow), findsOneWidget);
    });

    testWidgets('renders without tertiary color (null fallback)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0x44FF0000),
              secondary: Color(0x2200FF00),
              style: GlowStyle.halo,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientGlow), findsOneWidget);
    });

    testWidgets('renders with default style (orbit)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0x44FF0000),
              secondary: Color(0x2200FF00),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientGlow), findsOneWidget);
    });

    testWidgets('renders with transparent colors without crashing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0x00000000),
              secondary: Color(0x00000000),
              style: GlowStyle.orbit,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientGlow), findsOneWidget);
    });

    testWidgets('renders with fully opaque colors without crashing',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0xFFFF0000),
              secondary: Color(0xFF00FF00),
              style: GlowStyle.ember,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientGlow), findsOneWidget);
    });

    testWidgets('produces gradient decorations for each style', (tester) async {
      for (final style in GlowStyle.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AmbientGlow(
                primary: const Color(0x44FF0000),
                secondary: const Color(0x2200FF00),
                style: style,
              ),
            ),
          ),
        );
        await tester.pump();

        // Each style renders at least one DecoratedBox with a gradient
        final decoratedBoxes = tester.widgetList<DecoratedBox>(
          find.byType(DecoratedBox),
        );
        final hasGradient = decoratedBoxes.any((db) {
          final decoration = db.decoration;
          if (decoration is BoxDecoration) {
            return decoration.gradient != null;
          }
          return false;
        });
        expect(hasGradient, isTrue, reason: 'Style $style should produce a gradient');
      }
    });

    testWidgets('does not leak controller after disposal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0x44FF0000),
              secondary: Color(0x2200FF00),
            ),
          ),
        ),
      );
      await tester.pump();

      // Dispose the widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      // If the controller wasn't disposed, this would throw
      // a "controller used after dispose" error
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles style change via didUpdateWidget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0x44FF0000),
              secondary: Color(0x2200FF00),
              style: GlowStyle.orbit,
            ),
          ),
        ),
      );
      await tester.pump();

      // Change to ember style
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AmbientGlow(
              primary: Color(0x44FF0000),
              secondary: Color(0x2200FF00),
              style: GlowStyle.ember,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(AmbientGlow), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ThemeFlair glowStyle integration', () {
    test('ThemeFlair has glowStyle field with default orbit', () {
      const flair = ThemeFlair(
        scaffold: Color(0xFF000000),
        card: Color(0xFF111111),
        primary: Color(0xFFFFFFFF),
        secondary: Color(0xFF888888),
        headlineStat: Color(0xFFFFFFFF),
        bulletColor: Color(0xFFFFFFFF),
      );
      expect(flair.glowStyle, GlowStyle.orbit);
    });

    test('ThemeFlair can set glowStyle to non-default', () {
      const flair = ThemeFlair(
        scaffold: Color(0xFF000000),
        card: Color(0xFF111111),
        primary: Color(0xFFFFFFFF),
        secondary: Color(0xFF888888),
        headlineStat: Color(0xFFFFFFFF),
        bulletColor: Color(0xFFFFFFFF),
        glowStyle: GlowStyle.ember,
      );
      expect(flair.glowStyle, GlowStyle.ember);
    });
  });
}
