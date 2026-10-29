import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/widgets/particle_engine.dart'
    show ParticlePreset, GlowEffect, ParticleColorSchema, ParticleSpeed;
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
        font: AppFont.fredoka,
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
      expect(restored.font, AppFont.fredoka);
    });

    test('fromJson with missing fields uses defaults', () {
      final restored = CustomThemeData.fromJson({});

      expect(restored.name, 'Custom');
      expect(restored.auraStyle, AvatarAuraStyle.none);
      expect(restored.font, AppFont.gungeon);
    });

    test('copyWith overrides only specified fields', () {
      final original = CustomThemeData.defaultTheme;
      final updated = original.copyWith(
        primary: Colors.red,
        name: 'Red Theme',
      );

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

      final allFieldsMatch = r1.primary == r2.primary &&
          r1.secondary == r2.secondary &&
          r1.scaffold == r2.scaffold &&
          r1.card == r2.card &&
          r1.headlineStat == r2.headlineStat &&
          r1.bulletColor == r2.bulletColor;

      expect(allFieldsMatch, isFalse,
          reason: 'Two random themes should not match on every field');
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
        font: AppFont.montserrat,
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
      expect(restored.customData!.font, AppFont.montserrat);
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
      await prefs.setString('custom.themes.v1',
          '[${theme.toJson().toString()}]');

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
      expect(CustomThemeStore.themes.first.customData!.primary,
          const Color(0xFF222222));
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
      const newPrefs = VisualPrefs(
        glowIntensity: 0.7,
        particlesEnabled: true,
      );
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
    test('kPickerThemes has 9 entries (3 families × 3)', () {
      expect(kPickerThemes.length, 9);
      // Variants render band/fallback tiles — splash assets exist
      // only for the three family parents.
      for (final parent in [
        AppThemeMode.unicorn,
        AppThemeMode.forgeMaster,
        AppThemeMode.moonlitChamber,
      ]) {
        expect(kPickerThemes, contains(parent));
        expect(parent.splashSlug, isNotEmpty);
      }
    });

    test('kVisibleThemes includes custom', () {
      expect(kVisibleThemes, contains(AppThemeMode.custom));
    });

    test('kPickerThemes includes the Minimalist family', () {
      // moonlitChamber is the Minimalist enum (re-skin, index-stable).
      expect(kPickerThemes, contains(AppThemeMode.moonlitChamber));
      expect(kPickerThemes, contains(AppThemeMode.paperInk));
      expect(kPickerThemes, contains(AppThemeMode.voidWhite));
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
}
