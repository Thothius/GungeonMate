import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/services/codex_prefs.dart';

/// CodexPrefs — favorites/recents persistence + key format.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CodexPrefs.debugReset();
  });

  test('keyFor/parseKey round-trips and survives pipes in names', () {
    final key = CodexPrefs.keyFor('enemies', 'Hitbullet|True');
    expect(key, 'enemies|Hitbullet|True');
    final (section, name) = CodexPrefs.parseKey(key);
    expect(section, 'enemies');
    expect(name, 'Hitbullet|True');
  });

  test('parseKey handles malformed keys', () {
    expect(CodexPrefs.parseKey('noPipe').$1, '');
    expect(CodexPrefs.parseKey('noPipe').$2, 'noPipe');
  });

  test('toggleFavorite adds then removes', () async {
    await CodexPrefs.ensureLoaded();
    const key = 'bosses|Gatling Gull';
    await CodexPrefs.toggleFavorite(key);
    expect(CodexPrefs.isFavorite(key), isTrue);
    await CodexPrefs.toggleFavorite(key);
    expect(CodexPrefs.isFavorite(key), isFalse);
  });

  test('recordRecent moves key to front and dedupes', () async {
    await CodexPrefs.ensureLoaded();
    await CodexPrefs.recordRecent('npcs|Gunslinger');
    await CodexPrefs.recordRecent('enemies|Bullet Kin');
    await CodexPrefs.recordRecent('npcs|Gunslinger');
    expect(CodexPrefs.recents.value, [
      'npcs|Gunslinger',
      'enemies|Bullet Kin',
    ]);
  });

  test('recents persist across reload', () async {
    await CodexPrefs.ensureLoaded();
    await CodexPrefs.recordRecent('shrines|Ammo');
    await CodexPrefs.toggleFavorite('shrines|Ammo');

    // Simulate restart: reset in-memory, keep mock prefs.
    CodexPrefs.debugReset();
    await CodexPrefs.ensureLoaded();
    expect(CodexPrefs.recents.value, ['shrines|Ammo']);
    expect(CodexPrefs.isFavorite('shrines|Ammo'), isTrue);
  });
}
