import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';

/// MP experience coverage — the session-level behaviors that sit
/// above the transport: pause/resume state, demo mode, the recovery
/// elapsed feed, and the message types not covered by mp_message_test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RunProvider provider;
  late MpSession session;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    provider = RunProvider();
    session = MpSession(provider);
  });

  tearDown(() {
    session.dispose();
  });

  group('Peer-gone elapsed feed (S4.2)', () {
    test('elapsed ticks update disconnectElapsedSec every feed', () {
      session.debugFeedRecoveryElapsed(0);
      expect(session.disconnectElapsedSec.value, 0);
      session.debugFeedRecoveryElapsed(45);
      expect(session.disconnectElapsedSec.value, 45);
      session.debugFeedRecoveryElapsed(90);
      expect(session.disconnectElapsedSec.value, 90);
    });
  });

  group('Pause / resume', () {
    test('pause sets pausedNotifier and notifies', () async {
      var notified = 0;
      session.addListener(() => notified++);
      await session.pause();
      expect(session.pausedNotifier.value, true);
      expect(session.isPaused, true);
      expect(notified, greaterThan(0));
    });

    test('pause is idempotent — second call is a no-op', () async {
      await session.pause();
      var notified = 0;
      session.addListener(() => notified++);
      await session.pause();
      expect(session.pausedNotifier.value, true);
      expect(notified, 0);
    });

    test('resume clears pausedNotifier', () async {
      await session.pause();
      await session.resume();
      expect(session.pausedNotifier.value, false);
      expect(session.isPaused, false);
    });

    test('resume on unpaused session is a no-op', () async {
      var notified = 0;
      session.addListener(() => notified++);
      await session.resume();
      expect(session.pausedNotifier.value, false);
      expect(notified, 0);
    });

    test('unarmed run timer stays at 0 through pause/resume', () async {
      await session.pause();
      await session.resume();
      expect(session.runElapsedMs, 0);
    });
  });

  group('Demo mode (Testing Mode)', () {
    test('enableDemo fakes a connected Paradox main session', () {
      var notified = 0;
      session.addListener(() => notified++);
      session.enableDemo();
      expect(session.demoMode, true);
      expect(session.isParadoxRun, true);
      expect(session.myRole, MpRole.main);
      expect(session.phase, MpPhase.connected);
      expect(notified, greaterThan(0));
    });

    test('pause/resume works in demo mode', () async {
      session.enableDemo();
      await session.pause();
      expect(session.isPaused, true);
      await session.resume();
      expect(session.isPaused, false);
    });
  });

  group('Message round-trips — uncovered types', () {
    test('MpSessionMeta — runTitle/sessionNumber/paused round-trip', () {
      const meta = MpSessionMeta(
        runTitle: 'Cursed Dragunfall',
        sessionNumber: 7,
        paused: true,
      );
      final decoded = MpMessage.decode(meta.encode());
      expect(decoded, isA<MpSessionMeta>());
      final m = decoded as MpSessionMeta;
      expect(m.runTitle, 'Cursed Dragunfall');
      expect(m.sessionNumber, 7);
      expect(m.paused, true);
    });

    test('MpSessionMeta — defaults round-trip', () {
      const meta = MpSessionMeta();
      final m = MpMessage.decode(meta.encode()) as MpSessionMeta;
      expect(m.runTitle, '');
      expect(m.sessionNumber, 0);
      expect(m.paused, false);
    });

    test('MpEmote — from/action round-trip', () {
      const emote = MpEmote(from: 'Pilot', action: 'slap');
      final e = MpMessage.decode(emote.encode()) as MpEmote;
      expect(e.from, 'Pilot');
      expect(e.action, 'slap');
    });

    test('MpStartRun — type decodes (empty body)', () {
      const msg = MpStartRun();
      final decoded = MpMessage.decode(msg.encode());
      expect(decoded, isA<MpStartRun>());
    });

    test('MpPause / MpResume — types decode (empty bodies)', () {
      expect(MpMessage.decode(const MpPause().encode()), isA<MpPause>());
      expect(MpMessage.decode(const MpResume().encode()), isA<MpResume>());
    });

    test('MpSharedStateDelta — deltas + shrine round-trip', () {
      const delta = MpSharedStateDelta(
        coolnessDelta: 1.5,
        curseDelta: -2,
        shrineName: 'Cleanse',
      );
      final d = MpMessage.decode(delta.encode()) as MpSharedStateDelta;
      expect(d.coolnessDelta, 1.5);
      expect(d.curseDelta, -2);
      expect(d.shrineName, 'Cleanse');
    });

    test('MpSharedStateDelta — absent shrineName round-trips', () {
      const delta = MpSharedStateDelta(coolnessDelta: 2);
      final d = MpMessage.decode(delta.encode()) as MpSharedStateDelta;
      expect(d.shrineName, isNull);
    });
  });
}
