import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/providers/run_provider.dart';

/// Co-op synergy correctness — Enter the Gungeon evaluates synergies
/// strictly per player (AdvancedSynergyEntry.SynergyIsAvailable checks a
/// single PlayerController's inventory). Pieces split across P1+P2 do
/// NOT activate a synergy; the run-wide "combined" query must therefore
/// count a synergy only when ONE player's own inventory satisfies it.
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
  });

  /// Deterministic 2-piece synergy (gun + resolvable partner) — same
  /// driver style as gun_synergies_leb_test's findPair.
  ({String gunName, String synergyName, String partner}) findPair() {
    for (final gun in p.allGuns) {
      final lower = gun.name.toLowerCase();
      for (final s in p.getSynergiesFor(gun.name)) {
        if (s.items.length != 2 || s.anyOf.isNotEmpty) continue;
        if (!s.items.any((i) => i.toLowerCase() == lower)) continue;
        final partner = s.items.firstWhere(
          (i) => i.toLowerCase() != lower,
        );
        final r = p.entityByName(partner);
        if (r.gun != null || r.item != null) {
          return (
            gunName: gun.name,
            synergyName: s.name,
            partner: partner,
          );
        }
      }
    }
    throw StateError('catalog has no 2-piece gun synergy');
  }

  void own(String name, PlayerSlot slot) {
    final r = p.entityByName(name);
    if (r.item != null) {
      p.addItem(r.item!, slot: slot);
    } else {
      p.addGun(r.gun!, slot: slot);
    }
  }

  Set<String> activeNames() =>
      p.getActiveSynergiesCombined().map((s) => s.name).toSet();

  test('split pieces across P1+P2 do NOT activate the synergy', () {
    final pair = findPair();
    p.startNewRun(p.allGungeoneers.first);
    p.startCoopPlayer(p.allGungeoneers[1]);

    own(pair.gunName, PlayerSlot.main);
    own(pair.partner, PlayerSlot.coop);

    expect(
      activeNames(),
      isNot(contains(pair.synergyName)),
      reason: 'pieces split across players must not combine',
    );
  });

  test('all pieces on ONE player activates it in co-op', () {
    final pair = findPair();
    p.startNewRun(p.allGungeoneers.first);
    p.startCoopPlayer(p.allGungeoneers[1]);

    own(pair.gunName, PlayerSlot.main);
    own(pair.partner, PlayerSlot.main);

    expect(activeNames(), contains(pair.synergyName));
  });

  test('pieces on the CO-OP player also activate it', () {
    final pair = findPair();
    p.startNewRun(p.allGungeoneers.first);
    p.startCoopPlayer(p.allGungeoneers[1]);

    own(pair.gunName, PlayerSlot.coop);
    own(pair.partner, PlayerSlot.coop);

    expect(activeNames(), contains(pair.synergyName));
  });

  test('solo run unchanged — single inventory still activates', () {
    final pair = findPair();
    p.startNewRun(p.allGungeoneers.first);

    own(pair.gunName, PlayerSlot.main);
    own(pair.partner, PlayerSlot.main);

    expect(activeNames(), contains(pair.synergyName));
  });
}
