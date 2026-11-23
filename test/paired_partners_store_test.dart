import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/services/paired_partners_store.dart';

/// PairedPartnersStore — MP nickname persistence via SharedPreferences.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('loadNickname returns null when nothing saved', () async {
    expect(await PairedPartnersStore.loadNickname(), isNull);
  });

  test('saveNickname then loadNickname round-trips', () async {
    await PairedPartnersStore.saveNickname('GungeonMateFan');
    expect(await PairedPartnersStore.loadNickname(), 'GungeonMateFan');
  });

  test('overwriting replaces the previous nickname', () async {
    await PairedPartnersStore.saveNickname('First');
    await PairedPartnersStore.saveNickname('Second');
    expect(await PairedPartnersStore.loadNickname(), 'Second');
  });

  test('empty string nickname persists as empty, not null', () async {
    await PairedPartnersStore.saveNickname('');
    expect(await PairedPartnersStore.loadNickname(), '');
  });
}
