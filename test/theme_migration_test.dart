import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/services/app_theme.dart';

/// v3.0 theme cut migration — users persisted on a removed picker theme
/// (or a custom theme) must land on Moonlit Chamber at load. Supported
/// themes and the Minimalist default are untouched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> initWith(int? themeIdx) async {
    SharedPreferences.setMockInitialValues(
      themeIdx == null ? {} : {'theme.mode.v2': themeIdx},
    );
    await AppTheme.init();
  }

  test('removed picker themes migrate to Moonlit Chamber', () async {
    // gunpowder was cut from kPickerThemes in v3.0.
    await initWith(AppThemeMode.gunpowder.index);
    expect(AppTheme.mode, AppThemeMode.moonlitChamber);

    // lichsDomain likewise.
    await initWith(AppThemeMode.lichsDomain.index);
    expect(AppTheme.mode, AppThemeMode.moonlitChamber);
  });

  test('custom theme migrates to Moonlit Chamber', () async {
    await initWith(AppThemeMode.custom.index);
    expect(AppTheme.mode, AppThemeMode.moonlitChamber);
  });

  test('supported themes survive', () async {
    await initWith(AppThemeMode.unicorn.index);
    expect(AppTheme.mode, AppThemeMode.unicorn);

    await initWith(AppThemeMode.forgeMaster.index);
    expect(AppTheme.mode, AppThemeMode.forgeMaster);
  });

  test('minimalist default is not touched by the cut', () async {
    await initWith(AppThemeMode.minimalist.index);
    expect(AppTheme.mode, AppThemeMode.minimalist);
  });
}
