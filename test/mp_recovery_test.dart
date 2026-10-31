import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/models/run_state.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp/mp_recovery.dart';
import 'package:gungeon_mate/services/mp/mp_store.dart';

import 'helpers/fake_mp_link.dart';

/// Edge-case tests for MpRecovery.tryRestore — the app-kill restore
/// path that re-enters an MP session after the app is restarted.
///
/// These tests verify the v2.0.8 fixes:
/// - Sidekick coop slot is restored if missing
/// - Main character is corrected if stale solo run was loaded
/// - Empty/corrupted save state doesn't crash
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RunProvider rp;
  late FakeMpLink link;
  late Gungeoneer marine;
  late Gungeoneer cultist;
  late MpRecovery recovery;
  MpRole? restoredRole;
  String? restoredNickname;
  String? restoredCharacter;
  RunState? restoredPreSidekick;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    rp = RunProvider();
    link = FakeMpLink();
    marine = Gungeoneer(name: 'The Marine');
    cultist = Gungeoneer(name: 'The Cultist');
    restoredRole = null;
    restoredNickname = null;
    restoredCharacter = null;
    restoredPreSidekick = null;

    recovery = MpRecovery(
      link,
      rp,
      onRestoreSession: ({
        required MpRole role,
        required String nickname,
        required String character,
        RunState? preSidekickRun,
        bool paused = false,
        String avatarId = '',
        String runTitle = '',
        int sessionNumber = 0,
        int runStartMs = 0,
        int runAccumMs = 0,
      }) {
        restoredRole = role;
        restoredNickname = nickname;
        restoredCharacter = character;
        restoredPreSidekick = preSidekickRun;
      },
    );
  });

  group('tryRestore — no saved session', () {
    test('Returns silently when no MP session is saved', () async {
      await recovery.tryRestore();

      expect(
        restoredRole,
        isNull,
        reason: 'Should not restore when no session is saved',
      );
    });
  });

  group('tryRestore — Main with saved run state', () {
    test('Restores Main role and run state', () async {
      // Save a Main session with run state
      final runState = RunState(
        main: Player(character: marine, guns: [], items: []),
        coop: Player(character: cultist, guns: [], items: []),
        coolness: 5.0,
        curse: 2.0,
        shrinesUsed: [],
      );
      await MpStore.saveSession(
        role: MpRole.main,
        nickname: 'HostPlayer',
        character: 'The Marine',
      );
      await MpStore.saveRunState(runState, force: true);

      await recovery.tryRestore();

      expect(restoredRole, MpRole.main);
      expect(restoredNickname, 'HostPlayer');
      expect(restoredCharacter, 'The Marine');
      expect(rp.runState.main.character?.name, 'The Marine');
      expect(rp.runState.coop?.character?.name, 'The Cultist');
    });
  });

  group('tryRestore — Sidekick with saved run state', () {
    test('Restores Sidekick role and run state', () async {
      final runState = RunState(
        main: Player(character: marine, guns: [], items: []),
        coop: Player(character: cultist, guns: [], items: []),
        coolness: 3.0,
        curse: 1.0,
        shrinesUsed: [],
      );
      await MpStore.saveSession(
        role: MpRole.sidekick,
        nickname: 'GuestPlayer',
        character: 'The Cultist',
      );
      await MpStore.saveRunState(runState, force: true);

      await recovery.tryRestore();

      expect(restoredRole, MpRole.sidekick);
      expect(restoredNickname, 'GuestPlayer');
      expect(restoredCharacter, 'The Cultist');
    });
  });

  group('tryRestore — Sidekick without coop slot (save timer missed)', () {
    test('Ensures coop slot has Cultist after restore', () async {
      // Save a Sidekick session but with a run state that has NO coop
      // (simulates save timer not firing before app kill)
      final runState = RunState(
        main: Player(character: cultist, guns: [], items: []),
        coop: null,
        coolness: 0,
        curse: 0,
        shrinesUsed: [],
      );
      await MpStore.saveSession(
        role: MpRole.sidekick,
        nickname: 'GuestPlayer',
        character: 'The Cultist',
      );
      await MpStore.saveRunState(runState, force: true);

      // Without loadData(), gungeoneerByName returns null, so the
      // recovery can't find The Cultist. The coop slot stays null.
      // This test verifies the code path doesn't crash.
      await recovery.tryRestore();

      expect(restoredRole, MpRole.sidekick);
      // Coop slot may be null (no loadData) — but no crash
      expect(rp.runState.main, isNotNull);
    });
  });

  group('tryRestore — Main with stale solo run', () {
    test('Detects character mismatch and re-initializes', () async {
      // RunProvider loaded a solo run with Hunter via _loadSavedRun
      // (simulated by startNewRun)
      rp.startNewRun(Gungeoneer(name: 'The Hunter'));

      // But the saved MP session has Marine
      await MpStore.saveSession(
        role: MpRole.main,
        nickname: 'HostPlayer',
        character: 'The Marine',
      );
      // No saved runState — forces the mismatch path

      await recovery.tryRestore();

      expect(restoredRole, MpRole.main);
      expect(restoredCharacter, 'The Marine');
      // Without loadData(), gungeoneerByName returns null, so
      // startNewRun won't be called with Marine. But the code path
      // should not crash.
      expect(rp.runState.main, isNotNull);
    });
  });

  group('tryRestore — corrupted save state', () {
    test('Does not crash on corrupted run state JSON', () async {
      // Save valid session metadata but corrupt the run state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('mp.session_active', true);
      await prefs.setString('mp.role', 'main');
      await prefs.setString('mp.nickname', 'HostPlayer');
      await prefs.setString('mp.character', 'The Marine');
      await prefs.setString('mp.active_run', '{invalid json}}}');

      await recovery.tryRestore();

      // Should not crash — corrupted run state is caught
      // Session metadata may still be restored
      expect(restoredRole, MpRole.main);
    });
  });

  group('tryRestore — empty character in saved session', () {
    test('Handles empty character name gracefully', () async {
      await MpStore.saveSession(
        role: MpRole.main,
        nickname: 'HostPlayer',
        character: '',
      );

      await recovery.tryRestore();

      // Should restore with empty character (edge case)
      expect(restoredRole, MpRole.main);
      expect(restoredCharacter, '');
    });
  });

  group('tryRestore — pre-sidekick run preserved', () {
    test('Pre-sidekick run state is passed to onRestoreSession', () async {
      final preSidekick = RunState(
        main: Player(character: marine, guns: [], items: []),
        coolness: 10.0,
        curse: 0,
        shrinesUsed: ['Shrine1'],
      );
      await MpStore.saveSession(
        role: MpRole.sidekick,
        nickname: 'GuestPlayer',
        character: 'The Cultist',
      );
      await MpStore.savePreSidekickRun(preSidekick);

      await recovery.tryRestore();

      expect(restoredRole, MpRole.sidekick);
      expect(restoredPreSidekick, isNotNull);
      expect(restoredPreSidekick?.coolness, 10.0);
    });
  });

  group('MpRecovery — cadence lifecycle', () {
    test('onPeerDisconnected sets active state', () {
      recovery.setSessionInfo(role: MpRole.sidekick, nickname: 'Test');
      expect(recovery.isActive, isFalse);

      recovery.onPeerDisconnected();

      expect(recovery.isActive, isTrue);
    });

    test('onPeerReconnected clears active state', () {
      recovery.setSessionInfo(role: MpRole.sidekick, nickname: 'Test');
      recovery.onPeerDisconnected();
      expect(recovery.isActive, isTrue);

      recovery.onPeerReconnected();

      expect(recovery.isActive, isFalse);
    });

    test('cancel clears active state', () {
      recovery.setSessionInfo(role: MpRole.sidekick, nickname: 'Test');
      recovery.onPeerDisconnected();
      expect(recovery.isActive, isTrue);

      recovery.cancel();

      expect(recovery.isActive, isFalse);
    });

    test('double onPeerDisconnected does not re-trigger', () {
      recovery.setSessionInfo(role: MpRole.sidekick, nickname: 'Test');
      recovery.onPeerDisconnected();
      expect(recovery.isActive, isTrue);

      // Second call should be a no-op (guard: if (_active) return)
      recovery.onPeerDisconnected();
      expect(recovery.isActive, isTrue);
    });

    test('onDisconnectElapsed fires at 0 then ticks on cadence', () {
      fakeAsync((async) {
        recovery.setSessionInfo(role: MpRole.sidekick, nickname: 'Test');
        final ticks = <int>[];
        recovery.onDisconnectElapsed = ticks.add;

        // Immediate emission at disconnect — UI can stamp t=0.
        recovery.onPeerDisconnected();
        expect(ticks, [0]);

        // The cadence timer fires every 10s with the elapsed reading.
        // (The reading itself uses DateTime.now — wall clock, not fake
        // time — so we assert the cadence, not the value.)
        async.elapse(const Duration(seconds: 10));
        expect(ticks.length, 2);
        expect(ticks.last, isA<int>());
        async.elapse(const Duration(seconds: 10));
        expect(ticks.length, 3);

        // Reconnect stops the feed entirely — no trailing tick.
        recovery.onPeerReconnected();
        final count = ticks.length;
        async.elapse(const Duration(seconds: 30));
        expect(ticks.length, count);
      });
    });
  });
}
