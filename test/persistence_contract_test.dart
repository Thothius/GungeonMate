import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';
import 'package:gungeon_mate/models/run_state.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp/mp_store.dart';

/// Persistence contract test — guards the on-disk save schema against
/// accidental drift during refactors (BIG_FILES/OPTIMIZATION_PLAN Phase 0).
///
/// If a refactor renames a SharedPreferences key, changes a value's type,
/// or reshapes RunState.toJson, this file fails LOUDLY before the change
/// can silently corrupt user saves. Keys and shapes asserted here are the
/// schema contract — do not change them without a migration.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('special.* setter → key contract', () {
    // Every tracker setter must write its exact persisted key. Fire-and-
    // forget _persistSpecial writes are flushed via pumpEventQueue().
    Future<SharedPreferences> flush() async {
      await pumpEventQueue();
      return SharedPreferences.getInstance();
    }

    test('int trackers write their special.* keys', () async {
      final rp = RunProvider();
      await rp.setRobotArmor(4);
      await rp.setRobotJunk(7);
      await rp.setGunderfuryLevel(42);
      await rp.setTripleGunForm(2);
      await rp.setEvolverForm(3);
      await rp.setEvolverKills(17);
      await rp.setSprunTriggerIndex(1);
      await rp.setSpiceUsageCount(5);
      await rp.setShellegunMode(2);
      await rp.setChamberGunFloor(4);
      await rp.setPlatinumBulletsSeconds(120);
      await rp.setIronCoinUses(1);
      await rp.setPolarisKills(9);
      await rp.setPolarisDamageHits(6);
      await rp.setGuntherFriendship(3);
      await rp.setHuntressRoomClears(8);
      rp.setMetronomeKills(11);
      rp.setBoxingGloveStars(2);
      rp.setCigarettesUses(4);
      final prefs = await flush();

      expect(prefs.getInt('special.robot.armor'), 4);
      expect(prefs.getInt('special.robot.junk'), 7);
      expect(prefs.getInt('special.gunderfury.level'), 42);
      expect(prefs.getInt('special.triple_gun.form'), 2);
      // Evolver form is DERIVED from kills — the kills setter rewrites
      // special.evolver.form. Contract: persisted value == getter.
      expect(prefs.getInt('special.evolver.form'), rp.evolverForm);
      expect(prefs.getInt('special.evolver.kills'), 17);
      expect(prefs.getInt('special.sprun.trigger'), 1);
      expect(prefs.getInt('special.spice.count'), 5);
      expect(prefs.getInt('special.shellegun.mode'), 2);
      expect(prefs.getInt('special.chambergun.floor'), 4);
      expect(prefs.getInt('special.platinum.seconds'), 120);
      expect(prefs.getInt('special.ironcoin.uses'), 1);
      expect(prefs.getInt('special.polaris.kills'), 9);
      expect(prefs.getInt('special.polaris.hits'), 6);
      expect(prefs.getInt('special.gunther.friendship'), 3);
      expect(prefs.getInt('special.huntress.roomclears'), 8);
      expect(prefs.getInt('special.metronome.kills'), 11);
      expect(prefs.getInt('special.boxingglove.stars'), 2);
      expect(prefs.getInt('special.cigarettes.uses'), 4);
    });

    test('bool trackers write their special.* keys', () async {
      final rp = RunProvider();
      await rp.setRobotGoldJunk(true);
      await rp.setRobotLies(true);
      await rp.setFireplaceExtinguished(true);
      await rp.setBatteryBulletsSynergy(true);
      await rp.setFuseDisarmer(true);
      await rp.setGunSoulActivated(true);
      await rp.setHuntressInjured(true);
      final prefs = await flush();

      expect(prefs.getBool('special.robot.goldjunk'), true);
      expect(prefs.getBool('special.robot.lies'), true);
      expect(prefs.getBool('special.robot.fireplace'), true);
      expect(prefs.getBool('special.robot.battery'), true);
      expect(prefs.getBool('special.robot.fusedisarmer'), true);
      expect(prefs.getBool('special.gunsoul.activated'), true);
      expect(prefs.getBool('special.huntress.injured'), true);
    });
  });

  group('RunState JSON shape contract', () {
    test('toJson → fromJson → toJson is stable', () {
      final rp = RunProvider();
      rp.startNewRun(Gungeoneer(name: 'The Marine'));
      rp.startCoopPlayer(Gungeoneer(name: 'The Cultist'));
      rp.addGun(Gun(name: 'AKEY-47', quality: 'B'), force: true);
      rp.addItem(Item(name: 'Junk', quality: 'N'), force: true);

      final json1 = rp.runState.toJson();
      // Contract: these keys must exist in the persisted shape.
      expect(json1.keys, containsAll(['main']));
      expect(json1['main'], isA<Map<String, dynamic>>());

      // Round-trip must be lossless at the JSON level — except `icon`
      // fields, which fromJson re-derives from the entity name
      // (localGunIcon/localItemIcon/gungeoneer icon paths). Strip them.
      final restored = RunState.fromJson(json1);
      final json2 = restored.toJson();
      expect(_stripIcons(json2), equals(_stripIcons(json1)));
    });
  });

  group('MpStore key contract', () {
    test('saveRunState writes mp.active_run decodable to RunState', () async {
      final rp = RunProvider();
      rp.startNewRun(Gungeoneer(name: 'The Hunter'));
      rp.addItem(Item(name: 'Casey'), force: true);

      await MpStore.saveRunState(rp.runState, force: true);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('mp.active_run');
      expect(raw, isNotNull);
      expect(raw, isNotEmpty);
    });

    test('session keys persist with mp.* prefix', () async {
      await MpStore.saveSession(
        role: MpRole.main,
        nickname: 'tester',
        character: 'The Pilot',
        avatarId: 'g1_1',
        runTitle: 'Contract Run',
        sessionNumber: 3,
      );
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getBool('mp.session_active'), true);
      expect(prefs.getString('mp.role'), 'main');
      expect(prefs.getString('mp.nickname'), 'tester');
      expect(prefs.getString('mp.character'), 'The Pilot');
      expect(prefs.getString('mp.avatar_id'), 'g1_1');
      expect(prefs.getString('mp.run_title'), 'Contract Run');
      expect(prefs.getInt('mp.session_number'), 3);
    });
  });
}

/// Recursively removes `icon` entries — they are re-derived from names on
/// deserialization, so they are not part of the persisted-shape contract.
Object? _stripIcons(Object? node) {
  if (node is Map) {
    return {
      for (final e in node.entries)
        if (e.key != 'icon') e.key: _stripIcons(e.value),
    };
  }
  if (node is List) return node.map(_stripIcons).toList();
  return node;
}
