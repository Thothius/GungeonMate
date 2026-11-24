import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/models/run_state.dart';
import 'package:gungeon_mate/providers/run_provider.dart';

/// Backpack storage: per-player 12-slot mixed pool flagged via
/// Player.backpackKeys. Stashed gear stays in guns/items so every
/// aggregation (synergies, DPS, coolness, dashboards) keeps counting.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RunProvider rp;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    rp = RunProvider();
    await rp.loadData();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rp.startNewRun(Gungeoneer(name: 'The Marine'));
  });

  Gun gun(String name) => Gun(name: name);
  Item item(String name) => Item(name: name);

  group('Backpack item grant', () {
    test('startNewRun grants every player the Backpack item', () {
      rp.startCoopPlayer(Gungeoneer(name: 'The Hunter'));

      for (final slot in PlayerSlot.values) {
        final p = slot == PlayerSlot.main
            ? rp.runState.main
            : rp.runState.coop!;
        expect(
          p.items.any((i) => i.name == RunProvider.kBackpackItemName),
          isTrue,
          reason: '$slot should own the Backpack item',
        );
      }
      expect(rp.itemByName('Backpack')?.name, 'Backpack');
      expect(rp.itemByName('backpack')?.isPassive, isTrue);
    });
  });

  group('stash / unstash', () {
    test('stashGun flags the key and keeps the gun in inventory', () {
      final g = gun('Test Gun');
      rp.addGun(g);

      expect(rp.stashGun(g), isTrue);
      expect(rp.isBackpacked(g, PlayerSlot.main), isTrue);
      expect(rp.backpackCount(PlayerSlot.main), 1);
      // Everything counts — the gun is still in the loadout.
      expect(rp.runState.main.guns.any((x) => x.name == 'Test Gun'), isTrue);

      rp.unstashGun(g);
      expect(rp.isBackpacked(g, PlayerSlot.main), isFalse);
      expect(rp.backpackCount(PlayerSlot.main), 0);
    });

    test('mixed pool — guns and items share the 12 slots', () {
      for (var i = 0; i < 7; i++) {
        rp.addGun(gun('Gun $i'));
        rp.addItem(item('Item $i'));
      }
      var stashed = 0;
      for (var i = 0; i < 7; i++) {
        if (rp.stashGun(gun('Gun $i'))) stashed++;
        if (rp.stashItem(item('Item $i'))) stashed++;
      }
      expect(stashed, RunProvider.kBackpackCapacity);
      expect(rp.backpackCount(PlayerSlot.main),
          RunProvider.kBackpackCapacity);
    });

    test('capacity blocks the 13th stash', () {
      for (var i = 0; i < 13; i++) {
        rp.addItem(item('Thing $i'));
      }
      for (var i = 0; i < 12; i++) {
        expect(rp.stashItem(item('Thing $i')), isTrue);
      }
      expect(rp.stashItem(item('Thing 12')), isFalse);
      expect(rp.backpackCount(PlayerSlot.main),
          RunProvider.kBackpackCapacity);
      // Blocked stash leaves the item in the open inventory.
      expect(rp.isBackpackedItem(item('Thing 12'), PlayerSlot.main), isFalse);
    });

    test('the Backpack item cannot stash itself', () {
      final bag = rp.runState.main.items
          .firstWhere((i) => i.name == RunProvider.kBackpackItemName);
      expect(rp.stashItem(bag), isFalse);
    });

    test('the Backpack item cannot be deleted', () {
      final bag = rp.runState.main.items
          .firstWhere((i) => i.name == RunProvider.kBackpackItemName);
      final before = rp.runState.main.items.length;

      rp.removeItem(bag);
      rp.removeItem(bag, force: true); // MP peer-remove path too

      expect(rp.runState.main.items.length, before);
      expect(
        rp.runState.main.items.any(
          (i) => i.name == RunProvider.kBackpackItemName,
        ),
        isTrue,
      );
    });

    test('stash rejects gear the slot does not own', () {
      expect(rp.stashItem(item('Not Owned Item')), isFalse);
      expect(rp.stashGun(gun('Not Owned Gun')), isFalse);
      expect(rp.backpackCount(PlayerSlot.main), 0);
    });

    test('duplicate-named stackables share one slot and one tile', () {
      // Junk bypasses addItem dedup — real stacks exist in runs.
      final junk = rp.itemByName('Junk')!;
      rp.addItem(junk);
      rp.addItem(junk);
      rp.addItem(junk);
      expect(
        rp.runState.main.items.where((i) => i.name == 'Junk').length,
        3,
      );

      expect(rp.stashItem(junk), isTrue);
      // One key = one slot, regardless of stack depth.
      expect(rp.backpackCount(PlayerSlot.main), 1);
      // …and one bag tile — entries must not over-report vs the counter.
      expect(rp.backpackEntries(PlayerSlot.main).length, 1);

      // Retrieving returns the whole stack (keys are name-based).
      rp.unstashItem(junk);
      expect(rp.backpackCount(PlayerSlot.main), 0);
      expect(
        rp.runState.main.items.where((i) => i.name == 'Junk').length,
        3,
      );
    });

    test('stash is per-slot — coop bag is independent', () {
      rp.startCoopPlayer(Gungeoneer(name: 'The Hunter'));
      final g = gun('Shared Name Gun');
      rp.addGun(g, slot: PlayerSlot.main);
      rp.addGun(g, slot: PlayerSlot.coop);

      rp.stashGun(g, slot: PlayerSlot.main);
      expect(rp.isBackpacked(g, PlayerSlot.main), isTrue);
      expect(rp.isBackpacked(g, PlayerSlot.coop), isFalse);
      expect(rp.backpackCount(PlayerSlot.coop), 0);
    });
  });

  group('key hygiene', () {
    test('removeItem prunes the stash key', () {
      final it = item('Stashed Item');
      rp.addItem(it);
      rp.stashItem(it);
      expect(rp.backpackCount(PlayerSlot.main), 1);

      rp.removeItem(it);
      expect(rp.backpackCount(PlayerSlot.main), 0);
    });

    test('removeGun prunes the stash key', () {
      final g = gun('Stashed Gun');
      rp.addGun(g);
      rp.stashGun(g);

      rp.removeGun(g);
      expect(rp.backpackCount(PlayerSlot.main), 0);
    });

    test('transferItem moves gear out of the stash', () {
      rp.startCoopPlayer(Gungeoneer(name: 'The Hunter'));
      final it = item('Hand-me-down');
      rp.addItem(it, slot: PlayerSlot.main);
      rp.stashItem(it, slot: PlayerSlot.main);

      expect(rp.transferItem(it, PlayerSlot.main), isTrue);
      expect(rp.backpackCount(PlayerSlot.main), 0);
      expect(
        rp.runState.coop!.items.any((i) => i.name == 'Hand-me-down'),
        isTrue,
      );
      expect(rp.isBackpackedItem(it, PlayerSlot.coop), isFalse);
    });
  });

  group('persistence', () {
    test('backpackKeys survive toJson/fromJson', () {
      final g = gun('Persistent Gun');
      rp.addGun(g);
      rp.stashGun(g);

      final json = rp.runState.toJson();
      final restored = RunState.fromJson(json);
      expect(restored.main.backpackKeys, contains('g:Persistent Gun'));
      expect(restored.main.guns.any((x) => x.name == 'Persistent Gun'),
          isTrue);
    });

    test('new run clears backpack contents', () {
      final g = gun('Doomed Gun');
      rp.addGun(g);
      rp.stashGun(g);
      expect(rp.backpackCount(PlayerSlot.main), 1);

      rp.startNewRun(Gungeoneer(name: 'The Hunter'));
      expect(rp.backpackCount(PlayerSlot.main), 0);
      expect(rp.runState.main.backpackKeys, isEmpty);
    });
  });

  group('everything counts', () {
    test('stashing does not change coolness/curse totals', () {
      final it = Item(name: 'Cool Gear', coolness: 5, curse: 1);
      rp.addItem(it);
      final beforeCool = rp.runState.totalCoolness;
      final beforeCurse = rp.runState.totalCurse;

      rp.stashItem(it);
      expect(rp.runState.totalCoolness, beforeCool);
      expect(rp.runState.totalCurse, beforeCurse);
      // And the item is still owned for synergy/DPS readers.
      expect(rp.runState.main.items.any((i) => i.name == 'Cool Gear'),
          isTrue);
    });

    test('stashed guns still resolve for DPS', () {
      final g = rp.allGuns.first;
      rp.addGun(g);
      final dpsBefore = rp.gunDps(g);
      rp.stashGun(g);
      expect(rp.gunDps(g), dpsBefore);
      expect(rp.runState.main.guns.any((x) => x.name == g.name), isTrue);
    });
  });

  group('MP snapshot interplay', () {
    test('applyPeerSnapshot preserves pruned backpack keys', () {
      rp.startCoopPlayer(Gungeoneer(name: 'The Hunter'));
      // Snapshots resolve names against the real catalog — use a real gun.
      final realName = rp.allGuns.first.name;
      final g = rp.allGuns.first;
      rp.addGun(g, slot: PlayerSlot.coop);
      rp.stashGun(g, slot: PlayerSlot.coop);

      // Peer snapshot rebuilds the coop slot from name lists — the
      // stash flag survives because placement is local-only.
      rp.applyPartnerSnapshot(
        characterName: 'The Hunter',
        gunNames: [realName],
        itemNames: const [],
      );
      expect(rp.runState.coop!.backpackKeys, contains('g:$realName'));

      // A snapshot that drops the gun prunes the stale key.
      rp.applyPartnerSnapshot(
        characterName: 'The Hunter',
        gunNames: const [],
        itemNames: const [],
      );
      expect(rp.runState.coop!.backpackKeys, isNot(contains('g:$realName')));
    });

    test('Backpack item name resolves through itemByName for peers', () {
      // Simulate a peer snapshot carrying the Backpack name — the
      // mirrored inventory must still contain it.
      rp.applyPeerSnapshot(
        characterName: 'The Hunter',
        gunNames: const [],
        itemNames: const ['Backpack'],
        targetMainSlot: false,
      );
      expect(
        rp.runState.coop!.items.any((i) => i.name == 'Backpack'),
        isTrue,
      );
    });
  });
}
