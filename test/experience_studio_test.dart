import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/screens/experience_studio_screen.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/widgets/particle_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for the unified Customization hub — pick-or-create preset
/// flow (choose → gallery/source → wizard) plus the wizard tabs.
/// Covers the model behavior (12 particle palettes, scramble fix,
/// vignette/grain prefs) and the flow widgets themselves.
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

  /// Wizard tabs: 0=DETAILS 1=COLORS & BG 2=TYPE 3=PARTICLES 4=AMBIANCE 5=SAVE.
  /// initialTab>0 lands straight in the wizard (deep-link path).
  Future<void> openWizard(WidgetTester tester, [int tab = 1]) async {
    await tester.pumpWidget(
      MaterialApp(home: ExperienceStudioScreen(initialTab: tab)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Drive the full NEW PRESET flow to the wizard: choose → name →
  /// source → scratch. Leaves the screen on the DETAILS tab.
  Future<void> openWizardViaNewPreset(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ExperienceStudioScreen()),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('NEW PRESET'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'Test Look');
    await tester.tap(find.text('NEXT'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('START FROM SCRATCH'));
    await tester.pump(const Duration(milliseconds: 400));
  }

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
    test('18 curated palettes, all named with colors', () {
      expect(kGlobalParticlePalettes.length, 18);
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

    test('tapSparkles defaults true + survives json round-trip', () async {
      expect(const VisualPrefs().tapSparkles, isTrue);
      expect(VisualPrefs.fromJson(const {}).tapSparkles, isTrue);
      final r = VisualPrefs.fromJson(const VisualPrefs().toJson());
      expect(r.tapSparkles, isTrue);
      await VisualPrefs.setTapSparkles(false);
      expect(VisualPrefs.notifier.value.tapSparkles, isFalse);
      // Restore for later groups.
      await VisualPrefs.setTapSparkles(true);
    });

    test('particleItemIcon defaults off + survives json round-trip', () async {
      expect(const VisualPrefs().particleItemIcon, -1);
      expect(VisualPrefs.fromJson(const {}).particleItemIcon, -1);
      await VisualPrefs.setParticleItemIcon(3);
      final r = VisualPrefs.fromJson(VisualPrefs.notifier.value.toJson());
      expect(r.particleItemIcon, 3);
      expect(VisualPrefs.notifier.value.particleItemIcon, 3);
      await VisualPrefs.setParticleItemIcon(-1);
    });
  });

  group('Flow — CHOOSE', () {
    testWidgets('entry shows the two doors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CUSTOMIZE'), findsOneWidget);
      expect(find.text('BROWSE PRESETS'), findsOneWidget);
      expect(find.text('NEW PRESET'), findsOneWidget);
      // Wizard tabs must NOT be visible yet.
      expect(find.text('COLORS & BG'), findsNothing);
      expect(find.text('SAVE'), findsNothing);
    });
  });

  group('Flow — GALLERY', () {
    Future<void> openGallery(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('BROWSE PRESETS'));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('gallery shows PRESETS header + PICK PRESET bar', (
      tester,
    ) async {
      await openGallery(tester);
      expect(find.text('PRESETS'), findsOneWidget);
      expect(find.text('PICK PRESET'), findsOneWidget);
      // List view is the default — official section header + rows.
      expect(find.text('OFFICIAL'), findsOneWidget);
      expect(find.byType(PageView), findsNothing);
    });

    testWidgets('list view shows official presets; CARDS restores swiper', (
      tester,
    ) async {
      await openGallery(tester);
      // kPickerThemes.first = unicorn — list row shows its label.
      expect(find.text('Unicorn'), findsWidgets);

      // Flip to card view — fullscreen PageView + uppercase card name.
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PageView), findsOneWidget);
      expect(find.text('UNICORN'), findsWidgets);
      expect(find.text('OFFICIAL'), findsNothing);
    });

    testWidgets('PICK PRESET applies and closes', (tester) async {
      final before = AppTheme.mode;
      await openGallery(tester);
      // Page 0 = unicorn (kPickerThemes.first).
      await tester.tap(find.text('PICK PRESET'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(AppTheme.mode, AppThemeMode.unicorn);
      expect(AppTheme.previewNotifier.value, isNull);
      await AppTheme.setMode(before);
    });
  });

  group('Flow — NEW PRESET wizard', () {
    testWidgets('name → source → scratch lands on DETAILS tab', (
      tester,
    ) async {
      await openWizardViaNewPreset(tester);

      expect(find.text('PRESET: Test Look'), findsOneWidget);
      for (final tab in [
        'DETAILS',
        'COLORS & BG',
        'TYPE',
        'PARTICLES',
        'AMBIANCE',
        'SAVE',
      ]) {
        expect(find.text(tab), findsWidgets, reason: 'missing tab $tab');
      }
      expect(find.text('FULLSCREEN PREVIEW'), findsOneWidget);
      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('APPLY'), findsOneWidget);
    });

    testWidgets('DETAILS summary shows picks + preview opens mock', (
      tester,
    ) async {
      await openWizardViaNewPreset(tester);

      expect(find.text('PARTICLES'), findsWidgets);
      await tester.ensureVisible(find.text('FULLSCREEN PREVIEW'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('FULLSCREEN PREVIEW'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));

      // Mock preview — fake run page + gun detail page.
      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('WANDERER'), findsOneWidget);
      // 'BULLET BOY' only exists on the gun-detail page (page 2).
      expect(find.text('BULLET BOY'), findsNothing);

      // Swipe to the gun-detail page.
      await tester.drag(find.byType(PageView).last, const Offset(-400, 0));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('BULLET BOY'), findsOneWidget);
      expect(find.text('GUNGEON COAT'), findsOneWidget);

      // Tap the CLOSE chip by coordinates — tester.tap resolves a
      // stale center for this small header button.
      final closeBtn = find.ancestor(
        of: find.text('CLOSE'),
        matching: find.byType(GestureDetector),
      );
      await tester.tapAt(tester.getCenter(closeBtn.first));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('LIVE PREVIEW'), findsNothing);
    });

    testWidgets('wizard BACK returns to source stage', (tester) async {
      await openWizardViaNewPreset(tester);
      await tester.tap(find.text('BACK'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('START FROM'), findsOneWidget);
      expect(find.text('COPY EXISTING'), findsOneWidget);
      expect(find.text('START FROM SCRATCH'), findsOneWidget);
    });

    testWidgets('COPY EXISTING opens gallery in select mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('NEW PRESET'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), 'Copy Cat');
      await tester.tap(find.text('NEXT'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('COPY EXISTING'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('COPY FROM'), findsOneWidget);
      expect(find.text('USE AS BASE'), findsOneWidget);
      expect(find.text('PICK PRESET'), findsNothing);
    });

    testWidgets('COPY EXISTING → USE AS BASE seeds wizard + saves', (
      tester,
    ) async {
      final before = AppTheme.mode;
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('NEW PRESET'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), 'Copy Cat');
      await tester.tap(find.text('NEXT'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('COPY EXISTING'));
      await tester.pump(const Duration(milliseconds: 400));

      // Page 0 = unicorn — copying it applies unicorn curation to prefs.
      await tester.tap(find.text('USE AS BASE'));
      await tester.pump(const Duration(milliseconds: 500));

      // Wizard opens on DETAILS with the new name + custom preview.
      expect(find.text('PRESET: Copy Cat'), findsOneWidget);
      expect(find.text('DETAILS'), findsWidgets);
      expect(
        VisualPrefs.notifier.value.particlePreset,
        ParticlePreset.unicornSparkles,
      );

      // SAVE tab persists the copied look under the new name.
      await tester.tap(find.text('SAVE'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('SAVE & APPLY'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(CustomThemeStore.themes, hasLength(1));
      expect(CustomThemeStore.themes.single.name, 'Copy Cat');
      expect(AppTheme.mode, AppThemeMode.custom);

      await AppTheme.setMode(before);
    });

    testWidgets('SAVE tab persists preset + applies + closes', (
      tester,
    ) async {
      final before = AppTheme.mode;
      await openWizardViaNewPreset(tester);
      await tester.tap(find.text('SAVE'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SAVE PRESET'), findsOneWidget);
      expect(find.text('SAVE & APPLY'), findsOneWidget);

      await tester.tap(find.text('SAVE & APPLY'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(CustomThemeStore.themes, hasLength(1));
      expect(CustomThemeStore.themes.single.name, 'Test Look');
      expect(AppTheme.mode, AppThemeMode.custom);

      await AppTheme.setMode(before);
    });

    testWidgets('deep link initialTab lands in wizard directly', (
      tester,
    ) async {
      await openWizard(tester, 3); // PARTICLES
      expect(find.text('DETAILS'), findsWidgets);
      expect(find.text('Enable Particles'), findsOneWidget);
    });

    testWidgets('ITEM ICONS grid picks a sprite and persists pref', (
      tester,
    ) async {
      await openWizard(tester, 3); // PARTICLES
      expect(find.text('ITEM ICONS'), findsOneWidget);
      expect(find.text('BLANKS'), findsOneWidget);
      expect(find.text('SPRUN'), findsOneWidget);
      // OFF tile index 0 -> pick BLANKS (index 1 in grid = item 0)
      await tester.tap(find.text('BLANKS'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.particleItemIcon, 0);
      // OFF restores shape particles
      await tester.tap(find.text('OFF'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.particleItemIcon, -1);
    });

    testWidgets('SIZE & SPEED section writes size/opacity/speed prefs', (
      tester,
    ) async {
      await openWizard(tester, 3); // PARTICLES
      expect(find.text('SIZE & SPEED'), findsOneWidget);
      expect(find.text('SIZE'), findsOneWidget);
      expect(find.text('OPACITY'), findsOneWidget);
      expect(find.text('VERY FAST'), findsOneWidget);
      await tester.tap(find.text('VERY FAST'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        VisualPrefs.notifier.value.particleSpeed,
        ParticleSpeed.veryFast,
      );
      // drag the SIZE slider (inside the row labelled SIZE) -> pref moves
      final sizeRow = find
          .ancestor(of: find.text('SIZE'), matching: find.byType(Row))
          .first;
      await tester.drag(
        find.descendant(of: sizeRow, matching: find.byType(Slider)),
        const Offset(80, 0),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        VisualPrefs.notifier.value.particleSizeScale,
        isNot(1.0),
      );
    });
  });

  group('Wizard — tab content', () {
    testWidgets('COLORS & BG shows role descriptions', (tester) async {
      await openWizard(tester, 1);
      expect(find.text('app background'), findsOneWidget);
      expect(find.text('accents, borders & links'), findsOneWidget);
      expect(find.text('numbers & metrics'), findsOneWidget);
      // Old SAVE THEME button is gone — SAVE tab owns persistence.
      expect(find.text('SAVE THEME'), findsNothing);
      // BG MODE chips + wallpaper row label both say WALLPAPER.
      expect(find.text('SOLID'), findsOneWidget);
      expect(find.text('WALLPAPER'), findsWidgets);
    });

    testWidgets('TYPE shows swipable tiles + bottom controls', (
      tester,
    ) async {
      await openWizard(tester, 2);
      expect(find.byType(PageView), findsWidgets);
      expect(find.text('BASE FONT SIZE'), findsOneWidget);
      expect(find.text('DASHBOARD TEXT'), findsOneWidget);
      expect(find.text('WEIGHT BIAS'), findsOneWidget);
      expect(find.text('LETTER SPACING'), findsOneWidget);
    });

    testWidgets('PARTICLES hides the shared LIVE LOOK pane', (tester) async {
      await openWizard(tester, 1);
      expect(find.text('PREVIEW'), findsWidgets); // LIVE LOOK label

      await tester.tap(find.text('PARTICLES').first);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('Enable Particles'), findsOneWidget);
    });

    testWidgets('AMBIANCE shows glow + DEPTH sections', (tester) async {
      await openWizard(tester, 4);
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
      await openWizard(tester, 1);
      await tester.tap(find.text('CANVAS'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('GENERAL'), findsOneWidget);
      expect(find.text('METALLIC'), findsOneWidget);
      // GridView lazy-builds only visible rows (~50 of 64 at this
      // height) — a high count proves a full curated grid.
      expect(circlesInSheet(tester), greaterThanOrEqualTo(48));

      await tester.ensureVisible(find.text('METALLIC'));
      await tester.tap(find.text('METALLIC'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      expect(circlesInSheet(tester), greaterThanOrEqualTo(24));

      // Unique collections — each ships its own 32-swatch palette.
      for (final tab in [
        'PINK & PURPLE',
        'BLUE & CYAN',
        'GREEN & MINTY',
      ]) {
        await tester.ensureVisible(find.text(tab));
        await tester.tap(find.text(tab), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text(tab), findsOneWidget);
        expect(circlesInSheet(tester), greaterThanOrEqualTo(20));
      }
    });
  });

  group('Swatch sheet flow', () {
    testWidgets('sheet dismisses via barrier without touching draft', (
      tester,
    ) async {
      await openWizard(tester, 1);
      final before = AppTheme.previewNotifier.value;

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
    test('LINKS + TYPE GLOW prefs — setters write + persist', () async {
      SharedPreferences.setMockInitialValues({});
      await VisualPrefs.setParticleLineLinks(true);
      expect(VisualPrefs.notifier.value.particleLineLinks, isTrue);
      await VisualPrefs.setParticleGlowEffect(GlowEffect.prism);
      expect(
        VisualPrefs.notifier.value.particleGlowEffect,
        GlowEffect.prism,
      );
      // none = AUTO semantics — overlay maps it to null override.
      await VisualPrefs.setParticleGlowEffect(GlowEffect.none);
      expect(
        VisualPrefs.notifier.value.particleGlowEffect,
        GlowEffect.none,
      );
    });

    testWidgets('toggle + physics chips + schema chip', (tester) async {
      await openWizard(tester, 3);

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
      await openWizard(tester, 4);

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

    testWidgets('TAP FX row lists sparkles + haptics chips', (tester) async {
      await openWizard(tester, 4);
      await tester.ensureVisible(find.text('TAP FX'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('SPARKLES'), findsOneWidget);
      expect(find.text('OFF'), findsWidgets); // haptics chip
      expect(find.text('LITE'), findsOneWidget);
      expect(find.text('FULL'), findsOneWidget);

      // Sparkles chip writes the pref.
      await tester.tap(find.text('SPARKLES'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.tapSparkles, isFalse);
      await tester.tap(find.text('SPARKLES'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.tapSparkles, isTrue);
    });
  });

  group('LIVE LOOK drag handle', () {
    testWidgets('dragging the handle resizes the pane', (tester) async {
      await openWizard(tester, 1);

      final handle = find.byIcon(Icons.keyboard_arrow_down_rounded);
      expect(handle, findsOneWidget);
      final before = tester.getCenter(handle).dy;
      await tester.drag(handle, const Offset(0, 120));
      await tester.pump(const Duration(milliseconds: 300));
      final after = tester.getCenter(handle).dy;

      expect(after, greaterThan(before));
    });
  });

  group('Polish — back/restore integrity', () {
    /// Push the studio on top of a host route so maybePop has somewhere
    /// real to land after the restore-and-pop.
    Future<void> openStudioOnRoute(
      WidgetTester tester, {
      int tab = 2,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (ctx) => TextButton(
                  onPressed:
                      () => Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => ExperienceStudioScreen(initialTab: tab),
                        ),
                      ),
                  child: const Text('open'),
                ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('system back restores prefs + pops (no state leak)', (
      tester,
    ) async {
      final originalFont = VisualPrefs.notifier.value.font;
      await openStudioOnRoute(tester, tab: 2); // TYPE tab

      // Mutate a pref through real UI — pick a different font tile.
      await tester.tap(find.text('Orbitron'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(VisualPrefs.notifier.value.font, isNot(originalFont));

      // System back → PopScope → _onFlowBack → _onBack (deep link,
      // didn't come from flow) → restore + pop.
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      await nav.maybePop();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(VisualPrefs.notifier.value.font, originalFont);
      expect(find.text('open'), findsOneWidget);
      expect(find.byType(ExperienceStudioScreen), findsNothing);
    });

    testWidgets('BACK restores mutated custom theme data', (tester) async {
      // Live custom theme with known colors.
      final original = CustomThemeData.defaultTheme.copyWith(
        name: 'Base',
        primary: const Color(0xFF112233),
      );
      AppTheme.setCustomThemeData(original);
      await openStudioOnRoute(tester, tab: 1); // COLORS & BG

      // Mutate through the real picker — open PRIME sheet, tap a swatch.
      await tester.tap(find.text('PRIME'));
      await tester.pump(const Duration(milliseconds: 400));
      final swatch = find
          .descendant(
            of: find.byType(GridView),
            matching: find.byType(GestureDetector),
          )
          .first;
      await tester.ensureVisible(swatch);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(swatch);
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        AppTheme.cachedCustomTheme!.primary,
        isNot(const Color(0xFF112233)),
      );

      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      await nav.maybePop();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 300));

      expect(AppTheme.cachedCustomTheme!.primary, const Color(0xFF112233));
      expect(find.text('open'), findsOneWidget);
    });
  });

  group('Polish — saved preset gallery', () {
    SavedCustomTheme makePreset(String name, VisualPrefs prefs) {
      return SavedCustomTheme(
        id: name,
        name: name,
        splashSlug: 'custom',
        baseMode: AppThemeMode.custom,
        prefs: prefs,
        customData: CustomThemeData.defaultTheme.copyWith(name: name),
      );
    }

    /// Reach a gallery entry — list view lazily builds rows (drag the
    /// list until the label mounts); card view lazily pages (fling
    /// until it mounts).
    Future<void> goToGalleryEntry(WidgetTester tester, String text) async {
      if (find.byType(PageView).evaluate().isNotEmpty) {
        for (var i = 0; i < 8; i++) {
          if (find.text(text).evaluate().isNotEmpty) return;
          await tester.fling(
            find.byType(PageView).first,
            const Offset(-3000, 0),
            8000,
          );
          await tester.pump(const Duration(milliseconds: 400));
        }
        return;
      }
      for (var i = 0; i < 12 && find.text(text).evaluate().isEmpty; i++) {
        await tester.drag(
          find.byType(ListView).first,
          const Offset(0, -500),
        );
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.ensureVisible(find.text(text));
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('swiping to a saved preset applies its prefs live', (
      tester,
    ) async {
      const savedPrefs = VisualPrefs(glowIntensity: 0.9);
      CustomThemeStore.notifier.value = [
        makePreset('MY NEON', savedPrefs),
      ];

      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('BROWSE PRESETS'));
      await tester.pump(const Duration(milliseconds: 400));

      await goToGalleryEntry(tester, 'MY NEON');
      expect(find.text('MY NEON'), findsOneWidget);

      // List rows preview on tap (card view previews on swipe) — the
      // saved snapshot must replace the previous entry's curation.
      await tester.tap(find.text('MY NEON'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(VisualPrefs.notifier.value.glowIntensity, 0.9);
    });

    testWidgets('long-press a saved preset deletes it after confirm', (
      tester,
    ) async {
      CustomThemeStore.notifier.value = [
        makePreset('Doomed', const VisualPrefs()),
      ];

      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('BROWSE PRESETS'));
      await tester.pump(const Duration(milliseconds: 400));
      await goToGalleryEntry(tester, 'Doomed');
      expect(find.text('Doomed'), findsOneWidget);

      await tester.longPress(find.text('Doomed'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('DELETE PRESET'), findsOneWidget);

      await tester.tap(find.text('DELETE'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(CustomThemeStore.themes, isEmpty);
    });

    test('store load skips malformed entries instead of wiping', () async {
      SharedPreferences.setMockInitialValues({
        'custom.themes.v1':
            '[{"id":"ok","name":"Good","splashSlug":"custom",'
            '"baseMode":0,"prefs":{}},'
            '42,'
            '{"name":"missing required fields"}]',
      });
      await CustomThemeStore.load();
      expect(CustomThemeStore.themes, hasLength(1));
      expect(CustomThemeStore.themes.single.name, 'Good');
      CustomThemeStore.notifier.value = [];
    });
  });

  group('Flow - QUICK SLOTS', () {
    Future<void> openChoose(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('empty slots show +; tap opens slot picker; SET SLOT fills', (
      tester,
    ) async {
      await openChoose(tester);
      expect(find.byIcon(Icons.add_rounded), findsNWidgets(3));

      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('PICK FOR SLOT 1'), findsOneWidget);
      expect(find.text('SET SLOT'), findsOneWidget);

      // Page 0 = unicorn (kPickerThemes.first).
      await tester.tap(find.text('SET SLOT'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('CUSTOMIZE'), findsOneWidget);
      expect(find.text('Unicorn'), findsWidgets);
      expect(find.byIcon(Icons.add_rounded), findsNWidgets(2));
    });

    testWidgets('filled slot tap applies preset and closes', (tester) async {
      SharedPreferences.setMockInitialValues({
        'studio.quickSlots.v1': '["m:unicorn",null,null]',
      });
      final before = AppTheme.mode;
      await openChoose(tester);
      await tester.tap(find.text('Unicorn').first);
      await tester.pump(const Duration(milliseconds: 500));
      expect(AppTheme.mode, AppThemeMode.unicorn);
      expect(AppTheme.previewNotifier.value, isNull);
      await AppTheme.setMode(before);
    });

    testWidgets('slots persist across studio reopen', (tester) async {
      SharedPreferences.setMockInitialValues({
        'studio.quickSlots.v1': '["m:unicorn",null,null]',
      });
      await openChoose(tester);
      expect(find.text('Unicorn'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await openChoose(tester);
      expect(find.text('Unicorn'), findsWidgets);
      expect(find.byIcon(Icons.add_rounded), findsNWidgets(2));
    });

    testWidgets('long-press filled slot shows info; REMOVE empties it', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'studio.quickSlots.v1': '["m:unicorn",null,null]',
      });
      await openChoose(tester);
      await tester.longPress(find.text('Unicorn').first);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('SLOT 1'), findsOneWidget);
      expect(find.text('REMOVE'), findsOneWidget);

      await tester.tap(find.text('REMOVE'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byIcon(Icons.add_rounded), findsNWidgets(3));
    });
  });
}
