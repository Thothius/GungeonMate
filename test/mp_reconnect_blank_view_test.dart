import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/services/mp/mp_store.dart';

import 'helpers/fake_mp_link.dart';

/// Regression tests for the v2.2.1 "blank view on reconnect" bug.
///
/// The bug: when one player reconnects, the peer's snapshot can have a
/// character name that the receiver's gungeoneerByName() can't find
/// (e.g. data not loaded yet, or character name mismatch). The old code
/// replaced the slot with Player(character: null), which wiped
/// selectedCharacter and flipped the HomeScreen to MainMenu — the user
/// saw "particles but no UI" (blank view).
///
/// The fix: if gungeoneerByName returns null, preserve the existing
/// character and only update guns/items. If there's no existing
/// character, skip the snapshot entirely.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RunProvider mainRp;
  late RunProvider sidekickRp;
  late Gungeoneer marine;
  late Gungeoneer cultist;
  late FakeMpLink hostLink;
  late FakeMpLink guestLink;
  MpSession? mainSession;
  MpSession? sidekickSession;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mainRp = RunProvider();
    sidekickRp = RunProvider();
    marine = Gungeoneer(name: 'The Marine');
    cultist = Gungeoneer(name: 'The Cultist');

    hostLink = FakeMpLink();
    guestLink = FakeMpLink();
    hostLink.connectTo(guestLink);

    mainSession = MpSession.withLink(mainRp, hostLink);
    sidekickSession = MpSession.withLink(sidekickRp, guestLink);
  });

  tearDown(() {
    mainSession?.dispose();
    sidekickSession?.dispose();
    mainSession = null;
    sidekickSession = null;
  });

  group('R1 — Snapshot with unknown character does not wipe selectedCharacter', () {
    test(
      'Sidekick selectedCharacter survives unknown-character snapshot',
      () async {
        await mainSession!.startAsMain(nickname: 'Host', character: marine);
        await sidekickSession!.startAsSidekick(
          nickname: 'Guest',
          character: cultist,
        );
        guestLink.simulateDiscovery();
        await Future.delayed(const Duration(milliseconds: 150));

        // Sidekick should have a character from Main's snapshot
        expect(
          sidekickRp.runState.selectedCharacter,
          isNotNull,
          reason: 'Sidekick should have a character after initial snapshot',
        );

        // Simulate Main reconnecting and sending a snapshot with a character
        // name that Sidekick's gungeoneerByName can't find (data not loaded).
        hostLink.sendMessage(
          const MpSnapshot(
            character: 'Unknown Character',
            gunNames: [],
            itemNames: [],
            coolness: 0,
            curse: 0,
            shrinesUsed: [],
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // CRITICAL: selectedCharacter should NOT be null (no blank view)
        expect(
          sidekickRp.runState.selectedCharacter,
          isNotNull,
          reason: 'selectedCharacter must survive unknown-character snapshot',
        );
      },
    );

    test(
      'Main selectedCharacter survives unknown-character snapshot from Sidekick',
      () async {
        await mainSession!.startAsMain(nickname: 'Host', character: marine);
        await sidekickSession!.startAsSidekick(
          nickname: 'Guest',
          character: cultist,
        );
        guestLink.simulateDiscovery();
        await Future.delayed(const Duration(milliseconds: 150));

        expect(mainRp.runState.selectedCharacter, isNotNull);

        // Sidekick sends a snapshot with an unknown character
        guestLink.sendMessage(
          const MpSnapshot(
            character: 'Unknown Character',
            gunNames: [],
            itemNames: [],
            coolness: 0,
            curse: 0,
            shrinesUsed: [],
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        // Main's selectedCharacter should be preserved (it's in the main slot,
        // not the coop slot, but the test verifies the guard works)
        expect(
          mainRp.runState.selectedCharacter,
          isNotNull,
          reason:
              'Main selectedCharacter must survive unknown-character snapshot',
        );
      },
    );
  });

  group('R2 — Full reconnect cycle preserves selectedCharacter', () {
    test(
      'Both sides preserve selectedCharacter through disconnect+reconnect',
      () async {
        await mainSession!.startAsMain(nickname: 'Host', character: marine);
        await sidekickSession!.startAsSidekick(
          nickname: 'Guest',
          character: cultist,
        );
        guestLink.simulateDiscovery();
        await Future.delayed(const Duration(milliseconds: 150));

        expect(mainRp.runState.selectedCharacter, isNotNull);
        expect(sidekickRp.runState.selectedCharacter, isNotNull);

        // Disconnect
        await hostLink.disconnectPeer();
        await Future.delayed(const Duration(milliseconds: 200));

        // Both should still have their characters
        expect(
          mainRp.runState.selectedCharacter,
          isNotNull,
          reason: 'Main should keep character through disconnect',
        );
        expect(
          sidekickRp.runState.selectedCharacter,
          isNotNull,
          reason: 'Sidekick should keep character through disconnect',
        );

        // Reconnect
        await mainSession!.reconnect();
        await sidekickSession!.reconnect();
        await Future.delayed(const Duration(milliseconds: 100));
        guestLink.simulateDiscovery();
        await Future.delayed(const Duration(milliseconds: 200));

        // Both should be connected
        expect(mainSession!.phase, MpPhase.connected);
        expect(sidekickSession!.phase, MpPhase.connected);

        // CRITICAL: both should still have selectedCharacter after reconnect
        expect(
          mainRp.runState.selectedCharacter,
          isNotNull,
          reason: 'Main selectedCharacter must survive reconnect',
        );
        expect(
          sidekickRp.runState.selectedCharacter,
          isNotNull,
          reason: 'Sidekick selectedCharacter must survive reconnect',
        );
      },
    );
  });

  group('R3 — App restart (tryRestore) preserves selectedCharacter', () {
    test('Main restart restores selectedCharacter from saved state', () async {
      await mainSession!.startAsMain(nickname: 'Host', character: marine);
      await sidekickSession!.startAsSidekick(
        nickname: 'Guest',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Force save the session state
      await MpStore.saveRunState(mainRp.runState, force: true);
      await MpStore.saveSession(
        role: MpRole.main,
        nickname: 'Host',
        character: 'The Marine',
      );

      // Simulate app kill: dispose old session, create new one
      mainSession!.dispose();
      mainSession = null;

      // Create fresh RunProvider and session (simulates app restart)
      final newRp = RunProvider();
      final newLink = FakeMpLink();
      final newSession = MpSession.withLink(newRp, newLink);

      // tryRestore should restore the saved state
      await newSession.tryRestorePersistedSession();
      await Future.delayed(const Duration(milliseconds: 50));

      // CRITICAL: selectedCharacter should be restored
      expect(
        newRp.runState.selectedCharacter,
        isNotNull,
        reason: 'Main selectedCharacter must be restored after app restart',
      );

      try {
        newSession.dispose();
      } catch (_) {}
    });

    test('Sidekick restart restores coop slot from saved character', () async {
      await mainSession!.startAsMain(nickname: 'Host', character: marine);
      await sidekickSession!.startAsSidekick(
        nickname: 'Guest',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Force save
      await MpStore.saveRunState(sidekickRp.runState, force: true);
      await MpStore.saveSession(
        role: MpRole.sidekick,
        nickname: 'Guest',
        character: 'The Cultist',
      );

      // Simulate app kill
      sidekickSession!.dispose();
      sidekickSession = null;

      // Create fresh session
      final newRp = RunProvider();
      final newLink = FakeMpLink();
      final newSession = MpSession.withLink(newRp, newLink);

      await newSession.tryRestorePersistedSession();
      await Future.delayed(const Duration(milliseconds: 50));

      // Sidekick's coop slot should have a character
      expect(
        newRp.runState.coop,
        isNotNull,
        reason: 'Sidekick coop slot must be restored after app restart',
      );
      expect(
        newRp.runState.coop!.character,
        isNotNull,
        reason: 'Sidekick coop character must be restored',
      );

      try {
        newSession.dispose();
      } catch (_) {}
    });
  });

  group('R4 — Empty character snapshot does not wipe slot', () {
    test('Empty character snapshot is skipped entirely', () async {
      await mainSession!.startAsMain(nickname: 'Host', character: marine);
      await sidekickSession!.startAsSidekick(
        nickname: 'Guest',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      final charBefore = sidekickRp.runState.selectedCharacter;
      expect(charBefore, isNotNull);

      // Send empty-character snapshot
      hostLink.sendMessage(
        const MpSnapshot(
          character: '',
          gunNames: [],
          itemNames: [],
          coolness: 0,
          curse: 0,
          shrinesUsed: [],
        ),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        sidekickRp.runState.selectedCharacter,
        charBefore,
        reason: 'Empty character snapshot should not change anything',
      );
    });
  });

  group('R5 — Cascading blank view scenario', () {
    test('P1 reconnect → P2 keeps view → P2 restart → P1 keeps view', () async {
      // This simulates the exact user-reported scenario:
      // 1. P1 reconnects → P2 gets blank view
      // 2. P2 closes/reopens → P1 gets blank view
      // With the fix, neither should get blanked.

      await mainSession!.startAsMain(nickname: 'Host', character: marine);
      await sidekickSession!.startAsSidekick(
        nickname: 'Guest',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Both have characters
      expect(mainRp.runState.selectedCharacter, isNotNull);
      expect(sidekickRp.runState.selectedCharacter, isNotNull);

      // Step 1: P1 (Main) disconnects and reconnects
      await hostLink.disconnectPeer();
      await Future.delayed(const Duration(milliseconds: 200));
      await mainSession!.reconnect();
      await sidekickSession!.reconnect();
      await Future.delayed(const Duration(milliseconds: 100));
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 200));

      // P2 (Sidekick) should NOT have blank view
      expect(
        sidekickRp.runState.selectedCharacter,
        isNotNull,
        reason: 'P2 should not get blank view after P1 reconnects',
      );

      // Step 2: P2 (Sidekick) closes app and reopens
      // Save P2's state
      await MpStore.saveRunState(sidekickRp.runState, force: true);
      await MpStore.saveSession(
        role: MpRole.sidekick,
        nickname: 'Guest',
        character: 'The Cultist',
      );

      sidekickSession!.dispose();
      sidekickSession = null;
      final newSidekickRp = RunProvider();
      final newSidekickLink = FakeMpLink();
      final newSidekickSession = MpSession.withLink(
        newSidekickRp,
        newSidekickLink,
      );

      await newSidekickSession.tryRestorePersistedSession();
      await Future.delayed(const Duration(milliseconds: 50));

      // P2 should have restored their character
      expect(
        newSidekickRp.runState.selectedCharacter,
        isNotNull,
        reason: 'P2 should restore selectedCharacter after restart',
      );

      // P1 (Main) should still have their character
      expect(
        mainRp.runState.selectedCharacter,
        isNotNull,
        reason: 'P1 should not get blank view when P2 restarts',
      );

      try {
        newSidekickSession.dispose();
      } catch (_) {}
    });
  });
}
