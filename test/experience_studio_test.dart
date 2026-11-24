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

  /// Drive the full NEW PRESET flow to the wizard dashboard:
  /// choose → name → source → scratch. Leaves the screen on the
  /// dashboard landing (menubar + hero PREVIEW + theme panel);
  /// tap EDIT OPTIONS to reach the tabbed editor.
  Future<void> openWizardViaNewPreset(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: ExperienceStudioScreen()));
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
        ambientKindIndex: 3,
        cinematicBars: true,
        tapRipple: false,
      );
      final r = VisualPrefs.fromJson(p.toJson());
      expect(r.vignetteIntensity, 0.7);
      expect(r.grainIntensity, 0.4);
      expect(r.glowStyleIndex, 2);
      expect(r.ambientKindIndex, 3);
      expect(r.cinematicBars, isTrue);
      expect(r.tapRipple, isFalse);
    });

    test('atmosphere fields default off + survive old json', () {
      const p = VisualPrefs();
      expect(p.ambientKindIndex, 0);
      expect(p.cinematicBars, isFalse);
      expect(p.tapRipple, isTrue);
      final r = VisualPrefs.fromJson(const {});
      expect(r.ambientKindIndex, 0);
      expect(r.cinematicBars, isFalse);
      expect(r.tapRipple, isTrue);
    });

    test('ambientKindIndex clamps to enum range in fromJson', () {
      final r = VisualPrefs.fromJson(const {'ambientKindIndex': 99});
      expect(r.ambientKindIndex, AmbientKind.values.length - 1);
    });

    test('old json without new fields gets defaults', () {
      final r = VisualPrefs.fromJson(const {});
      expect(r.vignetteIntensity, 1.0);
      expect(r.grainIntensity, 0.0);
    });

    test('fromJson clamps out-of-range numerics to setter ranges', () {
      // Preset JSON is importable data — an absurd value must not
      // assert-crash the studio sliders that consume it.
      final r = VisualPrefs.fromJson(const {
        'particleCount': 9999,
        'fontWeightBias': 99999,
        'fontLetterSpacing': 50,
        'particleOpacity': 4.0,
        'particleSizeScale': 0.01,
        'glowStyleIndex': 500,
        'particleTypeIndex': 500,
        'particleSchemaIndex': 500,
        'particleItemIcon': 500,
      });
      expect(r.particleCount, 200);
      expect(r.fontWeightBias, 800);
      expect(r.fontLetterSpacing, 2);
      expect(r.particleOpacity, 1.0);
      expect(r.particleSizeScale, 0.3);
      expect(r.glowStyleIndex, GlowStyle.values.length - 1);
      expect(r.particleTypeIndex, ParticleType.values.length - 1);
      expect(r.particleSchemaIndex, kGlobalParticlePalettes.length - 1);
      expect(r.particleItemIcon, kItemIconParticles.length - 1);
    });

    test('fontLetterSpacing survives preset json round-trip', () {
      const p = VisualPrefs(fontLetterSpacing: -1);
      expect(VisualPrefs.fromJson(p.toJson()).fontLetterSpacing, -1);
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

    testWidgets('gallery is list-only — no card swiper or view toggle', (
      tester,
    ) async {
      await openGallery(tester);
      // kPickerThemes.first = unicorn — list row shows its label.
      expect(find.text('Unicorn'), findsWidgets);
      expect(find.text('OFFICIAL'), findsOneWidget);
      // The fullscreen swipe gallery was removed — no PageView, no
      // LIST/CARDS toggle icons.
      expect(find.byType(PageView), findsNothing);
      expect(find.byIcon(Icons.grid_view_rounded), findsNothing);
      expect(find.byIcon(Icons.view_list_rounded), findsNothing);
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
    testWidgets('name → source → scratch lands on dashboard', (tester) async {
      await openWizardViaNewPreset(tester);

      // Dashboard landing — menubar title, hero PREVIEW, theme panel,
      // preset actions. The tab strip lives one tap deeper.
      expect(find.text('PRESET: Test Look'), findsOneWidget);
      expect(find.text('PREVIEW'), findsWidgets);
      expect(find.text('EDIT OPTIONS'), findsOneWidget);
      expect(find.text('NEW PRESET'), findsOneWidget);
      expect(find.text('DETAILS'), findsNothing);
      expect(find.text('BACK'), findsOneWidget);
      expect(find.text('APPLY'), findsOneWidget);

      // EDIT OPTIONS opens the tabbed editor.
      await tester.tap(find.text('EDIT OPTIONS'));
      await tester.pump(const Duration(milliseconds: 300));
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
    });

    testWidgets('DETAILS summary shows picks + preview opens mock', (
      tester,
    ) async {
      await openWizardViaNewPreset(tester);
      await tester.tap(find.text('EDIT OPTIONS'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PARTICLES'), findsWidgets);
      await tester.ensureVisible(find.text('FULLSCREEN PREVIEW'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.text('FULLSCREEN PREVIEW'));
      // Wait for preview to open — don't wait for full data load
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));

      // Mock preview opens — shows LIVE PREVIEW header
      expect(find.text('LIVE PREVIEW'), findsOneWidget);

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

    testWidgets('COPY EXISTING opens gallery in select mode', (tester) async {
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

      // Wizard dashboard opens with the new name + custom preview.
      expect(find.text('PRESET: Copy Cat'), findsOneWidget);
      expect(find.text('EDIT OPTIONS'), findsOneWidget);
      expect(
        VisualPrefs.notifier.value.particlePreset,
        ParticlePreset.unicornSparkles,
      );

      // EDIT OPTIONS → SAVE tab persists the copied look.
      await tester.tap(find.text('EDIT OPTIONS'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('DETAILS'), findsWidgets);
      await tester.tap(find.text('SAVE'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('SAVE & APPLY'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(CustomThemeStore.themes, hasLength(1));
      expect(CustomThemeStore.themes.single.name, 'Copy Cat');
      expect(AppTheme.mode, AppThemeMode.custom);

      await AppTheme.setMode(before);
    });

    testWidgets('COPY EXISTING saved preset keeps the typed name (U-059)', (
      tester,
    ) async {
      CustomThemeStore.notifier.value = [
        SavedCustomTheme(
          id: 'src1',
          name: 'Base Look',
          splashSlug: 'custom',
          baseMode: AppThemeMode.custom,
          prefs: const VisualPrefs(),
          customData: CustomThemeData.defaultTheme.copyWith(name: 'Base Look'),
        ),
      ];
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('NEW PRESET'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField), 'My Copy');
      await tester.tap(find.text('NEXT'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('COPY EXISTING'));
      await tester.pump(const Duration(milliseconds: 400));

      // Select the saved preset row, then USE AS BASE.
      await tester.tap(find.text('Base Look'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('USE AS BASE'));
      await tester.pump(const Duration(milliseconds: 500));

      // The typed name wins — this is a NEW preset, not an edit of
      // the source (regression: source id/name used to be claimed,
      // discarding 'My Copy' and arming an overwrite of 'Base Look').
      expect(find.text('PRESET: My Copy'), findsOneWidget);
      expect(find.text('EDITING: Base Look'), findsNothing);

      // One-tap save under the staged name — source stays untouched.
      await tester.tap(find.text('SAVE "My Copy"'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(CustomThemeStore.themes, hasLength(2));
      expect(
        CustomThemeStore.themes.map((t) => t.name),
        containsAll(<String>['Base Look', 'My Copy']),
      );
    });

    testWidgets('SAVE tab persists preset + applies + closes', (tester) async {
      final before = AppTheme.mode;
      await openWizardViaNewPreset(tester);
      await tester.tap(find.text('EDIT OPTIONS'));
      await tester.pump(const Duration(milliseconds: 300));
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
      expect(VisualPrefs.notifier.value.particleSpeed, ParticleSpeed.veryFast);
      // drag the SIZE slider (inside the row labelled SIZE) -> pref moves
      final sizeRow =
          find
              .ancestor(of: find.text('SIZE'), matching: find.byType(Row))
              .first;
      await tester.drag(
        find.descendant(of: sizeRow, matching: find.byType(Slider)),
        const Offset(80, 0),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(VisualPrefs.notifier.value.particleSizeScale, isNot(1.0));
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

    testWidgets('TYPE shows curated font list + bottom controls', (tester) async {
      await openWizard(tester, 2);
      final scrollable = find.byType(Scrollable).first;
      // Curated collection — signature, fat display, accent, readable.
      // Rows below the fold are lazily built, so scroll to reveal them.
      await tester.scrollUntilVisible(
        find.text('Bungee'),
        120,
        scrollable: scrollable,
      );
      expect(find.text('Enter the Gungeon'), findsWidgets);
      expect(find.text('Megrim'), findsOneWidget);
      expect(find.text('Bungee'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Fjalla One'),
        120,
        scrollable: scrollable,
      );
      expect(find.text('Germania One'), findsOneWidget);
      expect(find.text('Fjalla One'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('WEIGHT BIAS'),
        120,
        scrollable: scrollable,
      );
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
      for (final tab in ['PINK & PURPLE', 'BLUE & CYAN', 'GREEN & MINTY']) {
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
      expect(VisualPrefs.notifier.value.particleGlowEffect, GlowEffect.prism);
      // none = AUTO semantics — overlay maps it to null override.
      await VisualPrefs.setParticleGlowEffect(GlowEffect.none);
      expect(VisualPrefs.notifier.value.particleGlowEffect, GlowEffect.none);
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
      // ensureVisible animates (~100ms); let the scroll settle or the
      // tap lands mid-flight below the viewport.
      await tester.pump(const Duration(milliseconds: 200));
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
    Future<void> openStudioOnRoute(WidgetTester tester, {int tab = 2}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (ctx) => TextButton(
                  onPressed:
                      () => Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder:
                              (_) => ExperienceStudioScreen(initialTab: tab),
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
      await tester.tap(find.text('Bungee'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(VisualPrefs.notifier.value.font, isNot(originalFont));

      // System back → PopScope → _onFlowBack → editor steps back to
      // the dashboard first (stage back, no pop), second back runs
      // _onBack (deep link, didn't come from flow) → restore + pop.
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      await nav.maybePop();
      await tester.pump(const Duration(milliseconds: 400));
      // Bounded pumps — the dashboard hero pulse is an infinite
      // animation, so pumpAndSettle would never settle.
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(ExperienceStudioScreen), findsOneWidget);

      await nav.maybePop();
      // _onBack awaits persistence then pops post-frame — give the
      // async chain several frames (bounded: hero pulse never settles).
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

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
      final swatch =
          find
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
      // First back: editor → dashboard. Second back: dashboard →
      // restore + pop. Bounded pumps — hero pulse never settles.
      await nav.maybePop();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 600));
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

    /// Reach a gallery entry — the list lazily builds rows (drag the
    /// list until the label mounts).
    Future<void> goToGalleryEntry(WidgetTester tester, String text) async {
      for (var i = 0; i < 12 && find.text(text).evaluate().isEmpty; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 250));
      }
      await tester.ensureVisible(find.text(text));
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('swiping to a saved preset applies its prefs live', (
      tester,
    ) async {
      const savedPrefs = VisualPrefs(glowIntensity: 0.9);
      CustomThemeStore.notifier.value = [makePreset('MY NEON', savedPrefs)];

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

  group('Dashboard polish', () {
    testWidgets('SAVE "<staged name>" stores a preset without closing', (
      tester,
    ) async {
      await openWizardViaNewPreset(tester); // names the preset 'Test Look'

      // The staged name rides on the card — one tap saves directly,
      // no second name prompt (U-059).
      await tester.tap(find.text('SAVE "Test Look"'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(CustomThemeStore.themes, hasLength(1));
      expect(CustomThemeStore.themes.single.name, 'Test Look');
      // Still on the dashboard — save-as-new doesn't apply or close,
      // and the consumed name reverts the card to SAVE AS NEW.
      expect(find.text('EDIT OPTIONS'), findsOneWidget);
      expect(find.text('SAVE AS NEW'), findsOneWidget);
    });

    testWidgets('menubar PRESETS previews the pick on the dashboard', (
      tester,
    ) async {
      final before = AppTheme.mode;
      await openWizardViaNewPreset(tester);

      await tester.tap(find.text('PRESETS'));
      await tester.pump(const Duration(milliseconds: 400));
      // Preview-mode gallery — the pick bar offers PREVIEW, not
      // PICK PRESET (no apply+close from the dashboard).
      expect(find.text('PICK PRESET'), findsNothing);
      expect(find.text('PREVIEW'), findsWidgets);

      await tester.tap(find.text('PREVIEW').last);
      await tester.pump(const Duration(milliseconds: 400));

      // Back on the dashboard with the pick staged — UNSAVED badge,
      // applied mode untouched until APPLY.
      expect(find.text('EDIT OPTIONS'), findsOneWidget);
      expect(find.text('UNSAVED'), findsOneWidget);
      expect(AppTheme.mode, before);
    });

    testWidgets('EDIT PRESET shows on dashboard after gallery edit', (
      tester,
    ) async {
      CustomThemeStore.notifier.value = [
        SavedCustomTheme(
          id: 'match1',
          name: 'Test Look',
          splashSlug: 'custom',
          baseMode: AppThemeMode.custom,
          prefs: const VisualPrefs(),
          customData: CustomThemeData.defaultTheme.copyWith(name: 'Test Look'),
        ),
      ];

      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('BROWSE PRESETS'));
      await tester.pump(const Duration(milliseconds: 400));

      // Saved row's edit pencil → wizard dashboard in edit mode.
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('EDITING: Test Look'), findsOneWidget);
      expect(find.text('EDIT PRESET'), findsOneWidget);
      expect(find.text('update "Test Look" in your gallery'), findsOneWidget);
    });
  });

  group('Active preset editing', () {
    SavedCustomTheme activePreset() => SavedCustomTheme(
      id: 'active1',
      name: 'Test Look',
      splashSlug: 'custom',
      baseMode: AppThemeMode.custom,
      prefs: const VisualPrefs(),
      customData: CustomThemeData.defaultTheme.copyWith(name: 'Test Look'),
    );

    /// Fresh-open on the dashboard the way a returning user lands:
    /// the saved preset is already the live custom theme app-wide,
    /// then deep-link into the editor and step back to the dashboard.
    /// No gallery pick this session — _presetName/_editingPresetId
    /// start empty, so detection must fall back to the live theme.
    Future<void> openDashboardOnActivePreset(WidgetTester tester) async {
      CustomThemeStore.notifier.value = [activePreset()];
      AppTheme.setCustomThemeData(
        CustomThemeData.defaultTheme.copyWith(name: 'Test Look'),
      );
      await AppTheme.setMode(AppThemeMode.custom);
      await tester.pumpWidget(
        const MaterialApp(home: ExperienceStudioScreen(initialTab: 1)),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).first);
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('active saved preset shows EDIT PRESET on fresh open', (
      tester,
    ) async {
      final before = AppTheme.mode;
      addTearDown(() => AppTheme.setMode(before));

      await openDashboardOnActivePreset(tester);

      expect(find.text('EDIT PRESET'), findsOneWidget);
      expect(find.text('update "Test Look" in your gallery'), findsOneWidget);
      expect(find.text('SAVED PRESET'), findsWidgets);
      expect(find.text('TEST LOOK'), findsWidgets);
    });

    testWidgets('EDIT OPTIONS → SAVE updates the active preset in place', (
      tester,
    ) async {
      final before = AppTheme.mode;
      addTearDown(() => AppTheme.setMode(before));

      await openDashboardOnActivePreset(tester);
      await tester.tap(find.text('EDIT OPTIONS'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('SAVE'));
      await tester.pump(const Duration(milliseconds: 400));

      // The staged look IS the saved preset — SAVE must offer an
      // update, not a new preset.
      expect(find.text('UPDATE PRESET'), findsOneWidget);
      expect(find.text('"Test Look" will be updated in your gallery'),
          findsOneWidget);

      await tester.tap(find.text('UPDATE & APPLY'));
      await tester.pump(const Duration(milliseconds: 500));

      // Overwritten in place — no duplicate, same id.
      expect(CustomThemeStore.themes, hasLength(1));
      expect(CustomThemeStore.themes.single.id, 'active1');
      expect(CustomThemeStore.themes.single.name, 'Test Look');
    });

    testWidgets('EDIT PRESET pencil still enters edit mode', (tester) async {
      final before = AppTheme.mode;
      addTearDown(() => AppTheme.setMode(before));

      await openDashboardOnActivePreset(tester);
      await tester.tap(find.text('EDIT PRESET'));
      // Infinite hero-pulse animation — settle never returns; fixed
      // pumps cover the stage transition instead. Deep link left
      // _hubTab on COLORS & BG — DETAILS carries the EDITING header.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('DETAILS'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('EDITING: Test Look'), findsOneWidget);
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

  group('U-035/U-036 picker a11y', () {
    testWidgets('glow quick dots expose labels and taller hit areas', (
      tester,
    ) async {
      await openWizard(tester, 4); // AMBIANCE tab
      await tester.pump(const Duration(milliseconds: 300));

      // U-036: bare color dots now carry a tooltip + semantics label.
      expect(find.byTooltip('Glow color 1'), findsOneWidget);
      expect(find.byTooltip('Glow color 12'), findsOneWidget);

      // U-035: hit area grew from 26px to a 30x40 box (visual dot stays 26).
      final gesture = find.descendant(
        of: find.byTooltip('Glow color 1'),
        matching: find.byType(GestureDetector),
      );
      expect(gesture, findsOneWidget);
      final size = tester.getSize(gesture);
      expect(size.height, greaterThanOrEqualTo(36));
      expect(size.width, greaterThanOrEqualTo(30));
    });

    testWidgets('atmosphere meter dots expose on/off semantics', (
      tester,
    ) async {
      await openWizard(tester, 4); // AMBIANCE tab
      await tester.pump(const Duration(milliseconds: 300));

      // U-036: the 4-dot load meter labels each layer active/inactive.
      final semantics = tester.widgetList<Semantics>(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label ?? '').startsWith('Backdrop layer'),
        ),
      );
      expect(semantics.length, greaterThanOrEqualTo(4));
    });
  });
}
