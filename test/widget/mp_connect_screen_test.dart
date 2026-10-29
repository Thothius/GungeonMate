import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/mp_connect_screen.dart';

/// Widget tests for MpConnectScreen — the connecting/connected/error view.
///
/// Note: MpConnectScreen has a repeating pulse animation, so we use
/// `pump()` instead of `pumpAndSettle()` to avoid timeouts.
void main() {
  Widget wrapWithProviders(Widget child, {MpSession? session}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunProvider()),
        ChangeNotifierProvider(create: (_) => session ?? MpSession.placeholder()),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('Shows HOSTING title when phase is connecting (hosting)',
      (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.hosting);

    await tester.pumpWidget(wrapWithProviders(const MpConnectScreen(), session: session));
    await tester.pump();

    expect(find.text('HOSTING'), findsOneWidget);
  });

  testWidgets('Shows CONNECTING title when phase is connecting (joining)',
      (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.joining);

    await tester.pumpWidget(wrapWithProviders(const MpConnectScreen(), session: session));
    await tester.pump();

    expect(find.text('CONNECTING'), findsOneWidget);
  });

  testWidgets('Shows RECONNECTING title when reconnecting', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.reconnecting);

    await tester.pumpWidget(wrapWithProviders(const MpConnectScreen(), session: session));
    await tester.pump();

    expect(find.text('RECONNECTING'), findsOneWidget);
  });

  testWidgets('Shows error UI with message when phase is error', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.error, MpConnectReason.hosting,
        error: 'Could not find your partner.');

    await tester.pumpWidget(wrapWithProviders(const MpConnectScreen(), session: session));
    // Use pump() not pumpAndSettle() — the pulse animation repeats forever.
    await tester.pump();

    expect(find.text('Connection failed'), findsOneWidget);
    expect(find.text('Could not find your partner.'), findsOneWidget);
  });

  testWidgets('Shows Bluetooth/Wi-Fi tip in error state', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.error, MpConnectReason.hosting,
        error: 'Test error');

    await tester.pumpWidget(wrapWithProviders(const MpConnectScreen(), session: session));
    await tester.pump();

    expect(find.textContaining('Bluetooth and Wi-Fi'), findsOneWidget);
  });

  testWidgets('Shows RETRY button in error state', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.error, MpConnectReason.hosting,
        error: 'Test error');

    await tester.pumpWidget(wrapWithProviders(const MpConnectScreen(), session: session));
    await tester.pump();

    expect(find.text('RETRY'), findsOneWidget);
  });

  testWidgets('Shows back button', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.hosting);

    await tester.pumpWidget(wrapWithProviders(const MpConnectScreen(), session: session));
    await tester.pump();

    expect(find.byType(IconButton), findsOneWidget);
  });

  testWidgets('Host connecting state shows waiting message', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.hosting);

    await tester.pumpWidget(wrapWithProviders(const MpConnectScreen(), session: session));
    await tester.pump();

    expect(find.text('Waiting for a partner to join…'), findsOneWidget);
  });

  testWidgets('Joiner connecting state shows searching message', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.joining);

    await tester.pumpWidget(wrapWithProviders(const MpConnectScreen(), session: session));
    await tester.pump();

    expect(find.text('Searching for host…'), findsOneWidget);
  });

  testWidgets('Restoring state shows restore message', (tester) async {
    final session = MpSession.placeholder();
    session.setPhaseForTest(MpPhase.connecting, MpConnectReason.restoring);

    await tester.pumpWidget(wrapWithProviders(const MpConnectScreen(), session: session));
    await tester.pump();

    expect(find.text('RESTORING'), findsOneWidget);
    expect(find.text('Restoring your run…'), findsOneWidget);
  });
}
