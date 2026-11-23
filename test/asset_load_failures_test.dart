import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/providers/run_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadData records no asset failures with bundled data', () async {
    SharedPreferences.setMockInitialValues({});
    final rp = RunProvider();
    await rp.loadData();

    // Every bundled asset should load+parse — an entry here means a real
    // asset broke (previously this degraded silently, L6-1).
    expect(rp.assetLoadFailures, isEmpty,
        reason: 'failed assets: ${rp.assetLoadFailures}');
    expect(rp.error, isNull);
    expect(rp.allGuns, isNotEmpty);
    expect(rp.allSynergies, isNotEmpty);
  });
}
