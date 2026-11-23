import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/providers/run_provider.dart';

/// Synergy-scan perf proof (S3.6 / H13+L7).
///
/// The browse screen calls synergy queries per row; before memoization
/// every call rebuilt lowercase owned-sets and rescanned all ~395
/// synergies. This test fills a large inventory, times cold vs warm
/// calls across the whole query surface, and prints the numbers for the
/// session log. Assertions stay deliberately loose — this is a
/// measurement harness, not a flaky CI gate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RunProvider p;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    p = RunProvider();
    await p.loadData();
  });

  setUp(() {
    p.endRun();
    // Large stress inventory: every 8th catalog gun + item (~30+30),
    // biased toward synergy-piece names so matchesOwnedSet does real work.
    final guns = p.allGuns.where((g) => g.name.isNotEmpty).toList();
    final items = p.allItems.where((i) => i.name.isNotEmpty).toList();
    for (var i = 0; i < guns.length; i += 8) {
      p.addGun(guns[i]);
    }
    for (var i = 0; i < items.length; i += 9) {
      p.addItem(items[i]);
    }
  });

  void time(String label, void Function() fn, {int iters = 100}) {
    final sw = Stopwatch()..start();
    fn();
    sw.stop();
    final coldUs = sw.elapsedMicroseconds;
    sw
      ..reset()
      ..start();
    for (var i = 0; i < iters; i++) {
      fn();
    }
    sw.stop();
    // ignore: avoid_print
    print(
      'PERF $label: cold=${coldUs}us warm=${sw.elapsedMicroseconds ~/ iters}us/call '
      '(${sw.elapsedMicroseconds}us / $iters iters)',
    );
  }

  test('synergy query surface is memoized — cold vs warm timings', () {
    final ownedCount =
        p.runState.main.allItemNames.length +
        p.runState.main.guns.length +
        p.runState.main.items.length;
    // ignore: avoid_print
    print('PERF inventory size: $ownedCount entries');

    time('getActiveSynergies', p.getActiveSynergies);
    time('getPartialSynergies', p.getPartialSynergies);
    time('getActiveSynergiesCombined', p.getActiveSynergiesCombined);
    time('getSynergiesByInventory', p.getSynergiesByInventory, iters: 20);
    time('ownedNamesLowerMain', () => p.ownedNamesLowerMain, iters: 1000);

    // synergiesCompletedBy — the browse-screen hot path. Cold = first
    // call per item name (full 395-synergy scan); warm = cached.
    final catalogNames = [
      ...p.allGuns.map((g) => g.name),
      ...p.allItems.map((i) => i.name),
    ];
    final sw = Stopwatch()..start();
    var total = 0;
    for (final n in catalogNames) {
      total += p.synergiesCompletedBy(n).length;
    }
    sw.stop();
    // ignore: avoid_print
    print(
      'PERF synergiesCompletedBy x${catalogNames.length} names (cold, uncached names): '
      '${sw.elapsedMilliseconds}ms total=${total}',
    );
    sw
      ..reset()
      ..start();
    for (var i = 0; i < 5; i++) {
      for (final n in catalogNames) {
        p.synergiesCompletedBy(n);
      }
    }
    sw.stop();
    // ignore: avoid_print
    print(
      'PERF synergiesCompletedBy x${catalogNames.length} names warm x5: '
      '${sw.elapsedMilliseconds}ms',
    );

    // Sanity: memoized results are stable + correct-shaped.
    expect(p.getActiveSynergies(), isNotEmpty);
    expect(p.getSynergiesByInventory(), isNotEmpty);
    // Warm batch must stay trivially fast — generous bound so CI
    // timing jitter can't flake it (memoized calls are ~µs each).
    final warm = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      p.getActiveSynergies();
      p.getPartialSynergies();
      p.getActiveSynergiesCombined();
    }
    warm.stop();
    expect(
      warm.elapsedMilliseconds,
      lessThan(2000),
      reason: 'memoized synergy queries regressed: ${warm.elapsedMilliseconds}ms/300 calls',
    );
  });
}
