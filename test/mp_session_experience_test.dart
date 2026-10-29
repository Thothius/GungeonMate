import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';

/// MP experience coverage — the session-level behaviors that sit
/// above the transport: the unified MpEvent activity log, chat
/// queue/history, pause/resume state, demo mode, and the message
/// types not covered by mp_message_test.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late RunProvider provider;
  late MpSession session;

  setUp(() {
    provider = RunProvider();
    session = MpSession(provider);
  });

  tearDown(() {
    session.dispose();
  });

  group('MpEvent + sessionEvents log', () {
    test('logEvent appends and notifies listeners', () {
      var notified = 0;
      session.addListener(() => notified++);
      session.logEvent(
        MpEvent.event(kind: 'system', from: 'Sys', text: 'hi', mine: false),
      );
      expect(session.sessionEvents.length, 1);
      expect(session.sessionEvents.first.kind, 'system');
      expect(session.sessionEvents.first.text, 'hi');
      expect(session.sessionEvents.first.mine, false);
      expect(notified, greaterThan(0));
    });

    test('logEvent caps history at 150 entries (oldest evicted)', () {
      for (var i = 0; i < 160; i++) {
        session.logEvent(MpEvent.chat(from: 'P', text: 'msg $i', mine: true));
      }
      expect(session.sessionEvents.length, 150);
      // First ten should have been evicted — oldest is 'msg 10'.
      expect(session.sessionEvents.first.text, 'msg 10');
      expect(session.sessionEvents.last.text, 'msg 159');
    });

    test('MpEvent.chat factory produces chat kind with mine flag', () {
      final e = MpEvent.chat(from: 'Buddy', text: 'hello', mine: false);
      expect(e.kind, 'chat');
      expect(e.from, 'Buddy');
      expect(e.text, 'hello');
      expect(e.mine, false);
      expect(e.ts, isNotNull);
    });

    test('MpEvent.event factory produces arbitrary kinds', () {
      final e = MpEvent.event(
        kind: 'transfer',
        from: 'Me',
        text: 'Gun → Pal',
        mine: true,
      );
      expect(e.kind, 'transfer');
      expect(e.mine, true);
    });
  });

  group('sendChatMessage', () {
    test('empty and whitespace-only text is ignored', () async {
      await session.sendChatMessage('');
      await session.sendChatMessage('   ');
      await session.sendChatMessage('\n\t ');
      expect(session.chatMessages, isEmpty);
      expect(session.sessionEvents, isEmpty);
    });

    test('valid message appends to chatMessages + logs event', () async {
      await session.sendChatMessage(' gg noob ');
      expect(session.chatMessages.length, 1);
      expect(session.chatMessages.first.text, ' gg noob '.trim());
      expect(session.sessionEvents.length, 1);
      expect(session.sessionEvents.first.kind, 'chat');
      expect(session.sessionEvents.first.mine, true);
    });

    test('onChatMessage callback fires with mine=true', () async {
      MpChat? received;
      bool? wasMine;
      session.onChatMessage = (msg, mine) {
        received = msg;
        wasMine = mine;
      };
      await session.sendChatMessage('hello peer');
      expect(received, isNotNull);
      expect(wasMine, true);
      expect(received!.text, 'hello peer');
    });

    test('disconnected send queues instead of dropping', () async {
      // No transport — isConnected is false. The message must be
      // queued for reconnect flush, not silently dropped: it lands
      // in chatMessages and is logged as a sent event.
      await session.sendChatMessage('queued line');
      expect(session.chatMessages.single.text, 'queued line');
      expect(session.sessionEvents.single.text, 'queued line');
    });

    test('chatMessages caps at 200 entries', () async {
      for (var i = 0; i < 210; i++) {
        await session.sendChatMessage('line $i');
      }
      expect(session.chatMessages.length, 200);
      expect(session.chatMessages.first.text, 'line 10');
    });
  });

  group('sendEmote / sendSurprise event logging', () {
    test('sendEmote logs an emote event even disconnected', () async {
      await session.sendEmote('kiss');
      expect(session.sessionEvents.single.kind, 'emote');
      expect(session.sessionEvents.single.text, 'kiss');
      expect(session.sessionEvents.single.mine, true);
    });

    test('sendSurprise early-returns when not connected (no event)', () async {
      await session.sendSurprise(preset: 'poke', text: 'boop');
      // Guard: if (!_link.isConnected) return — runs BEFORE logEvent.
      expect(session.sessionEvents, isEmpty);
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
      expect(session.mode, MpMode.paradox);
      expect(session.myRole, MpRole.main);
      expect(session.phase, MpPhase.connected);
      expect(notified, greaterThan(0));
    });

    test('demo session accepts chat (events + messages append)', () async {
      session.enableDemo();
      await session.sendChatMessage('demo chat');
      expect(session.chatMessages.single.text, 'demo chat');
      expect(session.sessionEvents.single.kind, 'chat');
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
