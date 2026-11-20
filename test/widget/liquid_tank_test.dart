import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/widgets/particles/liquid_tank.dart';

/// Widget tests for LiquidTankField — the ambient "liquid tank"
/// backdrop (bubbly rising fill + tilt-driven shells).
///
/// The field runs a repeating AnimationController, so pump() with
/// finite durations is used instead of pumpAndSettle().
void main() {
  group('LiquidKind enum', () {
    test('has exactly 5 values ending in shells', () {
      expect(LiquidKind.values.length, 5);
      expect(LiquidKind.values.last, LiquidKind.shells);
    });

    test('labels cover every kind', () {
      for (final k in LiquidKind.values) {
        expect(k.label, isNotEmpty);
      }
    });
  });

  group('LiquidTankField widget', () {
    for (final kind in [
      LiquidKind.blood,
      LiquidKind.venom,
      LiquidKind.umbra,
      LiquidKind.shells,
    ]) {
      testWidgets('renders $kind without crashing', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox.expand(
                child: LiquidTankField(kind: kind),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byType(LiquidTankField), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('kind switch re-fills without crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LiquidTankField(kind: LiquidKind.blood)),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LiquidTankField(kind: LiquidKind.venom)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('accepts a tilt listenable for shells', (tester) async {
      final tilt = ValueNotifier<Offset>(Offset.zero);
      addTearDown(tilt.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidTankField(kind: LiquidKind.shells, tilt: tilt),
          ),
        ),
      );
      await tester.pump();
      tilt.value = const Offset(4, -3);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not leak controllers after disposal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LiquidTankField(kind: LiquidKind.blood)),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('VisualPrefs liquidKindIndex', () {
    test('defaults to off (0)', () {
      expect(const VisualPrefs().liquidKindIndex, 0);
    });

    test('JSON round-trip preserves the pick', () {
      const prefs = VisualPrefs(liquidKindIndex: 3);
      final restored = VisualPrefs.fromJson(prefs.toJson());
      expect(restored.liquidKindIndex, 3);
    });

    test('fromJson clamps out-of-range indices', () {
      final restored = VisualPrefs.fromJson({'liquidKindIndex': 99});
      expect(restored.liquidKindIndex, LiquidKind.values.length - 1);
    });
  });
}
