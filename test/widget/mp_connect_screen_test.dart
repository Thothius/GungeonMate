import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/multiplayer_messages.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/mp_connect_screen.dart';

import '../helpers/fake_mp_link.dart';

/// Widget tests for MpConnectScreen — the connecting/connected/error view.
///
/// Note: MpConnectScreen has a repeating pulse animation, so we use
/// `pump()` instead of `pumpAndSettle()` to avoid timeouts.
void main() {
  Widget wrapWithProviders(Widget child, {MpSession? session}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunProvider()),
        ChangeNotifierProvider(
          create: (_) => session ?? MpSession.placeholder(),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  /// Session backed by a connected FakeMpLink pair — sendStartRun
  /// actually delivers instead of hitting the not-connected guard.
  (MpSession, RunProvider) connectedSession() {
    final rp = RunProvider();
    final host = FakeMpLink();
    final guest = FakeMpLink();
    host.connectTo(guest);
    host.forceConnect();
    return (MpSession.withLink(rp, host), rp);
  }

  Widget wrapWithRp(Widget child, RunProvider rp, MpSession session) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: rp),
        ChangeNotifierProvider.value(value: session),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('Shows HOSTING title when phase is connecting (hosting)', (
    tester,
  ) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.hosting);

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();

    expect(find.text('HOSTING'), findsOneWidget);
  });

  testWidgets('Shows CONNECTING title when phase is connecting (joining)', (
    tester,
  ) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.joining);

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();

    expect(find.text('CONNECTING'), findsOneWidget);
  });

  testWidgets('Shows RECONNECTING title when reconnecting', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.reconnecting);

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();

    expect(find.text('RECONNECTING'), findsOneWidget);
  });

  testWidgets('Shows error UI with message when phase is error', (
    tester,
  ) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(
      MpPhase.error,
      MpConnectReason.hosting,
      error: 'Could not find your partner.',
    );

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    // Use pump() not pumpAndSettle() — the pulse animation repeats forever.
    await tester.pump();

    expect(find.text('Connection failed'), findsOneWidget);
    expect(find.text('Could not find your partner.'), findsOneWidget);
  });

  testWidgets('Shows Bluetooth/Wi-Fi tip in error state', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(
      MpPhase.error,
      MpConnectReason.hosting,
      error: 'Test error',
    );

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();

    expect(find.textContaining('Bluetooth and Wi-Fi'), findsOneWidget);
  });

  testWidgets('Shows RETRY button in error state', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(
      MpPhase.error,
      MpConnectReason.hosting,
      error: 'Test error',
    );

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();

    expect(find.text('RETRY'), findsOneWidget);
  });

  testWidgets('Shows back button', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.hosting);

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();

    // Back moved to the shared bottom bar (task 17 sweep) — arrow icon
    // inside the OutlinedButton, not an IconButton.
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('Host connecting state shows waiting message', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.hosting);

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();

    expect(find.text('Waiting for a partner to join…'), findsOneWidget);
  });

  testWidgets('Joiner connecting state shows searching message', (
    tester,
  ) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.joining);

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();

    expect(find.text('Searching for host…'), findsOneWidget);
  });

  testWidgets('Restoring state shows restore message', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.restoring);

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();

    expect(find.text('RESTORING'), findsOneWidget);
    expect(find.text('Restoring your run…'), findsOneWidget);
  });

  // ── VS splash + final handshake (S5) ───────────────────────────

  testWidgets('Main sees VS splash with READY button on fresh connect', (
    tester,
  ) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(
      MpPhase.connected,
      MpConnectReason.hosting,
      role: MpRole.main,
      nickname: 'Hosty',
      peerNickname: 'Sidekick',
    );

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('LINKED'), findsOneWidget);
    expect(find.text('VS'), findsOneWidget);
    expect(find.textContaining('READY'), findsOneWidget);
  });

  testWidgets('READY tap flips to STARTING and fires sendStartRun', (
    tester,
  ) async {
    final (session, rp) = connectedSession();
    session.setPhaseForTest(
      MpPhase.connected,
      MpConnectReason.hosting,
      role: MpRole.main,
      nickname: 'Hosty',
      peerNickname: 'Sidekick',
    );

    await tester.pumpWidget(
      wrapWithRp(const MpConnectScreen(), rp, session),
    );
    await tester.pump();

    await tester.tap(find.textContaining('READY'));
    await tester.pump();
    // Flush the 600ms enter-run delay so no Timer leaks past teardown.
    await tester.pump(const Duration(milliseconds: 800));

    // Confirmed → handshake resolves → entering beat replaces READY.
    expect(find.textContaining('ENTERING THE GUNGEON'), findsOneWidget);
    expect(find.textContaining('READY'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('READY failure reverts the button — no silent desync', (
    tester,
  ) async {
    // Placeholder session's real MpLink is never connected —
    // sendStartRun returns false and READY must re-enable.
    final session = MpSession.placeholder();
    session.setPhaseForTest(
      MpPhase.connected,
      MpConnectReason.hosting,
      role: MpRole.main,
      nickname: 'Hosty',
      peerNickname: 'Sidekick',
    );

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();

    await tester.tap(find.textContaining('READY'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('READY'), findsOneWidget);
    expect(find.textContaining('STARTING'), findsNothing);
    expect(find.textContaining('ENTERING THE GUNGEON'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MpStartRun latched before mount — sidekick still enters', (
    tester,
  ) async {
    final (session, rp) = connectedSession();
    session.setPhaseForTest(
      MpPhase.connected,
      MpConnectReason.joining,
      role: MpRole.sidekick,
      nickname: 'Sidekick',
      peerNickname: 'Hosty',
    );
    // The wire message landed before initState could register
    // onStartRun — the session-level latch must carry it.
    session.debugReceiveStartRun();

    await tester.pumpWidget(
      wrapWithRp(const MpConnectScreen(), rp, session),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.textContaining('WAITING FOR'), findsNothing);
    expect(find.textContaining('ENTERING THE GUNGEON'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sidekick watchdog surfaces escape hint after 25s', (
    tester,
  ) async {
    final (session, rp) = connectedSession();
    session.setPhaseForTest(
      MpPhase.connected,
      MpConnectReason.joining,
      role: MpRole.sidekick,
      nickname: 'Sidekick',
      peerNickname: 'Hosty',
    );

    await tester.pumpWidget(
      wrapWithRp(const MpConnectScreen(), rp, session),
    );
    await tester.pump();
    expect(find.textContaining('The host confirms'), findsOneWidget);

    await tester.pump(const Duration(seconds: 26));
    expect(find.textContaining('Taking long?'), findsOneWidget);

    // A late MpStartRun still resolves the wait — hint state is
    // cosmetic only.
    session.debugReceiveStartRun();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('System back cancels the session and pops', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final (session, rp) = connectedSession();
    session.setPhaseForTest(
      MpPhase.connected,
      MpConnectReason.hosting,
      role: MpRole.main,
      nickname: 'Hosty',
      peerNickname: 'Sidekick',
    );

    await tester.pumpWidget(
      wrapWithRp(const MpConnectScreen(), rp, session),
    );
    await tester.pump();

    // Android system back → PopScope.onPopInvokedWithResult.
    await tester.binding.handlePopRoute();
    // cancel() is async (prefs + transport teardown) — flush it.
    for (var i = 0; i < 8; i++) {
      await tester.pump();
    }
    // cancel() → endCoopPlayer schedules a 400ms save debounce —
    // flush it so no Timer leaks past teardown.
    await tester.pump(const Duration(milliseconds: 600));

    expect(session.phase, MpPhase.idle);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sidekick sees WAITING FOR host on fresh connect', (
    tester,
  ) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(
      MpPhase.connected,
      MpConnectReason.joining,
      role: MpRole.sidekick,
      nickname: 'Sidekick',
      peerNickname: 'Hosty',
    );

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('WAITING FOR'), findsOneWidget);
    expect(find.textContaining('HOSTY'), findsOneWidget);
    expect(find.textContaining('READY'), findsNothing);
  });

  testWidgets('Sidekick enters run when peer startRun arrives', (
    tester,
  ) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(
      MpPhase.connected,
      MpConnectReason.joining,
      role: MpRole.sidekick,
      nickname: 'Sidekick',
      peerNickname: 'Hosty',
    );

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();
    expect(find.textContaining('WAITING FOR'), findsOneWidget);

    // Simulate the wire MpStartRun → onStartRun callback.
    session.onStartRun?.call();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Reconnect skips the handshake — no READY button', (
    tester,
  ) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(
      MpPhase.connected,
      MpConnectReason.reconnecting,
      role: MpRole.main,
      nickname: 'Hosty',
      peerNickname: 'Sidekick',
    );

    await tester.pumpWidget(
      wrapWithProviders(const MpConnectScreen(), session: session),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    // Auto-entered — entering beat shows, no handshake UI remains.
    expect(find.textContaining('ENTERING THE GUNGEON'), findsOneWidget);
    expect(find.textContaining('READY'), findsNothing);
    expect(find.textContaining('WAITING FOR'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
