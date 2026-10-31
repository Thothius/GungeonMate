import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/main_menu_screen.dart';
import 'package:gungeon_mate/screens/character_select_screen.dart';
import 'package:gungeon_mate/screens/ammonomicon_screen.dart';

/// Widget tests for MainMenuScreen — the opening screen with the app
/// title, subtitle, and primary action buttons (Local Run, Multiplayer,
/// Theme, Ammonomicon).
///
/// The menu is theme-locked and its backdrop runs a perpetual ember
/// animation, so `pumpAndSettle` would never finish — all pumps here
/// use fixed durations instead (same pattern as the Ammonomicon nav
/// test, which pumps past SkeletonLoader's perpetual shimmer).
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

  /// Pump the widget tree plus enough frames for the one-shot entrance
  /// animations to complete.
  Future<void> pumpMenu(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(wrap(child));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('Renders app title GUNGEON MATE', (tester) async {
    await pumpMenu(tester, const MainMenuScreen());

    expect(find.text('GUNGEON MATE'), findsWidgets);
  });

  testWidgets('Renders subtitle YOUR COMPANION IN THE GUNGEON', (tester) async {
    await pumpMenu(tester, const MainMenuScreen());

    expect(find.text('YOUR COMPANION IN THE GUNGEON'), findsOneWidget);
  });

  testWidgets('Renders all four primary action buttons', (tester) async {
    await pumpMenu(tester, const MainMenuScreen());

    expect(find.text('Local Run'), findsOneWidget);
    expect(find.text('Multiplayer'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Ammonomicon'), findsOneWidget);
    expect(find.text('Quiz'), findsNothing);
  });

  testWidgets('Renders version label', (tester) async {
    await pumpMenu(tester, const MainMenuScreen());

    // Version label is "v" + kAppVersion (e.g. "v2.0.3")
    expect(find.textContaining('v'), findsWidgets);
  });

  testWidgets('Tapping Local Run navigates to CharacterSelectScreen', (
    tester,
  ) async {
    await pumpMenu(tester, const MainMenuScreen());

    await tester.tap(find.text('Local Run'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(CharacterSelectScreen), findsOneWidget);
  });

  testWidgets('Tapping Ammonomicon navigates to AmmonomiconScreen', (
    tester,
  ) async {
    await pumpMenu(tester, const MainMenuScreen());

    await tester.ensureVisible(find.text('Ammonomicon'));
    await tester.pump();
    await tester.tap(find.text('Ammonomicon'));
    await tester.pump(); // Process the tap callback
    await tester.pump(
      const Duration(milliseconds: 500),
    ); // Complete route transition

    expect(find.byType(AmmonomiconScreen), findsOneWidget);
  });
}
