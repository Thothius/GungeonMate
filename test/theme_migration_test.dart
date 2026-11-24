import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/services/app_theme.dart';

/// Theme cut migration — users persisted on a theme removed from
/// kVisibleThemes land on the visible default (paperInk) at load.
/// Visible themes (unicorn/moltenSteel/paperInk/custom) are untouched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> initWith(int? themeIdx) async {
    SharedPreferences.setMockInitialValues(
      themeIdx == null ? {} : {'theme.mode.v2': themeIdx},
    );
    await AppTheme.init();
  }

  test('removed themes migrate to paperInk', () async {
    // gunpowder was cut from kVisibleThemes in v3.0.
    await initWith(AppThemeMode.gunpowder.index);
    expect(AppTheme.mode, AppThemeMode.paperInk);

    // lichsDomain likewise.
    await initWith(AppThemeMode.lichsDomain.index);
    expect(AppTheme.mode, AppThemeMode.paperInk);

    // forgeMaster and minimalist were also cut.
    await initWith(AppThemeMode.forgeMaster.index);
    expect(AppTheme.mode, AppThemeMode.paperInk);
    await initWith(AppThemeMode.minimalist.index);
    expect(AppTheme.mode, AppThemeMode.paperInk);
  });

  test('custom theme is kept (still visible)', () async {
    await initWith(AppThemeMode.custom.index);
    expect(AppTheme.mode, AppThemeMode.custom);
  });

  test('visible themes survive', () async {
    await initWith(AppThemeMode.unicorn.index);
    expect(AppTheme.mode, AppThemeMode.unicorn);

    await initWith(AppThemeMode.moltenSteel.index);
    expect(AppTheme.mode, AppThemeMode.moltenSteel);
  });

  test('punk trio are visible and survive index persistence', () async {
    // Appended after minimalist — every pre-existing enum index must be
    // unchanged or persisted 'theme.mode.v2' values would remap.
    for (final m in [
      AppThemeMode.popriot,
      AppThemeMode.neonRiot,
      AppThemeMode.toxiRiot,
    ]) {
      expect(kVisibleThemes, contains(m));
      expect(kPickerThemes, contains(m));
      await initWith(m.index);
      expect(AppTheme.mode, m);
    }
  });
}
