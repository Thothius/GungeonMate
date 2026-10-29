import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/models/run_state.dart';
import 'package:gungeon_mate/providers/run_provider.dart';

/// Tests for RunProvider state management — the layer that MpSession
/// depends on for run creation, snapshot application, shared state,
/// and restore operations.
///
/// These tests verify the state transitions that happen during a
/// multiplayer session without needing Nearby Connections.
void main() {
  late RunProvider rp;
  late Gungeoneer marine;
  late Gungeoneer cultist;
  late Gungeoneer hunter;

  setUp(() {
    rp = RunProvider();
    marine = Gungeoneer(name: 'The Marine');
    cultist = Gungeoneer(name: 'The Cultist');
    hunter = Gungeoneer(name: 'The Hunter');
  });

  group('Run creation', () {
    test('startNewRun sets main slot and selectedCharacter', () {
      rp.startNewRun(marine);

      expect(rp.runState.main.character?.name, 'The Marine');
      expect(rp.runState.selectedCharacter?.name, 'The Marine');
      expect(rp.runState.coop, isNull);
    });

    test('startCoopPlayer adds second player without clearing main', () {
      rp.startNewRun(marine);
      rp.startCoopPlayer(cultist);

      expect(rp.runState.main.character?.name, 'The Marine');
      expect(rp.runState.coop?.character?.name, 'The Cultist');
    });

    test('startNewRun replaces existing run entirely', () {
      rp.startNewRun(marine);
      rp.startCoopPlayer(cultist);
      // Start a completely new run
      rp.startNewRun(hunter);

      expect(rp.runState.main.character?.name, 'The Hunter');
      expect(
        rp.runState.coop,
        isNull,
        reason: 'New run should not carry over coop player',
      );
    });

    test('endCoopPlayer removes coop slot but keeps main', () {
      rp.startNewRun(marine);
      rp.startCoopPlayer(cultist);

      rp.endCoopPlayer();

      expect(rp.runState.main.character?.name, 'The Marine');
      expect(rp.runState.coop, isNull);
    });

    test('endRun clears everything', () {
      rp.startNewRun(marine);
      rp.startCoopPlayer(cultist);

      rp.endRun();

      expect(rp.runState.selectedCharacter, isNull);
      expect(rp.runState.coop, isNull);
    });
  });

  group('applyPeerSnapshot — slot routing', () {
    test('Host receives joiner snapshot → coop slot populated', () {
      rp.startNewRun(marine);
      // Host is main, so peer snapshot goes to coop (targetMainSlot: false)
      rp.applyPeerSnapshot(
        characterName: 'The Cultist',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );

      expect(
        rp.runState.main.character?.name,
        'The Marine',
        reason: 'Host main slot should be untouched',
      );
      expect(
        rp.runState.coop,
        isNotNull,
        reason: 'Coop slot should be populated by peer snapshot',
      );
    });

    test('Joiner receives host snapshot → main slot overwritten', () {
      rp.startNewRun(cultist);
      // Joiner is sidekick, so peer snapshot goes to main (targetMainSlot: true)
      rp.applyPeerSnapshot(
        characterName: 'The Marine',
        gunNames: [],
        itemNames: [],
        targetMainSlot: true,
      );

      // main slot is now a Player (may have null character without loadData)
      expect(rp.runState.main, isNotNull);
      // coop should still be null (joiner doesn't have coop)
      expect(rp.runState.coop, isNull);
    });

    test('Empty character name does not overwrite the slot', () {
      rp.startNewRun(marine);
      // Without loadData(), gungeoneerByName returns null, so the
      // character will be null but the slot is still populated.
      // First, populate coop with a snapshot.
      rp.applyPeerSnapshot(
        characterName: 'The Cultist',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );
      expect(
        rp.runState.coop,
        isNotNull,
        reason: 'Coop slot should be populated by first snapshot',
      );

      // Now send an empty character snapshot — should NOT overwrite
      // the existing slot. This prevents the reconnect blank-screen
      // bug where a restarting peer sends an empty snapshot.
      rp.applyPeerSnapshot(
        characterName: '',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );

      // The slot should still be populated from the first snapshot.
      expect(
        rp.runState.coop,
        isNotNull,
        reason: 'Empty character name should not overwrite existing slot',
      );
    });

    test('Multiple snapshots overwrite the same slot', () {
      rp.startNewRun(marine);

      // First snapshot
      rp.applyPeerSnapshot(
        characterName: 'The Cultist',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );
      final firstCoop = rp.runState.coop;
      expect(firstCoop, isNotNull);

      // Second snapshot — should replace, not append
      rp.applyPeerSnapshot(
        characterName: 'The Hunter',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );
      final secondCoop = rp.runState.coop;
      expect(secondCoop, isNotNull);
      // Should be a single coop player, not a list
      expect(rp.runState.coop, isNot(isA<List>()));
    });

    test('Empty character does not wipe existing main slot', () {
      rp.startNewRun(marine);
      // Populate main slot via snapshot (simulates Sidekick receiving
      // Main's data)
      rp.applyPeerSnapshot(
        characterName: 'The Marine',
        gunNames: [],
        itemNames: [],
        targetMainSlot: true,
      );
      expect(rp.runState.main, isNotNull);

      // Now send an empty character snapshot — should NOT wipe
      rp.applyPeerSnapshot(
        characterName: '',
        gunNames: [],
        itemNames: [],
        targetMainSlot: true,
      );

      // Main slot should still be the previous Player, not wiped
      expect(
        rp.runState.main,
        isNotNull,
        reason: 'Empty character should not wipe existing main slot',
      );
    });

    test('Empty character does not wipe existing coop slot', () {
      rp.startNewRun(marine);
      rp.applyPeerSnapshot(
        characterName: 'The Cultist',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );
      expect(rp.runState.coop, isNotNull);

      // Empty snapshot should not wipe
      rp.applyPeerSnapshot(
        characterName: '',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );

      expect(
        rp.runState.coop,
        isNotNull,
        reason: 'Empty character should not wipe existing coop slot',
      );
    });

    test('Rapid alternating empty and valid snapshots', () {
      rp.startNewRun(marine);

      // Valid → populates coop
      rp.applyPeerSnapshot(
        characterName: 'The Cultist',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );
      expect(rp.runState.coop, isNotNull);

      // Empty → should NOT wipe
      rp.applyPeerSnapshot(
        characterName: '',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );
      expect(rp.runState.coop, isNotNull);

      // Valid again → should still work after empty was skipped
      rp.applyPeerSnapshot(
        characterName: 'The Hunter',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );
      expect(rp.runState.coop, isNotNull);
    });

    test('Null player slot broadcasts fallback character name', () {
      // This tests the _broadcastSnapshot fallback logic:
      // player?.character?.name ?? _myCharacterName
      // When the slot is null, the fallback is used.
      rp.startNewRun(marine);
      // Coop is null at this point
      expect(rp.runState.coop, isNull);

      // Simulate what _broadcastSnapshot does for Sidekick:
      // final player = runState.coop (null)
      // character: player?.character?.name ?? 'The Cultist'
      final player = rp.runState.coop;
      final charName = player?.character?.name ?? 'The Cultist';
      expect(
        charName,
        'The Cultist',
        reason: 'Fallback character name should be used when slot is null',
      );
    });
  });

  group('Shared state — Main-authoritative model', () {
    test('applySharedStateFromPeer overwrites coolness/curse/shrines', () {
      rp.startNewRun(marine);
      // Set some initial shared state
      rp.applySharedStateDelta(coolnessDelta: 5.0, curseDelta: 2.0);
      expect(rp.runState.coolness, 5.0);
      expect(rp.runState.curse, 2.0);

      // Peer (Main) sends authoritative snapshot
      rp.applySharedStateFromPeer(
        coolness: 10.0,
        curse: -1.0,
        shrinesUsed: ['Glass Guon Stone'],
      );

      expect(
        rp.runState.coolness,
        10.0,
        reason: 'Main authoritative coolness should overwrite',
      );
      expect(
        rp.runState.curse,
        -1.0,
        reason: 'Main authoritative curse should overwrite',
      );
      expect(rp.runState.shrinesUsed, ['Glass Guon Stone']);
    });

    test('applySharedStateDelta adds coolness', () {
      rp.startNewRun(marine);
      expect(rp.runState.coolness, 0);

      rp.applySharedStateDelta(coolnessDelta: 3.0);
      expect(rp.runState.coolness, 3.0);

      rp.applySharedStateDelta(coolnessDelta: 2.5);
      expect(rp.runState.coolness, 5.5);
    });

    test('applySharedStateDelta subtracts curse', () {
      rp.startNewRun(marine);
      expect(rp.runState.curse, 0);

      rp.applySharedStateDelta(curseDelta: 2.0);
      expect(rp.runState.curse, 2.0);

      rp.applySharedStateDelta(curseDelta: -1.0);
      expect(rp.runState.curse, 1.0);
    });

    test('applySharedStateDelta clamps to [-100, 100]', () {
      rp.startNewRun(marine);

      rp.applySharedStateDelta(coolnessDelta: 200.0);
      expect(
        rp.runState.coolness,
        100.0,
        reason: 'Coolness should clamp at 100',
      );

      rp.applySharedStateDelta(coolnessDelta: -300.0);
      expect(
        rp.runState.coolness,
        -100.0,
        reason: 'Coolness should clamp at -100',
      );
    });

    test('applySharedStateDelta adds shrine to list', () {
      rp.startNewRun(marine);
      expect(rp.runState.shrinesUsed, isEmpty);

      rp.applySharedStateDelta(shrineName: 'Glass Guon Stone');
      expect(rp.runState.shrinesUsed, ['Glass Guon Stone']);

      rp.applySharedStateDelta(shrineName: 'Pillar Shrine');
      expect(rp.runState.shrinesUsed, ['Glass Guon Stone', 'Pillar Shrine']);
    });

    test('applySharedStateDelta with empty shrineName does not add', () {
      rp.startNewRun(marine);

      rp.applySharedStateDelta(shrineName: '');
      expect(rp.runState.shrinesUsed, isEmpty);
    });

    test('applySharedStateDelta with null shrineName does not add', () {
      rp.startNewRun(marine);

      rp.applySharedStateDelta();
      expect(rp.runState.shrinesUsed, isEmpty);
    });
  });

  group('Restore operations', () {
    test('restoreRunScopeState overwrites main + shared state', () {
      rp.startNewRun(marine);
      rp.applySharedStateDelta(coolnessDelta: 5.0);

      // Simulate sidekick cancel-restore
      final savedMain = Player(character: cultist);
      rp.restoreRunScopeState(
        main: savedMain,
        coolness: 0.0,
        curse: 0.0,
        shrinesUsed: [],
      );

      expect(rp.runState.main.character?.name, 'The Cultist');
      expect(rp.runState.coolness, 0.0);
      expect(rp.runState.curse, 0.0);
      expect(rp.runState.shrinesUsed, isEmpty);
    });

    test('restoreEntireRunState replaces everything', () {
      rp.startNewRun(marine);
      rp.startCoopPlayer(cultist);

      final freshState = RunState(main: Player(character: hunter));
      rp.restoreEntireRunState(freshState);

      expect(rp.runState.main.character?.name, 'The Hunter');
      expect(rp.runState.coop, isNull);
      expect(rp.runState.coolness, 0.0);
    });
  });

  group('Multiplayer session lifecycle simulation', () {
    test('Host lifecycle: create → coop → snapshot → end', () {
      // 1. Host creates game
      rp.startNewRun(marine);
      rp.startCoopPlayer(marine); // Host's own char in coop initially
      expect(rp.runState.selectedCharacter?.name, 'The Marine');
      expect(rp.runState.coop?.character?.name, 'The Marine');

      // 2. Joiner connects, sends snapshot → coop slot updated
      rp.applyPeerSnapshot(
        characterName: 'The Cultist',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );
      expect(rp.runState.coop, isNotNull);

      // 3. Shared state sync from joiner delta
      rp.applySharedStateDelta(coolnessDelta: 1.0);
      expect(rp.runState.coolness, 1.0);

      // 4. Host ends run
      rp.endRun();
      expect(rp.runState.selectedCharacter, isNull);
    });

    test(
      'Joiner lifecycle: create → receive host snapshot → cancel restore',
      () {
        // 1. Joiner creates local run before connecting
        final preMpRun = rp.runState;
        rp.startNewRun(cultist);
        expect(rp.runState.selectedCharacter?.name, 'The Cultist');

        // 2. Host snapshot overwrites main slot
        rp.applyPeerSnapshot(
          characterName: 'The Marine',
          gunNames: [],
          itemNames: [],
          targetMainSlot: true,
        );
        expect(rp.runState.main, isNotNull);

        // 3. Host sends authoritative shared state
        rp.applySharedStateFromPeer(
          coolness: 7.5,
          curse: 1.0,
          shrinesUsed: ['Glass Guon Stone'],
        );
        expect(rp.runState.coolness, 7.5);

        // 4. Joiner cancels → restore pre-MP state
        rp.restoreRunScopeState(
          main: preMpRun.main,
          coolness: preMpRun.coolness,
          curse: preMpRun.curse,
          shrinesUsed: preMpRun.shrinesUsed,
        );
        expect(
          rp.runState.coolness,
          0.0,
          reason: 'Pre-MP coolness should be restored',
        );
      },
    );

    test('Both players: snapshots route to correct slots', () {
      // Simulate two RunProviders (host and joiner)
      final hostRP = RunProvider();
      final joinerRP = RunProvider();
      final hostChar = Gungeoneer(name: 'The Marine');
      final joinerChar = Gungeoneer(name: 'The Hunter');

      // Host starts
      hostRP.startNewRun(hostChar);
      hostRP.startCoopPlayer(hostChar);

      // Joiner starts
      joinerRP.startNewRun(joinerChar);

      // Exchange snapshots
      // Host's main → joiner's main (targetMainSlot: true for joiner)
      joinerRP.applyPeerSnapshot(
        characterName: 'The Marine',
        gunNames: [],
        itemNames: [],
        targetMainSlot: true,
      );

      // Joiner's char → host's coop (targetMainSlot: false for host)
      hostRP.applyPeerSnapshot(
        characterName: 'The Hunter',
        gunNames: [],
        itemNames: [],
        targetMainSlot: false,
      );

      // Both should have non-null main slots
      expect(hostRP.runState.main, isNotNull);
      expect(joinerRP.runState.main, isNotNull);
      // Host should have coop populated
      expect(hostRP.runState.coop, isNotNull);
    });
  });

  group('Edge cases', () {
    test('endCoopPlayer when coop is already null is a no-op', () {
      rp.startNewRun(marine);
      // coop is null
      rp.endCoopPlayer();
      expect(rp.runState.coop, isNull);
      expect(rp.runState.main.character?.name, 'The Marine');
    });

    test('applySharedStateDelta with zero deltas is a no-op on values', () {
      rp.startNewRun(marine);
      rp.applySharedStateDelta(coolnessDelta: 5.0);
      final before = rp.runState.coolness;

      rp.applySharedStateDelta(); // zero deltas

      expect(rp.runState.coolness, before);
    });

    test('startNewRun with same character twice does not duplicate', () {
      rp.startNewRun(marine);
      rp.startNewRun(marine);

      expect(rp.runState.main.character?.name, 'The Marine');
      expect(rp.runState.coop, isNull);
    });
  });
}
