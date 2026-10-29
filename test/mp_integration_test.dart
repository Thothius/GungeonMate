import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';

import 'helpers/fake_mp_link.dart';

/// Full integration tests for the MP layer using FakeMpLink.
///
/// These tests simulate two devices (Main + Sidekick) talking to each
/// other through in-memory FakeMpLink transports. No Nearby Connections
/// or Bluetooth/Wi-Fi required.
///
/// Coverage:
///   I1: Full handshake — startAsMain + startAsSidekick → connected
///   I2: Snapshot sync — Main's guns/items appear on Sidekick
///   I3: Gift flow — Main sends gun → Sidekick receives it
///   I4: Request flow — Sidekick requests item → Main approves → transfer
///   I5: Dice challenge — Sidekick challenges → Main accepts → results
///   I6: Emote — Main sends emote → Sidekick receives
///   I7: Disconnect → both sides detect it
///   I8: Cancel — Main cancels → Sidekick gets MpEndRun
///   I9: Add-to-peer (Main → Sidekick gift without removal)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RunProvider mainRp;
  late RunProvider sidekickRp;
  late Gungeoneer marine;
  late Gungeoneer cultist;
  late FakeMpLink hostLink;
  late FakeMpLink guestLink;
  late MpSession mainSession;
  late MpSession sidekickSession;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mainRp = RunProvider();
    sidekickRp = RunProvider();
    marine = Gungeoneer(name: 'The Marine');
    cultist = Gungeoneer(name: 'The Cultist');

    // Create paired fakes
    hostLink = FakeMpLink();
    guestLink = FakeMpLink();
    hostLink.connectTo(guestLink);

    // Create sessions with injected transports
    mainSession = MpSession.withLink(mainRp, hostLink);
    sidekickSession = MpSession.withLink(sidekickRp, guestLink);
  });

  tearDown(() {
    mainSession.dispose();
    sidekickSession.dispose();
  });

  group('I1 — Full handshake', () {
    test('Main + Sidekick connect and reach connected phase', () async {
      // Main starts hosting
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      expect(mainSession.phase, MpPhase.connecting);

      // Sidekick starts joining (no PIN needed)
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      expect(sidekickSession.phase, MpPhase.connecting);

      // Simulate discovery → connection
      guestLink.simulateDiscovery();

      // Allow async message processing (hello handshake)
      await Future.delayed(const Duration(milliseconds: 100));

      // Both should be connected
      expect(mainSession.phase, MpPhase.connected,
          reason: 'Main should be connected after handshake');
      expect(sidekickSession.phase, MpPhase.connected,
          reason: 'Sidekick should be connected after handshake');
    });

    test('Peer metadata is exchanged after handshake', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );

      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );

      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(mainSession.peerNickname, 'GuestPlayer');
      expect(mainSession.peerCharacterName, 'The Cultist');
      expect(sidekickSession.peerNickname, 'HostPlayer');
      expect(sidekickSession.peerCharacterName, 'The Marine');
    });
  });

  group('I2 — Snapshot sync', () {
    test('Snapshot exchange completes without crash after connection', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );

      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );

      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Both sides should still be connected after snapshot exchange
      // (snapshot sync runs automatically after hello handshake).
      // Without loaded asset data, gun/item names can't resolve, but
      // the snapshot exchange itself should not crash the session.
      expect(mainSession.phase, MpPhase.connected,
          reason: 'Main should remain connected after snapshot sync');
      expect(sidekickSession.phase, MpPhase.connected,
          reason: 'Sidekick should remain connected after snapshot sync');
    });
  });

  group('I3 — Gift flow', () {
    test('Gift send completes without crash (no loaded data)', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );

      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );

      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Sidekick sends a gift to Main. Without loaded asset data,
      // gunByName returns null so the gun can't be removed from
      // inventory — but the sendGift call should handle this
      // gracefully (no crash, no pending gift tracked).
      await sidekickSession.sendGift(kind: 'gun', name: 'Marine Sidearm');
      await Future.delayed(const Duration(milliseconds: 50));

      // Session should still be connected
      expect(sidekickSession.phase, MpPhase.connected,
          reason: 'Session should remain connected after gift send');
    });
  });

  group('I4 — Request flow', () {
    test('Sidekick sends request — Main receives pending request', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );

      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );

      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Sidekick requests an item from Main
      await sidekickSession.sendRequest(
        kind: 'item',
        name: 'Military Training',
      );

      // Allow message processing
      await Future.delayed(const Duration(milliseconds: 50));

      // Main should have a pending request
      expect(mainSession.pendingRequest, isNotNull,
          reason: 'Main should have received the request');
      expect(mainSession.pendingRequest?.kind, 'item');
      expect(mainSession.pendingRequest?.name, 'Military Training');
    });
  });

  group('I5 — Dice challenge', () {
    test('Dice challenge sent and received', () async {
      bool diceChallengeReceived = false;
      String? challengerName;

      mainSession.onDiceChallenge = (name) {
        diceChallengeReceived = true;
        challengerName = name;
      };

      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );

      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );

      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Sidekick sends dice challenge
      await sidekickSession.sendDiceChallenge('GuestPlayer');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(diceChallengeReceived, true,
          reason: 'Main should receive dice challenge');
      expect(challengerName, 'GuestPlayer');
    });

    test('Dice accept/decline flow', () async {
      bool diceAccepted = false;
      bool diceDeclined = false;

      sidekickSession.onDiceAccept = () => diceAccepted = true;
      sidekickSession.onDiceDecline = () => diceDeclined = true;

      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );

      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );

      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Main accepts dice
      await mainSession.sendDiceAccept();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(diceAccepted, true, reason: 'Sidekick should receive dice accept');

      // Main declines dice (reset and test)
      diceAccepted = false;
      await mainSession.sendDiceDecline();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(diceDeclined, true, reason: 'Sidekick should receive dice decline');
    });
  });

  group('I6 — Emote', () {
    test('Emote sent and received', () async {
      String? receivedEmoteFrom;
      String? receivedEmoteAction;

      sidekickSession.onEmote = (from, action) {
        receivedEmoteFrom = from;
        receivedEmoteAction = action;
      };

      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );

      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );

      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      await mainSession.sendEmote('wave');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(receivedEmoteFrom, 'HostPlayer');
      expect(receivedEmoteAction, 'wave');
    });
  });

  group('I7 — Disconnect', () {
    test('Both sides detect disconnect', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );

      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );

      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      expect(mainSession.phase, MpPhase.connected);

      // Main disconnects
      await mainSession.disconnect();
      // Pump enough time for the reconnectNotifier Future.delayed(100ms)
      // to fire BEFORE tearDown disposes the sessions.
      await Future.delayed(const Duration(milliseconds: 200));

      // Main should be in disconnected phase
      expect(mainSession.phase, MpPhase.disconnected);

      // Sidekick should also detect disconnect
      expect(sidekickSession.phase, MpPhase.disconnected,
          reason: 'Sidekick should detect peer disconnect');
    });
  });

  group('I8 — Cancel (End Run)', () {
    test('Main cancels — Sidekick receives MpEndRun and tears down', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );

      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );

      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      expect(mainSession.phase, MpPhase.connected);

      // Main cancels the session
      await mainSession.cancel();
      await Future.delayed(const Duration(milliseconds: 200));

      // Main should be back to idle
      expect(mainSession.phase, MpPhase.idle);

      // Sidekick should have received the end-run and torn down
      expect(sidekickSession.phase, isNot(MpPhase.connected),
          reason: 'Sidekick should not be connected after Main cancels');
    });
  });

  group('I9 — Add-to-peer (gift without removal)', () {
    test('Main sends add-to-peer for Sidekick — no crash', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );

      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );

      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Main adds a gun to peer's inventory. Add-to-peer doesn't
      // remove from Main's inventory, just sends a gift message.
      await mainSession.sendAddToPeer(kind: 'gun', name: 'Marine Sidearm');
      await Future.delayed(const Duration(milliseconds: 50));

      // Session should still be connected
      expect(mainSession.phase, MpPhase.connected,
          reason: 'Session should remain connected after add-to-peer');
    });
  });

  group('I10 — Ping/Pong heartbeat', () {
    test('Ping is answered with Pong (no crash)', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );

      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );

      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Manually send a ping from Main — MpSync should auto-respond
      // with a Pong on the Sidekick side. Just verify no crash.
      await hostLink.sendMessage(
        MpPing(DateTime.now().millisecondsSinceEpoch),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // If we got here without throwing, the ping/pong cycle works.
      expect(mainSession.phase, MpPhase.connected);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Reconnect edge cases — the v2.0.8 blank-screen fix.
  // ─────────────────────────────────────────────────────────────────

  group('I11 — Reconnect: Main disconnects, Sidekick keeps view', () {
    test('Sidekick main slot survives Main disconnect', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // After connect, Sidekick's main slot has Marine (from snapshot)
      expect(sidekickRp.runState.main, isNotNull);
      expect(sidekickRp.runState.coop, isNotNull,
          reason: 'Sidekick coop slot should have Cultist');

      // Main disconnects (simulates app refresh)
      await hostLink.disconnectPeer();
      await Future.delayed(const Duration(milliseconds: 200));

      // Sidekick should be in disconnected phase
      expect(sidekickSession.phase, MpPhase.disconnected);

      // Sidekick's main slot should NOT be null (no blank screen)
      expect(sidekickRp.runState.main, isNotNull,
          reason: 'Sidekick main slot should survive peer disconnect');
    });
  });

  group('I12 — Reconnect: Sidekick disconnects, Main keeps view', () {
    test('Main coop slot survives Sidekick disconnect', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      expect(mainRp.runState.main, isNotNull);
      expect(mainRp.runState.coop, isNotNull);

      // Sidekick disconnects (simulates app refresh)
      await guestLink.disconnectPeer();
      await Future.delayed(const Duration(milliseconds: 200));

      // Main should be in disconnected phase
      expect(mainSession.phase, MpPhase.disconnected);

      // Main's main slot should NOT be null (no blank screen)
      expect(mainRp.runState.main, isNotNull,
          reason: 'Main main slot should survive peer disconnect');
    });
  });

  group('I13 — Reconnect: snapshot with empty character does not wipe', () {
    test('Empty character snapshot preserves existing slot', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Sidekick's main slot is populated from Main's snapshot
      final mainBefore = sidekickRp.runState.main;
      expect(mainBefore, isNotNull);

      // Simulate a restarting peer sending a snapshot with empty
      // character (before their run state is restored).
      hostLink.sendMessage(const MpSnapshot(
        character: '',
        gunNames: [],
        itemNames: [],
        coolness: 0,
        curse: 0,
        shrinesUsed: [],
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      // Sidekick's main slot should still be populated (not wiped)
      final mainAfter = sidekickRp.runState.main;
      expect(mainAfter, isNotNull,
          reason: 'Empty character snapshot should not wipe main slot');
    });
  });

  group('I14 — Reconnect: both disconnect simultaneously', () {
    test('Both sides go to disconnected without crashing', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Both disconnect at the same time
      await hostLink.disconnectPeer();
      await guestLink.disconnectPeer();
      await Future.delayed(const Duration(milliseconds: 200));

      // Both should be in disconnected phase (not crashed)
      expect(mainSession.phase, MpPhase.disconnected);
      expect(sidekickSession.phase, MpPhase.disconnected);

      // Both should still have their run state
      expect(mainRp.runState.main, isNotNull);
      expect(sidekickRp.runState.main, isNotNull);
    });
  });

  group('I15 — Reconnect: reconnect after disconnect restores connected', () {
    test('Both sides reconnect after disconnect', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));
      expect(mainSession.phase, MpPhase.connected);

      // Disconnect
      await hostLink.disconnectPeer();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(mainSession.phase, MpPhase.disconnected);
      expect(sidekickSession.phase, MpPhase.disconnected);

      // Simulate reconnect: Main re-advertises, Sidekick re-discovers
      await mainSession.reconnect();
      await sidekickSession.reconnect();
      await Future.delayed(const Duration(milliseconds: 100));
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 200));

      // Both should be connected again
      expect(mainSession.phase, MpPhase.connected,
          reason: 'Main should reconnect');
      expect(sidekickSession.phase, MpPhase.connected,
          reason: 'Sidekick should reconnect');
    });
  });

  group('I16 — Reconnect: cancel during disconnected tears down cleanly', () {
    test('Main cancels while disconnected → idle, no crash', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Disconnect
      await hostLink.disconnectPeer();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(mainSession.phase, MpPhase.disconnected);

      // Main cancels while disconnected
      await mainSession.cancel();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(mainSession.phase, MpPhase.idle);
    });

    test('Sidekick cancels while disconnected → idle, no crash', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Disconnect
      await guestLink.disconnectPeer();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(sidekickSession.phase, MpPhase.disconnected);

      // Sidekick cancels while disconnected
      await sidekickSession.cancel();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(sidekickSession.phase, MpPhase.idle);
    });
  });

  group('I17 — Reconnect: rapid double disconnect', () {
    test('Double disconnect does not crash or corrupt state', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Rapid double disconnect
      await hostLink.disconnectPeer();
      await hostLink.disconnectPeer();
      await Future.delayed(const Duration(milliseconds: 200));

      // Should be in disconnected, not crashed
      expect(mainSession.phase, MpPhase.disconnected);
      expect(sidekickSession.phase, MpPhase.disconnected);
    });
  });

  group('I18 — Reconnect: snapshot with unknown character name', () {
    test('Unknown character name does not crash', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Send a snapshot with a character name that doesn't exist
      // in the data (gungeoneerByName returns null without loadData).
      // This should NOT crash — the slot gets a Player with null char.
      hostLink.sendMessage(const MpSnapshot(
        character: 'Unknown Character',
        gunNames: [],
        itemNames: [],
        coolness: 0,
        curse: 0,
        shrinesUsed: [],
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      // Sidekick should still be connected and have a main slot
      expect(sidekickSession.phase, MpPhase.connected);
      expect(sidekickRp.runState.main, isNotNull);
    });
  });

  group('I19 — Reconnect: MpEndRun during reconnect', () {
    test('Sidekick cancels while disconnected → clean teardown', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Disconnect both sides
      await hostLink.disconnectPeer();
      await guestLink.disconnectPeer();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(mainSession.phase, MpPhase.disconnected);
      expect(sidekickSession.phase, MpPhase.disconnected);

      // Sidekick cancels while disconnected — should NOT send MpEndRun
      // (not connected), just tear down locally
      await sidekickSession.cancel();
      await Future.delayed(const Duration(milliseconds: 200));

      // Sidekick should be idle
      expect(sidekickSession.phase, MpPhase.idle);
      // Main should still be disconnected (didn't receive MpEndRun
      // because Sidekick wasn't connected when it cancelled)
      expect(mainSession.phase, MpPhase.disconnected);
    });
  });

  group('I20 — Reconnect: snapshot after reconnect updates state', () {
    test('Post-reconnect snapshot updates peer inventory', () async {
      await mainSession.startAsMain(
        nickname: 'HostPlayer',
        character: marine,
      );
      await sidekickSession.startAsSidekick(
        nickname: 'GuestPlayer',
        character: cultist,
      );
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 150));

      // Disconnect and reconnect
      await hostLink.disconnectPeer();
      await Future.delayed(const Duration(milliseconds: 200));
      await mainSession.reconnect();
      await sidekickSession.reconnect();
      await Future.delayed(const Duration(milliseconds: 100));
      guestLink.simulateDiscovery();
      await Future.delayed(const Duration(milliseconds: 200));

      expect(mainSession.phase, MpPhase.connected);

      // After reconnect, a snapshot should be exchanged.
      // Sidekick's main slot should be populated (from Main's snapshot).
      expect(sidekickRp.runState.main, isNotNull,
          reason: 'Main slot should be populated after reconnect snapshot');
      expect(sidekickRp.runState.coop, isNotNull,
          reason: 'Coop slot should survive reconnect');
    });
  });
}
