import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/main_menu_screen.dart';
import 'package:gungeon_mate/screens/character_select_screen.dart';
import 'package:gungeon_mate/screens/codex_screen.dart';

/// Widget tests for MainMenuScreen — the opening screen with the app
/// title, subtitle, and primary action buttons (Local Run, Multiplayer,
/// Customization, Codex).
///
/// "How to Use" was removed in the 10-item rework (2026-08-25).
///
/// MainMenuScreen uses ScaleButton (spring-scale on press, not
/// perpetual) and flutter_animate one-shot entrance animations, so
/// pumpAndSettle is safe for the main screen. However, navigating to
/// CodexScreen triggers SkeletonLoader (perpetual animation), so we
/// use pump() after that navigation.
void main() {
  Widget _wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunProvider()),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('Renders app title GUNGEON MATE', (tester) async {
    await tester.pumpWidget(_wrap(const MainMenuScreen()));
    await tester.pumpAndSettle();

    expect(find.text('GUNGEON MATE'), findsWidgets);
  });

  testWidgets('Renders subtitle YOUR COMPANION IN THE GUNGEON', (tester) async {
    await tester.pumpWidget(_wrap(const MainMenuScreen()));
    await tester.pumpAndSettle();

    expect(find.text('YOUR COMPANION IN THE GUNGEON'), findsOneWidget);
  });

  testWidgets('Renders all four primary action buttons', (tester) async {
    await tester.pumpWidget(_wrap(const MainMenuScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Local Run'), findsOneWidget);
    expect(find.text('Multiplayer'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Codex'), findsOneWidget);
  });

  testWidgets('Renders version label', (tester) async {
    await tester.pumpWidget(_wrap(const MainMenuScreen()));
    await tester.pumpAndSettle();

    // Version label is "v" + kAppVersion (e.g. "v2.0.3")
    expect(find.textContaining('v'), findsWidgets);
  });

  testWidgets('Tapping Local Run navigates to CharacterSelectScreen',
      (tester) async {
    await tester.pumpWidget(_wrap(const MainMenuScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Local Run'));
    await tester.pumpAndSettle();

    expect(find.byType(CharacterSelectScreen), findsOneWidget);
  });

  testWidgets('Tapping Codex navigates to CodexScreen', (tester) async {
    await tester.pumpWidget(_wrap(const MainMenuScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Codex'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Codex'));
    // Use pump() not pumpAndSettle() — CodexScreen shows SkeletonLoader
    // which has a perpetual shimmer animation that would time out.
    await tester.pump(); // Process the tap callback
    await tester.pump(const Duration(milliseconds: 500)); // Complete route transition

    expect(find.byType(CodexScreen), findsOneWidget);
  });

}
