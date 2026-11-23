import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/providers/run_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('no saved run → saveWasCorrupt stays false', () async {
    SharedPreferences.setMockInitialValues({});
    final rp = RunProvider();
    await rp.loadData();
    expect(rp.saveWasCorrupt, isFalse);
  });

  test('corrupt primary + no backup → saveWasCorrupt true (L6-2)',
      () async {
    SharedPreferences.setMockInitialValues({
      'current_run': '{this is not json',
    });
    final rp = RunProvider();
    await rp.loadData();
    expect(rp.saveWasCorrupt, isTrue);
    expect(rp.error, isNull); // still boots — just no longer silent
  });

  test('corrupt primary + corrupt backup → saveWasCorrupt true', () async {
    SharedPreferences.setMockInitialValues({
      'current_run': '{broken',
      'current_run_backup': '{also broken',
    });
    final rp = RunProvider();
    await rp.loadData();
    expect(rp.saveWasCorrupt, isTrue);
  });
}
