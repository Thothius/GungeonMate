import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/character_select_screen.dart';

/// Widget tests for CharacterSelectScreen — the gungeoneer picker grid.
///
/// With an empty RunProvider (no loaded assets), allGungeoneers is
/// empty so the grid renders nothing (SizedBox.shrink). These tests
/// verify the title/subtitle/header render correctly in each mode and
/// that the empty state doesn't crash.
///
/// CharacterSelectScreen uses flutter_animate one-shot entrance
/// animations on the grid cards. With an empty grid there are no
/// animations, so pumpAndSettle is safe.
///
/// NOTE: A tall viewport (400x900) is used so ScreenProfile.isShort
/// is false (needs >700px usable height) — otherwise the description
/// text is hidden on short screens.
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

  /// Sets a tall viewport so the description text is visible.
  void _setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Solo mode renders title Gungeon Mate and subtitle',
      (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CharacterSelectScreen()));
    await tester.pumpAndSettle();

    // AppBar title
    expect(find.text('Gungeon Mate'), findsOneWidget);
    // Subtitle (unified to 'Choose Gungeoneer' by Slot 2 label cleanup)
    expect(find.text('Choose Gungeoneer'), findsOneWidget);
  });

  testWidgets('Solo mode renders description text', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CharacterSelectScreen()));
    await tester.pumpAndSettle();

    expect(
        find.text("Starts a new run with character's default loadout."),
        findsOneWidget);
  });

  testWidgets('Coop mode renders Add Co-op Player title', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(
      const CharacterSelectScreen(mode: CharSelectMode.coop),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Add Co-op Player'), findsOneWidget);
    // Subtitle unified to 'Choose Gungeoneer' for all modes
    expect(find.text('Choose Gungeoneer'), findsOneWidget);
  });

  testWidgets('Multiplayer pick mode renders Pick your Gungeoneer title',
      (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(
      const CharacterSelectScreen.multiplayerPick(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Pick your Gungeoneer'), findsOneWidget);
    // Subtitle unified to 'Choose Gungeoneer' for all modes
    expect(find.text('Choose Gungeoneer'), findsOneWidget);
  });

  testWidgets('Multiplayer pick mode hides description', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(
      const CharacterSelectScreen.multiplayerPick(),
    ));
    await tester.pumpAndSettle();

    // The description text should NOT appear in multiplayer pick mode
    expect(
        find.text("Starts a new run with character's default loadout."),
        findsNothing);
  });

  testWidgets('Empty gungeoneer list does not crash', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CharacterSelectScreen()));
    await tester.pumpAndSettle();

    // No cards rendered, but no crash either
    expect(find.byType(Card), findsNothing);
    // The divider should still be present
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('Renders a Divider between header and grid', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CharacterSelectScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('AppBar is centered', (tester) async {
    _setTallViewport(tester);
    await tester.pumpWidget(_wrap(const CharacterSelectScreen()));
    await tester.pumpAndSettle();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.centerTitle, isTrue);
  });
}
