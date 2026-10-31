import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/mp_lobby_screen.dart';

/// Widget tests for MpLobbyScreen — the entry point for multiplayer.
///
/// Verifies that the screen renders the correct UI elements:
/// - Nickname text field
/// - Role toggle (MAIN / SIDEKICK)
/// - HOST GAME button (when MAIN selected)
/// - JOIN GAME button (when SIDEKICK selected)
/// - How to Play link
/// - Character preview card
///
/// Also verifies button behavior:
/// - HOST with empty nickname → toast
/// - JOIN with empty nickname → toast
void main() {
  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunProvider()),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: MaterialApp(home: child),
    );
  }

  /// Stage helpers — the lobby is a 3-stage flow:
  /// role -> gungeoneer (HOST only) -> identity.
  Future<void> settleStages(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // AnimatedSwitcher
  }

  Future<void> toIdentityViaSidekick(WidgetTester tester) async {
    await tester.tap(find.text('SIDEKICK'));
    await settleStages(tester);
  }

  Future<void> toIdentityViaHost(WidgetTester tester) async {
    await tester.tap(find.text('HOST'));
    await settleStages(tester);
    // Gungeoneer stage — CONTINUE to identity.
    await tester.tap(find.text('CONTINUE'));
    await settleStages(tester);
  }

  testWidgets('Role stage shows HOST and SIDEKICK cards, no TextField', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const MpLobbyScreen()));
    await tester.pump();

    expect(find.text('WHO ARE YOU?'), findsOneWidget);
    expect(find.text('HOST'), findsOneWidget);
    expect(find.text('SIDEKICK'), findsOneWidget);
    // Identity stage fields must NOT be visible yet.
    expect(find.byType(TextField), findsNothing);
    expect(find.text('HOST GAME'), findsNothing);
    expect(find.text('JOIN GAME'), findsNothing);
  });

  testWidgets('SIDEKICK skips gungeoneer and lands on identity stage', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const MpLobbyScreen()));
    await tester.pump();

    await toIdentityViaSidekick(tester);

    expect(find.text('IDENTITY'), findsOneWidget);
    expect(find.text('JOIN GAME'), findsOneWidget);
    expect(find.text('HOST GAME'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('HOST goes through gungeoneer stage to identity', (tester) async {
    await tester.pumpWidget(wrap(const MpLobbyScreen()));
    await tester.pump();

    await tester.tap(find.text('HOST'));
    await settleStages(tester);
    expect(find.text('PICK YOUR GUNGEONEER'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await settleStages(tester);
    expect(find.text('IDENTITY'), findsOneWidget);
    expect(find.text('HOST GAME'), findsOneWidget);
    expect(find.text('JOIN GAME'), findsNothing);
  });

  testWidgets('HOST with empty nickname shows toast', (tester) async {
    await tester.pumpWidget(wrap(const MpLobbyScreen()));
    await tester.pump();
    await toIdentityViaHost(tester);

    await tester.tap(find.text('HOST GAME'));
    await tester.pump();

    expect(find.text('Please enter a nickname.'), findsOneWidget);
  });

  testWidgets('JOIN with empty nickname shows toast', (tester) async {
    await tester.pumpWidget(wrap(const MpLobbyScreen()));
    await tester.pump();
    await toIdentityViaSidekick(tester);

    await tester.tap(find.text('JOIN GAME'));
    await tester.pump();

    expect(find.text('Please enter a nickname.'), findsOneWidget);
  });

  testWidgets('Back button on identity stage returns to role stage', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const MpLobbyScreen()));
    await tester.pump();
    await toIdentityViaSidekick(tester);
    expect(find.text('IDENTITY'), findsOneWidget);

    // AppBar back — sidekick jumps identity -> role (skips stage 1).
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await settleStages(tester);
    expect(find.text('WHO ARE YOU?'), findsOneWidget);
  });

  testWidgets('Back button on gungeoneer stage returns to role stage', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const MpLobbyScreen()));
    await tester.pump();
    await tester.tap(find.text('HOST'));
    await settleStages(tester);
    expect(find.text('PICK YOUR GUNGEONEER'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await settleStages(tester);
    expect(find.text('WHO ARE YOU?'), findsOneWidget);
  });

  testWidgets('How to Play modal opens and shows instructions', (tester) async {
    // Use phone-sized viewport so the bottom sheet doesn't overflow
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(const MpLobbyScreen()));
    await tester.pump();
    await toIdentityViaSidekick(tester);

    await tester.tap(find.text('How to Play'), warnIfMissed: false);
    await tester.pump();

    expect(find.text('HOW TO PLAY'), findsOneWidget);
    expect(find.textContaining('nickname'), findsWidgets);
  });

  testWidgets('Identity stage has exactly one TextField (no PIN)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const MpLobbyScreen()));
    await tester.pump();
    await toIdentityViaSidekick(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('HOST PIN (JOIN ONLY)'), findsNothing);
  });

  testWidgets('HOST identity stage shows optional run-title field', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const MpLobbyScreen()));
    await tester.pump();
    await toIdentityViaHost(tester);

    // Nickname + run title — the title is host-only (Sidekick gets it
    // via session meta).
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('RUN TITLE (OPTIONAL)'), findsOneWidget);
  });
}
