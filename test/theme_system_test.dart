import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/utils/asset_paths.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit tests for the custom theme system — serialization round-trips,
/// store operations, VisualPrefs persistence, and CustomThemeData.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Reset AppTheme state
    AppTheme.previewNotifier.value = null;
    AppTheme.setCustomThemeData(CustomThemeData.defaultTheme);
    CustomThemeStore.notifier.value = [];
    VisualPrefs.notifier.value = const VisualPrefs();
  });

  group('CustomThemeData', () {
    test('toJson/fromJson round-trip preserves all fields', () {
      final original = CustomThemeData(
        name: 'Test Palette',
        scaffold: const Color(0xFF1A2B3C),
        card: const Color(0xFF4D5E6F),
        primary: const Color(0xFFFF6B9D),
        secondary: const Color(0xFF00E5FF),
        headlineStat: const Color(0xFFFFD54F),
        bulletColor: const Color(0xFFE8A7F0),
        auraStyle: AvatarAuraStyle.pastelPulse,
        font: AppFont.lilitaOne,
      );
      final json = original.toJson();
      final restored = CustomThemeData.fromJson(json);

      expect(restored.name, 'Test Palette');
      expect(restored.scaffold, const Color(0xFF1A2B3C));
      expect(restored.card, const Color(0xFF4D5E6F));
      expect(restored.primary, const Color(0xFFFF6B9D));
      expect(restored.secondary, const Color(0xFF00E5FF));
      expect(restored.headlineStat, const Color(0xFFFFD54F));
      expect(restored.bulletColor, const Color(0xFFE8A7F0));
      expect(restored.auraStyle, AvatarAuraStyle.pastelPulse);
      expect(restored.font, AppFont.lilitaOne);
    });

    test('fromJson with missing fields uses defaults', () {
      final restored = CustomThemeData.fromJson({});

      expect(restored.name, 'Custom');
      expect(restored.auraStyle, AvatarAuraStyle.none);
      expect(restored.font, AppFont.gungeon);
    });

    test('copyWith overrides only specified fields', () {
      final original = CustomThemeData.defaultTheme;
      final updated = original.copyWith(primary: Colors.red, name: 'Red Theme');

      expect(updated.name, 'Red Theme');
      expect(updated.primary, Colors.red);
      // Unchanged fields preserved
      expect(updated.scaffold, original.scaffold);
      expect(updated.card, original.card);
      expect(updated.secondary, original.secondary);
      expect(updated.font, original.font);
    });

    test('random() generates valid data with all fields non-null', () {
      final random = CustomThemeData.random();

      expect(random.name, isNotEmpty);
      expect(random.scaffold, isNotNull);
      expect(random.card, isNotNull);
      expect(random.primary, isNotNull);
      expect(random.secondary, isNotNull);
      expect(random.headlineStat, isNotNull);
      expect(random.bulletColor, isNotNull);
    });

    test('random() generates different colors on successive calls', () {
      // Generate several random themes — at least one field must differ
      // between any two successive calls. Comparing only a single field
      // is flaky because Random can occasionally produce the same value.
      final r1 = CustomThemeData.random();
      final r2 = CustomThemeData.random();

      final allFieldsMatch =
          r1.primary == r2.primary &&
          r1.secondary == r2.secondary &&
          r1.scaffold == r2.scaffold &&
          r1.card == r2.card &&
          r1.headlineStat == r2.headlineStat &&
          r1.bulletColor == r2.bulletColor;

      expect(
        allFieldsMatch,
        isFalse,
        reason: 'Two random themes should not match on every field',
      );
    });
  });

  group('SavedCustomTheme', () {
    test('toJson/fromJson round-trip without customData', () {
      final original = SavedCustomTheme(
        id: '12345',
        name: 'My Theme',
        splashSlug: 'unicorn',
        baseMode: AppThemeMode.unicorn,
        prefs: const VisualPrefs(),
      );
      final json = original.toJson();
      final restored = SavedCustomTheme.fromJson(json);

      expect(restored.id, '12345');
      expect(restored.name, 'My Theme');
      expect(restored.splashSlug, 'unicorn');
      expect(restored.baseMode, AppThemeMode.unicorn);
      expect(restored.customData, isNull);
    });

    test('toJson/fromJson round-trip with customData', () {
      final customData = CustomThemeData(
        name: 'Custom Palette',
        scaffold: const Color(0xFF111111),
        card: const Color(0xFF222222),
        primary: const Color(0xFF333333),
        secondary: const Color(0xFF444444),
        headlineStat: const Color(0xFF555555),
        bulletColor: const Color(0xFF666666),
        auraStyle: AvatarAuraStyle.voidPulse,
        font: AppFont.fjallaOne,
      );
      final original = SavedCustomTheme(
        id: '67890',
        name: 'Custom Saved',
        splashSlug: 'forge_master',
        baseMode: AppThemeMode.custom,
        prefs: const VisualPrefs(glowIntensity: 0.5),
        customData: customData,
      );
      final json = original.toJson();
      final restored = SavedCustomTheme.fromJson(json);

      expect(restored.id, '67890');
      expect(restored.name, 'Custom Saved');
      expect(restored.splashSlug, 'forge_master');
      expect(restored.baseMode, AppThemeMode.custom);
      expect(restored.prefs.glowIntensity, 0.5);
      expect(restored.customData, isNotNull);
      expect(restored.customData!.name, 'Custom Palette');
      expect(restored.customData!.scaffold, const Color(0xFF111111));
      expect(restored.customData!.primary, const Color(0xFF333333));
      expect(restored.customData!.auraStyle, AvatarAuraStyle.voidPulse);
      expect(restored.customData!.font, AppFont.fjallaOne);
    });

    test('fromJson handles legacy entries without customData', () {
      final legacyJson = {
        'id': 'legacy1',
        'name': 'Old Theme',
        'splashSlug': 'the_bullet',
        'baseMode': AppThemeMode.theBullet.index,
        'prefs': const VisualPrefs().toJson(),
      };
      final restored = SavedCustomTheme.fromJson(legacyJson);

      expect(restored.id, 'legacy1');
      expect(restored.name, 'Old Theme');
      expect(restored.customData, isNull);
    });
  });

  group('CustomThemeStore', () {
    test('save() adds theme to notifier', () async {
      final theme = SavedCustomTheme(
        id: 'test1',
        name: 'Test',
        splashSlug: 'unicorn',
        baseMode: AppThemeMode.unicorn,
        prefs: const VisualPrefs(),
      );
      await CustomThemeStore.save(theme);

      expect(CustomThemeStore.themes.length, 1);
      expect(CustomThemeStore.themes.first.name, 'Test');
    });

    test('save() appends without replacing existing', () async {
      final t1 = SavedCustomTheme(
        id: '1',
        name: 'First',
        splashSlug: 'unicorn',
        baseMode: AppThemeMode.unicorn,
        prefs: const VisualPrefs(),
      );
      final t2 = SavedCustomTheme(
        id: '2',
        name: 'Second',
        splashSlug: 'forge_master',
        baseMode: AppThemeMode.forgeMaster,
        prefs: const VisualPrefs(),
      );
      await CustomThemeStore.save(t1);
      await CustomThemeStore.save(t2);

      expect(CustomThemeStore.themes.length, 2);
      expect(CustomThemeStore.themes[0].name, 'First');
      expect(CustomThemeStore.themes[1].name, 'Second');
    });

    test('delete() removes the specified theme', () async {
      final t1 = SavedCustomTheme(
        id: 'keep',
        name: 'Keep',
        splashSlug: 'unicorn',
        baseMode: AppThemeMode.unicorn,
        prefs: const VisualPrefs(),
      );
      final t2 = SavedCustomTheme(
        id: 'delete',
        name: 'Delete',
        splashSlug: 'unicorn',
        baseMode: AppThemeMode.unicorn,
        prefs: const VisualPrefs(),
      );
      await CustomThemeStore.save(t1);
      await CustomThemeStore.save(t2);
      expect(CustomThemeStore.themes.length, 2);

      await CustomThemeStore.delete('delete');

      expect(CustomThemeStore.themes.length, 1);
      expect(CustomThemeStore.themes.first.id, 'keep');
    });

    test('delete() with unknown id is a no-op', () async {
      final t1 = SavedCustomTheme(
        id: '1',
        name: 'Keep',
        splashSlug: 'unicorn',
        baseMode: AppThemeMode.unicorn,
        prefs: const VisualPrefs(),
      );
      await CustomThemeStore.save(t1);

      await CustomThemeStore.delete('nonexistent');

      expect(CustomThemeStore.themes.length, 1);
    });

    test('load() restores themes from SharedPreferences', () async {
      // Manually populate SharedPreferences with a saved theme
      final prefs = await SharedPreferences.getInstance();
      final theme = SavedCustomTheme(
        id: 'loaded1',
        name: 'Loaded Theme',
        splashSlug: 'the_bullet',
        baseMode: AppThemeMode.theBullet,
        prefs: const VisualPrefs(glowIntensity: 0.8),
        customData: CustomThemeData(
          name: 'Loaded Theme',
          scaffold: const Color(0xFF000000),
          card: const Color(0xFF111111),
          primary: const Color(0xFF222222),
          secondary: const Color(0xFF333333),
          headlineStat: const Color(0xFF444444),
          bulletColor: const Color(0xFF555555),
        ),
      );
      await prefs.setString(
        'custom.themes.v1',
        '[${theme.toJson().toString()}]',
      );

      // This won't work because the JSON encoding needs proper encoding
      // Use the store's own save method instead
      await CustomThemeStore.save(theme);
      // Simulate app restart by clearing notifier
      CustomThemeStore.notifier.value = [];
      expect(CustomThemeStore.themes, isEmpty);

      await CustomThemeStore.load();

      expect(CustomThemeStore.themes.length, 1);
      expect(CustomThemeStore.themes.first.name, 'Loaded Theme');
      expect(CustomThemeStore.themes.first.customData, isNotNull);
      expect(
        CustomThemeStore.themes.first.customData!.primary,
        const Color(0xFF222222),
      );
    });

    test('load() with empty storage is a no-op', () async {
      await CustomThemeStore.load();
      expect(CustomThemeStore.themes, isEmpty);
    });
  });

  group('VisualPrefs.replaceAndPersist', () {
    test('replaces the in-memory value', () async {
      const newPrefs = VisualPrefs(
        glowIntensity: 0.9,
        particlesEnabled: true,
        fontSize: 18.0,
      );
      await VisualPrefs.replaceAndPersist(newPrefs);

      expect(VisualPrefs.notifier.value.glowIntensity, 0.9);
      expect(VisualPrefs.notifier.value.particlesEnabled, true);
      expect(VisualPrefs.notifier.value.fontSize, 18.0);
    });

    test('persists to SharedPreferences', () async {
      const newPrefs = VisualPrefs(glowIntensity: 0.7, particlesEnabled: true);
      await VisualPrefs.replaceAndPersist(newPrefs);

      // Verify it was persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('vp.glow_v1'), 0.7);
      expect(prefs.getBool('vp.particles_v2'), true);
    });
  });

  group('AppTheme custom theme data', () {
    test('saveCustomThemeData updates cache and persists', () async {
      final data = CustomThemeData(
        name: 'Persisted',
        scaffold: const Color(0xFF0A0B0C),
        card: const Color(0xFF1A1B1C),
        primary: const Color(0xFF2A2B2C),
        secondary: const Color(0xFF3A3B3C),
        headlineStat: const Color(0xFF4A4B4C),
        bulletColor: const Color(0xFF5A5B5C),
      );
      await AppTheme.saveCustomThemeData(data);

      expect(AppTheme.cachedCustomTheme, isNotNull);
      expect(AppTheme.cachedCustomTheme!.name, 'Persisted');
      expect(AppTheme.cachedCustomTheme!.scaffold, const Color(0xFF0A0B0C));

      // Verify persisted to disk
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('custom.theme.data'), true);
    });

    test('setCustomThemeData updates cache without persisting', () {
      final data = CustomThemeData(
        name: 'Cached Only',
        scaffold: const Color(0xFF000000),
        card: const Color(0xFF111111),
        primary: const Color(0xFF222222),
        secondary: const Color(0xFF333333),
        headlineStat: const Color(0xFF444444),
        bulletColor: const Color(0xFF555555),
      );
      AppTheme.setCustomThemeData(data);

      expect(AppTheme.cachedCustomTheme, isNotNull);
      expect(AppTheme.cachedCustomTheme!.name, 'Cached Only');
    });

    test('flairFor(custom) uses cached custom theme data', () {
      final data = CustomThemeData(
        name: 'Flair Test',
        scaffold: const Color(0xFF101010),
        card: const Color(0xFF202020),
        primary: const Color(0xFF303030),
        secondary: const Color(0xFF404040),
        headlineStat: const Color(0xFF505050),
        bulletColor: const Color(0xFF606060),
      );
      AppTheme.setCustomThemeData(data);

      final flair = AppTheme.flairFor(AppThemeMode.custom);

      expect(flair.scaffold, const Color(0xFF101010));
      expect(flair.card, const Color(0xFF202020));
      expect(flair.primary, const Color(0xFF303030));
      expect(flair.secondary, const Color(0xFF404040));
    });

    test('flairFor(custom) falls back to default when no cache', () {
      // Clear the cache
      AppTheme.setCustomThemeData(CustomThemeData.defaultTheme);

      final flair = AppTheme.flairFor(AppThemeMode.custom);

      // Should use default theme colors
      expect(flair.scaffold, CustomThemeData.defaultTheme.scaffold);
      expect(flair.primary, CustomThemeData.defaultTheme.primary);
    });
  });

  group('Theme list integrity', () {
    test('kPickerThemes is the six presets', () {
      // 3 core + 3 added presets (cool/warm/dark variety, all curated).
      expect(
        kPickerThemes,
        equals([
          AppThemeMode.unicorn,
          AppThemeMode.moltenSteel,
          AppThemeMode.paperInk,
          AppThemeMode.moonlitChamber,
          AppThemeMode.dragunfire,
          AppThemeMode.lichsDomain,
        ]),
      );
    });

    test('kVisibleThemes includes custom', () {
      expect(kVisibleThemes, contains(AppThemeMode.custom));
    });

    test('kVisibleThemes defaults to paperInk', () {
      // paperInk is the visible default — removed themes migrate here.
      expect(kVisibleThemes.first, AppThemeMode.paperInk);
    });

    test('kPickerThemes does not include custom (has its own tile)', () {
      expect(kPickerThemes, isNot(contains(AppThemeMode.custom)));
    });

    test('every picker theme has a non-empty label', () {
      for (final mode in kPickerThemes) {
        expect(mode.label, isNotEmpty);
      }
    });
  });

  group('Panel chrome overrides', () {
    tearDown(() => VisualPrefs.notifier.value = const VisualPrefs());

    test('defaults are theme-following sentinels', () {
      const p = VisualPrefs();
      expect(p.panelColor, 0);
      expect(p.panelOpacity, 1.0);
      expect(p.panelBorderColor, 0);
      expect(p.panelBorderWidth, 0);
      expect(p.panelRadius, 0);
    });

    test('toJson/fromJson round-trip preserves panel fields', () {
      const p = VisualPrefs(
        panelColor: 0xFF112233,
        panelOpacity: 0.5,
        panelBorderColor: -1,
        panelBorderWidth: 2.0,
        panelRadius: 16.0,
      );
      final r = VisualPrefs.fromJson(p.toJson());
      expect(r.panelColor, 0xFF112233);
      expect(r.panelOpacity, 0.5);
      expect(r.panelBorderColor, -1);
      expect(r.panelBorderWidth, 2.0);
      expect(r.panelRadius, 16.0);
    });

    test('flairFor applies color/opacity/border/radius overrides', () {
      VisualPrefs.notifier.value = const VisualPrefs(
        panelColor: 0xFF102030,
        panelOpacity: 0.5,
        panelBorderColor: 0xFF445566,
        panelBorderWidth: 2.5,
        panelRadius: 20.0,
      );
      final f = AppTheme.flairFor(AppThemeMode.paperInk);
      expect(f.card.a, closeTo(0.5, 0.02));
      expect(f.card.r, closeTo(0x10 / 255, 0.02));
      expect(f.card.g, closeTo(0x20 / 255, 0.02));
      expect(f.cardRadius, 20.0);
      expect(f.cardBorderColor!.toARGB32(), 0xFF445566);
      expect(f.cardBorderWidth, 2.5);
    });

    test('flairFor border -1 hides the border', () {
      VisualPrefs.notifier.value = const VisualPrefs(panelBorderColor: -1);
      final f = AppTheme.flairFor(AppThemeMode.paperInk);
      expect(f.cardBorderColor, Colors.transparent);
    });

    test('flairFor returns theme flair untouched when sentinels', () {
      final f = AppTheme.flairFor(AppThemeMode.paperInk);
      expect(f.card, AppThemeMode.paperInk.flair.card);
      expect(f.cardRadius, AppThemeMode.paperInk.flair.cardRadius);
    });
  });

  group('BG modes + particle off-flag', () {
    tearDown(() => VisualPrefs.notifier.value = const VisualPrefs());

    test(
      'CustomThemeData bgMode round-trips; legacy defaults to wallpaper',
      () {
        final d = CustomThemeData.defaultTheme.copyWith(bgMode: 2);
        final j = d.toJson();
        expect(j['bgMode'], 2);
        final r = CustomThemeData.fromJson(j);
        expect(r.bgMode, CustomThemeData.bgGradient);
        // Missing key = legacy wallpaper-or-solid behavior.
        final legacy = CustomThemeData.fromJson(
          Map<String, dynamic>.from(j)..remove('bgMode'),
        );
        expect(legacy.bgMode, CustomThemeData.bgWallpaper);
      },
    );

    test('VisualPrefs particlesUserOff round-trips', () {
      const p = VisualPrefs(particlesUserOff: true);
      expect(VisualPrefs.fromJson(p.toJson()).particlesUserOff, isTrue);
      expect(const VisualPrefs().particlesUserOff, isFalse);
    });
  });

  group('Font curation', () {
    test('curated set keeps signature + new faces, drops the catalog', () {
      expect(
        AppFontLabel.curated,
        containsAll([
          AppFont.gungeon,
          AppFont.megrim,
          AppFont.bungee,
          AppFont.lilitaOne,
          AppFont.germaniaOne,
          AppFont.anton,
          AppFont.fjallaOne,
          AppFont.wallpoet,
          AppFont.monoton,
          AppFont.pressStart2p,
        ]),
      );
      expect(AppFontLabel.curated.length, 10);
      // Deprecated members exist for index stability but are hidden.
      expect(AppFontLabel.isOffered(AppFont.orbitron), isFalse);
      expect(AppFontLabel.isOffered(AppFont.montserrat), isFalse);
      expect(AppFontLabel.isOffered(AppFont.fjallaOne), isTrue);
      // Neo-Skeuo trio stays valid but skin-locked.
      expect(AppFontLabel.isOffered(AppFont.patrickHand), isTrue);
      expect(AppFontLabel.curated, isNot(contains(AppFont.patrickHand)));
    });

    test('migrate maps deprecated fonts by role', () {
      expect(AppFontLabel.migrate(AppFont.orbitron), AppFont.fjallaOne);
      expect(AppFontLabel.migrate(AppFont.vt323), AppFont.pressStart2p);
      expect(AppFontLabel.migrate(AppFont.cinzel), AppFont.germaniaOne);
      expect(AppFontLabel.migrate(AppFont.fredoka), AppFont.lilitaOne);
      expect(AppFontLabel.migrate(AppFont.archivoBlack), AppFont.anton);
      // Live fonts pass through untouched.
      expect(AppFontLabel.migrate(AppFont.bungee), AppFont.bungee);
      expect(AppFontLabel.migrate(AppFont.gungeon), AppFont.gungeon);
      expect(AppFontLabel.migrate(AppFont.patrickHand), AppFont.patrickHand);
    });

    test('every offered font resolves a bundled family that exists', () {
      for (final f in [...AppFontLabel.curated, ...AppFontLabel.skeuoOnly]) {
        final fam = f.bundledFontFamily;
        expect(fam, isNotEmpty);
        expect(fam, isNot(contains(' ')), reason: '$f family "$fam"');
      }
      // Deprecated fonts fall back to the signature face, never a
      // nonexistent GoogleFonts.* family.
      expect(AppFont.orbitron.bundledFontFamily, 'EnterTheGungeonBig');
    });

    test('deprecated persisted font index migrates on load', () {
      // orbitron.index written by an old build must not survive as
      // orbitron — it lands on fjallaOne.
      final j = const VisualPrefs().toJson()..['font'] = AppFont.orbitron.index;
      expect(VisualPrefs.fromJson(j).font, AppFont.fjallaOne);
      // CustomThemeData font field migrates the same way.
      final d = CustomThemeData.fromJson({'font': AppFont.vt323.index});
      expect(d.font, AppFont.pressStart2p);
      // Random themes only ever pick from the curated set.
      for (var i = 0; i < 50; i++) {
        final r = CustomThemeData.random();
        expect(AppFontLabel.curated, contains(r.font));
      }
    });
  });

  group('Wallpaper names', () {
    test('every bundled wallpaper has a lore name', () {
      for (final f in kCustomWallpaperAssets) {
        expect(
          wallpaperDisplayName(f),
          isNot(f),
          reason: '$f missing from kWallpaperNames',
        );
        expect(kWallpaperNames[f], isNotEmpty);
      }
      expect(kWallpaperNames.length, kCustomWallpaperAssets.length);
    });
  });

  group('Ambience load guard', () {
    test('ambienceLoad counts heavy backdrop layers', () {
      expect(const VisualPrefs().ambienceLoad, 1); // particles on by default
      expect(
        VisualPrefs(
          ambientKindIndex: AmbientKind.ash.index,
          liquidKindIndex: LiquidKind.blood.index,
          shaderEnabled: true,
          particlesEnabled: true,
        ).ambienceLoad,
        4,
      );
      expect(
        VisualPrefs(
          ambientKindIndex: AmbientKind.off.index,
          liquidKindIndex: LiquidKind.off.index,
          shaderEnabled: false,
          particlesEnabled: false,
        ).ambienceLoad,
        0,
      );
    });

    test('calmAmbience kills shader + scene, keeps identity picks', () async {
      VisualPrefs.notifier.value = VisualPrefs(
        ambientKindIndex: AmbientKind.runes.index,
        liquidKindIndex: LiquidKind.venom.index,
        shaderEnabled: true,
        particlesEnabled: true,
      );
      await VisualPrefs.calmAmbience();
      final p = VisualPrefs.notifier.value;
      expect(p.shaderEnabled, isFalse);
      expect(p.ambientKindIndex, AmbientKind.off.index);
      expect(p.liquidKindIndex, LiquidKind.venom.index);
      expect(p.particlesEnabled, isTrue);
      expect(p.ambienceLoad, 2);
    });
  });

  group('Theme splash integrity', () {
    test('every advertised splashSlug resolves to a file on disk', () {
      // U-013 regression guard — 12 modes pointed at JPGs that were
      // never bundled, so the studio silently showed gradient fallbacks.
      final missing = <String>[
        for (final mode in AppThemeMode.values)
          if (mode.splashSlug.isNotEmpty &&
              !File(themeSplashPath(mode.splashSlug)).existsSync())
            '${mode.name} -> ${mode.splashSlug}',
      ];
      expect(missing, isEmpty, reason: 'splash files missing: $missing');
    });

    test('every splash file on disk is advertised by a mode', () {
      final advertised =
          AppThemeMode.values
              .map((m) => m.splashSlug)
              .where((s) => s.isNotEmpty)
              .toSet();
      final dir = Directory('assets/images/themes/splash');
      final orphans =
          dir
              .listSync()
              .whereType<File>()
              .map((f) => f.uri.pathSegments.last.replaceAll('.jpg', ''))
              .where((slug) => !advertised.contains(slug))
              .toList();
      expect(orphans, isEmpty, reason: 'orphan splash files: $orphans');
    });
  });
}
