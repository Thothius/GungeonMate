import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/services/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preset survives save -> wipe notifier -> load', () async {
    SharedPreferences.setMockInitialValues({});
    await CustomThemeStore.load();
    await VisualPrefs.init();
    await CustomThemeStore.save(
      SavedCustomTheme(
        id: 't1',
        name: 'DOOMED',
        splashSlug: 'custom',
        baseMode: AppThemeMode.custom,
        prefs: VisualPrefs.notifier.value,
        customData: CustomThemeData.defaultTheme,
      ),
    );
    expect(CustomThemeStore.themes, hasLength(1));

    // simulate restart: drop notifier + reload from disk
    CustomThemeStore.notifier.value = [];
    await CustomThemeStore.load();
    expect(CustomThemeStore.themes, hasLength(1),
        reason: 'preset lost across restart');
    expect(CustomThemeStore.themes.first.name, 'DOOMED');
  });
}
