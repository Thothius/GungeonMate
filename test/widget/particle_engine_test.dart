import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/widgets/particle_engine.dart';

void main() {
  group('preset config tables', () {
    test('every ParticlePreset exposes a non-empty config', () {
      for (final p in ParticlePreset.values) {
        final c = p.config;
        expect(c.colors, isNotEmpty, reason: '$p has no colors');
        expect(c.sizeMax, greaterThanOrEqualTo(c.sizeMin),
            reason: '$p sizeMax < sizeMin');
        expect(c.speedMax, greaterThanOrEqualTo(c.speedMin),
            reason: '$p speedMax < speedMin');
        expect(p.label, isNotEmpty);
        expect(p.description, isNotEmpty);
      }
    });

    test('every ParticleSpeed exposes label + multiplier', () {
      for (final s in ParticleSpeed.values) {
        expect(s.label, isNotEmpty);
        expect(s.multiplier, greaterThan(0));
      }
    });

    test('every ParticleColorSchema exposes label + colors', () {
      for (final s in ParticleColorSchema.values) {
        expect(s.label, isNotEmpty);
        final c = s.colors;
        if (c != null) {
          expect(c, isNotEmpty);
        }
      }
    });
  });

  group('typedParticleConfig', () {
    const colors = [Color(0xFFFF0000), Color(0xFF00FF00)];

    test('every ParticleType builds a valid config', () {
      for (final t in ParticleType.values) {
        final calm = typedParticleConfig(t, colors);
        final chaosCfg = typedParticleConfig(t, colors, chaos: true);
        for (final c in [calm, chaosCfg]) {
          expect(c.colors, isNotEmpty, reason: '$t');
          expect(c.sizeMax, greaterThanOrEqualTo(c.sizeMin));
          expect(c.turbulence, greaterThanOrEqualTo(0));
        }
        expect(chaosCfg.turbulence, greaterThanOrEqualTo(calm.turbulence),
            reason: '$t chaos should not reduce turbulence');
      }
    });
  });

  group('ParticleField widget', () {
    Future<void> pumpField(
      WidgetTester tester, {
      ParticlePreset preset = ParticlePreset.gungeonDust,
      PresetConfig? config,
      int count = 8,
      List<Color>? colorsOverride,
      GlowEffect? glowOverride,
      bool? lineLinksOverride,
      bool bounce = false,
      bool tiltEnabled = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: ParticleField(
                preset: preset,
                config: config,
                count: count,
                colorsOverride: colorsOverride,
                glowOverride: glowOverride,
                lineLinksOverride: lineLinksOverride,
                bounce: bounce,
                tiltEnabled: tiltEnabled,
              ),
            ),
          ),
        ),
      );
      // Fixed pumps — the ticker repeats forever; never pumpAndSettle.
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.takeException(), isNull);
    }

    testWidgets('renders preset path without exception', (tester) async {
      await pumpField(tester);
      expect(find.byType(ParticleField), findsOneWidget);
    });

    testWidgets('renders typed-config override path', (tester) async {
      final cfg = typedParticleConfig(ParticleType.star, [
        const Color(0xFFFFFFFF),
      ]);
      await pumpField(tester, config: cfg);
    });

    testWidgets('renders with color/glow/link overrides and bounce',
        (tester) async {
      await pumpField(
        tester,
        preset: ParticlePreset.bulletHell,
        colorsOverride: const [Color(0xFF00FFFF)],
        glowOverride: GlowEffect.neon,
        lineLinksOverride: true,
        bounce: true,
        tiltEnabled: true,
      );
    });

    testWidgets('preset change respawns particles without exception',
        (tester) async {
      Widget build(ParticlePreset p) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 200,
                height: 200,
                child: ParticleField(preset: p, count: 6),
              ),
            ),
          );
      await tester.pumpWidget(build(ParticlePreset.gungeonDust));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(build(ParticlePreset.frostShards));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(build(ParticlePreset.voidRift));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });
  });
}
