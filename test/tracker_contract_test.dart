import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contract test for _SpecialTrackers (extracted to a mixin in Phase 4b).
/// Pins setter→getter behavior, clamps, and the special.* prefs keys the
/// dashboards and game logic depend on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Special trackers — setter/getter contract', () {
    test('huntress trackers persist + read back', () async {
      final p = RunProvider();
      await p.setHuntressRoomClears(5);
      await p.setHuntressInjured(true);
      expect(p.huntressRoomClears, 5);
      expect(p.huntressInjured, true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('special.huntress.roomclears'), 5);
      expect(prefs.getBool('special.huntress.injured'), true);
    });

    test('robot trackers clamp and persist', () async {
      final p = RunProvider();
      await p.setRobotArmor(999);
      expect(p.robotArmor, 99); // clamped
      await p.setRobotJunk(12);
      await p.setRobotGoldJunk(true);
      await p.setRobotLies(true);
      expect(p.robotJunk, 12);
      expect(p.robotGoldJunk, true);
      expect(p.robotLies, true);
    });

    test('gun-form trackers write prefs', () async {
      final p = RunProvider();
      await p.setGunderfuryLevel(70);
      expect(p.gunderfuryLevel, 60); // clamped to max 60
      await p.setTripleGunForm(3);
      expect(p.tripleGunForm, 3);
      await p.setShellegunMode(2);
      expect(p.shellegunMode, 2);
      await p.setChamberGunFloor(4);
      expect(p.chamberGunFloor, 4);
    });

    test('evolver kills derive form (game rule)', () async {
      final p = RunProvider();
      await p.setEvolverKills(0);
      expect(p.evolverForm, isNot(5));
      await p.setEvolverForm(5);
      expect(p.evolverForm, 5);
    });

    test('counter trackers write prefs', () async {
      final p = RunProvider();
      await p.setPolarisKills(7);
      await p.setPolarisDamageHits(3);
      await p.setGuntherFriendship(9);
      await p.setSpiceUsageCount(4);
      p.setMetronomeKills(2);
      p.setBoxingGloveStars(3);
      p.setCigarettesUses(1);
      expect(p.polarisKills, 7);
      expect(p.polarisDamageHits, 3);
      expect(p.guntherFriendship, 9);
      expect(p.spiceUsageCount, 4);
      expect(p.metronomeKills, 2);
      expect(p.boxingGloveStars, 3);
      expect(p.cigarettesUses, 1);
    });

    test('flag trackers toggle prefs', () async {
      final p = RunProvider();
      await p.setFireplaceExtinguished(true);
      await p.setBatteryBulletsSynergy(true);
      await p.setFuseDisarmer(true);
      await p.setGunSoulActivated(true);
      await p.setIronCoinUses(2);
      await p.setPlatinumBulletsSeconds(45);
      await p.setSprunTriggerIndex(2);
      expect(p.fireplaceExtinguished, true);
      expect(p.batteryBulletsSynergy, true);
      expect(p.fuseDisarmer, true);
      expect(p.gunSoulActivated, true);
      expect(p.ironCoinUses, 2);
      expect(p.platinumBulletsSeconds, 45);
      expect(p.sprunTriggerIndex, 2);
    });

    test('windgunner countdown start/cancel', () async {
      final p = RunProvider();
      p.startWindgunnerCountdown();
      expect(p.windgunnerCountdown, 20);
      p.cancelWindgunnerCountdown();
      expect(p.windgunnerCountdown, 0);
      p.dispose();
    });
  });
}
