import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/mp_reconnect_banner.dart';
import '../helpers/fake_mp_link.dart';

/// S4.3 — reconnect UX states a user actually sees:
/// modal on drop (when ParadoxBar isn't covering), persistent banner
/// after dismiss, elapsed escalation, reopen-on-tap, cancel, and the
/// success path. Driven through the real notifiers + setPhaseForTest.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  (MpSession, RunProvider) makeSession() {
    final rp = RunProvider();
    return (MpSession.withLink(rp, FakeMpLink()), rp);
  }

  Widget wrap(MpSession session, RunProvider rp, {required bool runBar}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: session),
        ChangeNotifierProvider.value(value: rp),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MpReconnectBanner(
            runBarVisible: runBar,
            child: const Center(child: Text('body')),
          ),
        ),
      ),
    );
  }

  void dropPeer(MpSession s) {
    s.setPhaseForTest(MpPhase.disconnected, MpConnectReason.reconnecting);
    s.reconnectNotifier.value = true;
  }

  testWidgets('bar on screen → no modal, no banner (ParadoxBar owns it)', (
    t,
  ) async {
    final (s, rp) = makeSession();
    await t.pumpWidget(wrap(s, rp, runBar: true));
    await t.pump();

    dropPeer(s);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    expect(find.text('Connection lost'), findsNothing);
    expect(find.textContaining('Reconnecting…'), findsNothing);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('bar off screen → modal fires, dismiss → persistent banner', (
    t,
  ) async {
    final (s, rp) = makeSession();
    await t.pumpWidget(wrap(s, rp, runBar: false));
    await t.pump();

    dropPeer(s);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));

    // Modal dialog with both actions.
    expect(find.text('Connection lost'), findsOneWidget);
    expect(find.text('DISMISS'), findsOneWidget);
    expect(find.text('CANCEL RUN'), findsOneWidget);

    // Dismiss → dialog gone, persistent banner remains.
    await t.tap(find.text('DISMISS'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Connection lost'), findsNothing);
    expect(find.textContaining('Reconnecting…'), findsOneWidget);

    // Elapsed past 2min → escalation copy.
    s.disconnectElapsedSec.value = 150;
    await t.pump();
    expect(find.textContaining('partner may have left'), findsOneWidget);

    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('banner tap reopens the dialog', (t) async {
    final (s, rp) = makeSession();
    await t.pumpWidget(wrap(s, rp, runBar: false));
    await t.pump();

    dropPeer(s);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('DISMISS'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Connection lost'), findsNothing);

    await t.tap(find.textContaining('Reconnecting…'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Connection lost'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('banner X cancels the session', (t) async {
    final (s, rp) = makeSession();
    await t.pumpWidget(wrap(s, rp, runBar: false));
    await t.pump();

    dropPeer(s);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.text('DISMISS'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    // The banner's close icon — last IconButton-ish in the banner row.
    await t.tap(find.byIcon(Icons.close_rounded));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    // cancel() ran → phase leaves disconnected → banner gone.
    expect(find.textContaining('Reconnecting…'), findsNothing);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('reconnect success closes dialog + snackbar', (t) async {
    final (s, rp) = makeSession();
    await t.pumpWidget(wrap(s, rp, runBar: false));
    await t.pump();

    dropPeer(s);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('Connection lost'), findsOneWidget);

    s.reconnectSuccessNotifier.value = true;
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Connection lost'), findsNothing);
    expect(find.text('Connected again'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('no banner while phase is connected', (t) async {
    final (s, rp) = makeSession();
    s.setPhaseForTest(MpPhase.connected, MpConnectReason.hosting);
    await t.pumpWidget(wrap(s, rp, runBar: false));
    await t.pump();
    expect(find.textContaining('Reconnecting…'), findsNothing);
    await t.pump(const Duration(seconds: 1));
  });
}
