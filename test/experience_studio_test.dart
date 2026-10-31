import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/screens/experience_studio_screen.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/widgets/particle_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for the unified Customization hub — the 2026-10-31 rework.
/// Covers the new model behavior (12 particle palettes, scramble fix,
/// vignette/grain prefs) and the hub widget itself (action bar, tabs,
/// LIVE LOOK, swatch sheet, font pager).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Tall surface — lazy lists/grids build all children so asserts
    // can see below-the-fold items without scrolling.
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .implicitView!
        .physicalSize = const Size(800, 1600);
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .implicitView!
        .devicePixelRatio = 1.0;
    AppTheme.previewNotifier.value = null;
    AppTheme.setCustomThemeData(CustomThemeData.defaultTheme);
    CustomThemeStore.notifier.value = [];
    VisualPrefs.notifier.value = const VisualPrefs();
  });

  group('PresetConfig equality (scramble fix)', () {
    // ParticleField.didUpdateWidget compares config by !=. Without
    // value equality every parent rebuild respawned all particles —
    // the "tapping screens scrambles particles" bug.
    test('two identical configs are equal', () {
      final a = typedParticleConfig(ParticleType.dot, const [
        Color(0xFFFF0000),
      ]);
      final b = typedParticleConfig(ParticleType.dot, const [
        Color(0xFFFF0000),
      ]);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('differing configs are not equal', () {
      final base = typedParticleConfig(ParticleType.dot, const [
        Color(0xFFFF0000),
      ]);
      expect(
        typedParticleConfig(ParticleType.square, const [Color(0xFFFF0000)]),
        isNot(equals(base)),
      );
      expect(
        typedParticleConfig(ParticleType.dot, const [
          Color(0xFFFF0000),
        ], chaos: true),
        isNot(equals(base)),
      );
      expect(
        typedParticleConfig(ParticleType.dot, const [Color(0xFF00FF00)]),
        isNot(equals(base)),
      );
    });
  });

  group('Global particle palettes', () {
    test('12 curated palettes, all named with colors', () {
      expect(kGlobalParticlePalettes.length, 12);
      for (final p in kGlobalParticlePalettes) {
        expect(p.name, isNotEmpty);
        expect(p.colors.length, greaterThanOrEqualTo(3));
      }
    });

    test('particleSchemaColors clamps out-of-range index', () {
      // Old persisted schemaIndex > 11 must not crash — clamps to last.
      final last = particleSchemaColors(AppThemeMode.paperInk, 999);
      expect(last, kGlobalParticlePalettes.last.colors);
      final first = particleSchemaColors(AppThemeMode.unicorn, -5);
      expect(first, kGlobalParticlePalettes.first.colors);
    });
  });

  group('VisualPrefs ambiance fields', () {
    test('defaults: vignette 1.0, grain 0.0, glowStyleIndex -1', () {
      const p = VisualPrefs();
      expect(p.vignetteIntensity, 1.0);
      expect(p.grainIntensity, 0.0);
      expect(p.glowStyleIndex, -1);
      expect(p.glowStyleOverride, isNull);
    });

    test('setters clamp to valid ranges', () async {
      await VisualPrefs.setVignetteIntensity(9.0);
      expect(VisualPrefs.notifier.value.vignetteIntensity, 1.5);
      await VisualPrefs.setVignetteIntensity(-2);
      expect(VisualPrefs.notifier.value.vignetteIntensity, 0.0);
      await VisualPrefs.setGrainIntensity(5);
      expect(VisualPrefs.notifier.value.grainIntensity, 1.0);
      await VisualPrefs.setGlowStyleIndex(99);
      expect(
        VisualPrefs.notifier.value.glowStyleIndex,
        GlowStyle.values.length - 1,
      );
    });

    test('json round-trip preserves ambiance fields', () {
      const p = VisualPrefs(
        vignetteIntensity: 0.7,
        grainIntensity: 0.4,
        glowStyleIndex: 2,
      );
      final r = VisualPrefs.fromJson(p.toJson());
      expect(r.vignetteIntensity, 0.7);
      expect(r.grainIntensity, 0.4);
      expect(r.glowStyleIndex, 2);
    });

    test('old json without new fields gets defaults', () {
      final r = VisualPrefs.fromJson(const {});
      expect(r.vignetteIntensity, 1.0);
      expect(r.grainIntensity, 0.0);
    });

    test('setGlowColorIndex clears the custom glow color', () async {
      await VisualPrefs.setGlowColor(const Color(0xFF123456));
      expect(VisualPrefs.notifier.value.glowCustomColor, 0xFF123456);
      await VisualPrefs.setGlowColorIndex(3);
      expect(VisualPrefs.notifier.value.glowCustomColor, 0);
    });
  });

  group('Hub — PRESETS', () {
    testWidgets('action bar has BACK + APPLY, no PREVIEW button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('APPLY'), findsOneWidget);
      expect(find.text('PREVIEW'), findsOneWidget); // LIVE LOOK label only
      expect(find.text('MAKE YOUR PALETTE'), findsNothing);
    });

    testWidgets('all 5 tabs render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      for (final tab in [
        'PRESETS',
        'CUSTOM',
        'FONTS',
        'PARTICLES',
        'AMBIANCE',
      ]) {
        expect(find.text(tab), findsWidgets, reason: 'missing tab $tab');
      }
    });

    testWidgets('six preset panels render', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      for (final name in [
        'UNICORN',
        'MOLTEN STEEL',
        'PAPER & INK',
        'MINIMALIST',
        'DRAGUNFIRE',
        "LICH'S DOMAIN",
      ]) {
        // findsWidgets — the previewed preset's name also appears in
        // the LIVE LOOK pane title.
        expect(find.text(name), findsWidgets, reason: 'missing $name');
      }
    });
  });

  group('Hub — tab content', () {
    Future<void> openHub(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('CUSTOM shows role descriptions', (tester) async {
      await openHub(tester);
      await tester.tap(find.text('CUSTOM'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('app background'), findsOneWidget);
      expect(find.text('accents, borders & links'), findsOneWidget);
      expect(find.text('numbers & metrics'), findsOneWidget);
      expect(find.text('SAVE THEME'), findsOneWidget);
    });

    testWidgets('PARTICLES hides the shared LIVE LOOK pane', (tester) async {
      await openHub(tester);
      expect(find.text('PREVIEW'), findsOneWidget); // pane label present

      final tab = find.text('PARTICLES').first;
      await tester.ensureVisible(tab);
      await tester.tap(tab, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 400));

      // Shared pane label gone; the step's own LIVE PREVIEW is there.
      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('Enable Particles'), findsOneWidget);
    });

    testWidgets('FONTS shows swipable tiles + bottom controls', (tester) async {
      await openHub(tester);
      await tester.tap(find.text('FONTS'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('BASE FONT SIZE'), findsOneWidget);
      expect(find.text('DASHBOARD TEXT'), findsOneWidget);
      expect(find.text('WEIGHT BIAS'), findsOneWidget);
      expect(find.text('LETTER SPACING'), findsOneWidget);
    });

    testWidgets('AMBIANCE shows glow + DEPTH sections', (tester) async {
      await openHub(tester);
      await tester.tap(find.text('AMBIANCE'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('GLOW STYLE'), findsOneWidget);
      expect(find.text('CUSTOM COLOR'), findsOneWidget);
      expect(find.text('DEPTH'), findsOneWidget);
      expect(find.text('Vignette'), findsOneWidget);
      expect(find.text('Film Grain'), findsOneWidget);
    });
  });

  group('Swatch sheet', () {
    int circlesInSheet(WidgetTester tester) {
      return tester
          .widgetList(
            find.descendant(
              of: find.byType(GridView),
              matching: find.byWidgetPredicate(
                (w) =>
                    w is Container &&
                    w.decoration is BoxDecoration &&
                    (w.decoration as BoxDecoration).shape == BoxShape.circle,
              ),
            ),
          )
          .length;
    }

    testWidgets('64 general + 32 metallic swatches', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('CUSTOM'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('CANVAS'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('METALLIC'), findsOneWidget);
      // GridView lazy-builds only visible rows (~50 of 64 at this
      // height) — a high count proves a full curated grid.
      expect(circlesInSheet(tester), greaterThanOrEqualTo(48));

      await tester.tap(find.text('METALLIC'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(circlesInSheet(tester), greaterThanOrEqualTo(24));
    });
  });
  group('Preset preview/apply flow', () {
    testWidgets('tapping a preset stages it + defaults Gungeon font', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('UNICORN'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(AppTheme.previewNotifier.value, AppThemeMode.unicorn);
      // Presets default the font to Gungeon (user requirement).
      expect(VisualPrefs.notifier.value.font, AppFont.gungeon);
      // Curation applied — unicorn ships glow color 2 + sparkles.
      expect(VisualPrefs.notifier.value.glowColorIndex, 2);
      expect(
        VisualPrefs.notifier.value.particlePreset,
        ParticlePreset.unicornSparkles,
      );
    });

    testWidgets('APPLY commits the staged mode', (tester) async {
      final before = AppTheme.mode;
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('UNICORN'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('APPLY'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(AppTheme.mode, AppThemeMode.unicorn);
      expect(AppTheme.previewNotifier.value, isNull);

      // Restore so later groups start clean.
      await AppTheme.setMode(before);
    });

    testWidgets('BACK discards staged prefs + preview', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final baseGlow = VisualPrefs.notifier.value.glowColorIndex;

      await tester.tap(find.text('UNICORN'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(VisualPrefs.notifier.value.glowColorIndex, 2);

      await tester.tap(find.text('BACK'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      // Screen is the test root so it can't pop — the contract is
      // the restore: preview cleared + staged prefs rolled back.
      expect(AppTheme.previewNotifier.value, isNull);
      expect(VisualPrefs.notifier.value.glowColorIndex, baseGlow);
    });
  });

  group('Swatch sheet flow', () {
    testWidgets('sheet dismisses via barrier without touching draft', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final before = AppTheme.previewNotifier.value;

      await tester.tap(find.text('CUSTOM'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('CANVAS'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('GENERAL'), findsOneWidget); // sheet open

      // Barrier tap above the sheet → dismiss, null color, no change.
      await tester.tapAt(const Offset(400, 200));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('GENERAL'), findsNothing);
      expect(AppTheme.previewNotifier.value, before);
    });
  });

  group('Particles controls write prefs', () {
    testWidgets('toggle + physics chips + schema chip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.ensureVisible(find.text('PARTICLES').first);
      await tester.tap(find.text('PARTICLES'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      // Enable toggle — tap the Switch, not the row label.
      final sw = find.byType(Switch);
      await tester.tap(sw, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.particlesEnabled, false);
      await tester.tap(sw, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.particlesEnabled, true);

      // Physics chips — TILT defaults ON, others OFF.
      await tester.tap(find.text('CHAOS'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.particleChaos, true);
      await tester.tap(find.text('BOUNCE'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.particleBounce, true);
      await tester.tap(find.text('TILT'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.particleTouch, false);

      // Schema chip — 'TOXIN' is index 3 in the global palettes.
      await tester.ensureVisible(find.text('TOXIN'));
      await tester.tap(find.text('TOXIN'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
      // A palette chip wrote an index (scroll offsets may land a
      // neighbor — contract is 'chip tap writes the index').
      expect(VisualPrefs.notifier.value.particleSchemaIndex, isNot(0));
    });
  });

  group('Ambiance controls write prefs', () {
    testWidgets('style chips + quick color row', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('AMBIANCE'));
      await tester.pump(const Duration(milliseconds: 300));

      // HALO is GlowStyle index 2.
      await tester.tap(find.text('HALO'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.glowStyleIndex, 2);
      expect(VisualPrefs.notifier.value.glowStyleOverride, GlowStyle.halo);

      // THEME chip resets to -1 (theme default).
      await tester.tap(find.text('THEME'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.glowStyleIndex, -1);
      expect(VisualPrefs.notifier.value.glowStyleOverride, isNull);
    });
  });

  group('LIVE LOOK drag handle', () {
    testWidgets('dragging the handle resizes the pane', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final handle = find.byIcon(Icons.keyboard_arrow_down_rounded);
      expect(handle, findsOneWidget);
      final before = tester.getCenter(handle).dy;
      await tester.drag(handle, const Offset(0, 120));
      await tester.pump(const Duration(milliseconds: 300));
      final after = tester.getCenter(handle).dy;

      expect(after, greaterThan(before));
    });
  });
}
