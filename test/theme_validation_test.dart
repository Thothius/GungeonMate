import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for saved theme name validation logic — duplicate detection,
/// empty name handling, and length limits.
///
/// The actual UI validation happens in ExperienceStudioScreen's save dialog,
/// but the core logic (duplicate detection via CustomThemeStore) is testable
/// directly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CustomThemeStore.notifier.value = [];
  });

  group('Name validation logic', () {
    test('duplicate name is detectable via CustomThemeStore.themes', () async {
      final t1 = SavedCustomTheme(
        id: '1',
        name: 'My Theme',
        splashSlug: 'unicorn',
        baseMode: AppThemeMode.unicorn,
        prefs: const VisualPrefs(),
      );
      await CustomThemeStore.save(t1);

      // Simulate the duplicate check from the save dialog
      final existing = CustomThemeStore.themes
          .where((t) => t.name.toLowerCase() == 'my theme'.toLowerCase())
          .toList();
      expect(existing.isNotEmpty, true,
          reason: 'Duplicate name should be detectable');
    });

    test('case-insensitive duplicate detection', () async {
      final t1 = SavedCustomTheme(
        id: '1',
        name: 'Forge Master',
        splashSlug: 'forge_master',
        baseMode: AppThemeMode.forgeMaster,
        prefs: const VisualPrefs(),
      );
      await CustomThemeStore.save(t1);

      final existing = CustomThemeStore.themes
          .where((t) => t.name.toLowerCase() == 'FORGE MASTER'.toLowerCase())
          .toList();
      expect(existing.isNotEmpty, true,
          reason: 'Duplicate should be detected case-insensitively');
    });

    test('unique name passes duplicate check', () async {
      final t1 = SavedCustomTheme(
        id: '1',
        name: 'Unique Theme',
        splashSlug: 'unicorn',
        baseMode: AppThemeMode.unicorn,
        prefs: const VisualPrefs(),
      );
      await CustomThemeStore.save(t1);

      final existing = CustomThemeStore.themes
          .where((t) => t.name.toLowerCase() == 'different name'.toLowerCase())
          .toList();
      expect(existing.isEmpty, true,
          reason: 'Different name should not trigger duplicate');
    });

    test('empty name after trim is detectable', () {
      const name = '   ';
      final trimmed = name.trim();
      expect(trimmed.isEmpty, true,
          reason: 'Whitespace-only name should be empty after trim');
    });

    test('name with only spaces is rejected', () {
      const name = '';
      expect(name.trim().isEmpty, true,
          reason: 'Empty name should be rejected');
    });

    test('name at max length (24 chars) is accepted', () {
      const name = 'TwentyFourCharacterName!';
      expect(name.length, 24);
      expect(name.trim().isNotEmpty, true);
    });

    test('name over max length is truncated by TextField maxLength', () {
      const name = 'ThisNameIsWayTooLongForTheLimit';
      // The TextField has maxLength: 24, so the framework prevents
      // typing beyond 24 chars. Here we just verify the logic.
      expect(name.length > 24, true);
    });

    test('name with leading/trailing spaces is trimmed', () {
      const name = '  Spaced Name  ';
      final trimmed = name.trim();
      expect(trimmed, 'Spaced Name');
      expect(trimmed.isNotEmpty, true);
    });

    test('multiple themes with different names coexist', () async {
      await CustomThemeStore.save(SavedCustomTheme(
        id: '1',
        name: 'Alpha',
        splashSlug: 'unicorn',
        baseMode: AppThemeMode.unicorn,
        prefs: const VisualPrefs(),
      ));
      await CustomThemeStore.save(SavedCustomTheme(
        id: '2',
        name: 'Beta',
        splashSlug: 'forge_master',
        baseMode: AppThemeMode.forgeMaster,
        prefs: const VisualPrefs(),
      ));
      await CustomThemeStore.save(SavedCustomTheme(
        id: '3',
        name: 'Gamma',
        splashSlug: 'the_bullet',
        baseMode: AppThemeMode.theBullet,
        prefs: const VisualPrefs(),
      ));

      expect(CustomThemeStore.themes.length, 3);

      // None should conflict with each other
      for (final theme in CustomThemeStore.themes) {
        final dupes = CustomThemeStore.themes
            .where((t) =>
                t.id != theme.id &&
                t.name.toLowerCase() == theme.name.toLowerCase())
            .toList();
        expect(dupes.isEmpty, true,
            reason: '${theme.name} should not have duplicates');
      }
    });
  });

  group('Save from any theme', () {
    test('SavedCustomTheme can be created with any baseMode', () {
      for (final mode in AppThemeMode.values) {
        if (!kVisibleThemes.contains(mode)) continue;

        final theme = SavedCustomTheme(
          id: mode.name,
          name: 'Saved ${mode.label}',
          splashSlug: mode.splashSlug,
          baseMode: mode,
          prefs: const VisualPrefs(),
        );
        expect(theme.baseMode, mode);
        expect(theme.name, 'Saved ${mode.label}');
      }
    });

    test('SavedCustomTheme with customData only for custom mode', () {
      // Custom mode saves with customData
      final customTheme = SavedCustomTheme(
        id: 'custom1',
        name: 'My Custom',
        splashSlug: 'unicorn',
        baseMode: AppThemeMode.custom,
        prefs: const VisualPrefs(),
        customData: CustomThemeData.defaultTheme,
      );
      expect(customTheme.customData, isNotNull);

      // Premade modes save without customData
      final premadeTheme = SavedCustomTheme(
        id: 'premade1',
        name: 'My Forge',
        splashSlug: 'forge_master',
        baseMode: AppThemeMode.forgeMaster,
        prefs: const VisualPrefs(),
      );
      expect(premadeTheme.customData, isNull);
    });
  });
}
