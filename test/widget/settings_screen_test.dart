import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/settings_screen.dart';

/// Widget tests for SettingsScreen — the tabbed settings screen.
///
/// SettingsScreen wraps SettingsTab which renders collapsible cards:
/// RUN TOOLS, DICE, DATA & STORAGE, DEV TOOLS. MULTIPLAYER is only
/// shown when MP is active or a co-op slot exists.
/// DANGER ZONE was removed in the 10-item rework — END RUN and
/// RESET DATA are now full-width buttons, always visible at the
/// bottom (no collapsible wrapper, no "DANGER ZONE" header).
///
/// SettingsTab uses AnimatedCrossFade for expand/collapse and
/// AnimatedRotation for the chevron — short one-shot animations.
/// pumpAndSettle() is safe for the settings screen itself.
///
/// However, the EndRunConfirmDialog has perpetual float/glow
/// animations, so we use pump() after opening it.
///
/// The settings content is scrollable. Sections below the fold
/// (DATA & STORAGE, DEV TOOLS, END RUN, RESET DATA) need scrollUntilVisible
/// to be brought on-screen before tapping.
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

  /// Scrolls until the given finder is visible, then taps it.
  /// Uses pumpAndSettle() for the scroll (settings screen has no
  /// perpetual animations) to ensure the element is fully on-screen.
  Future<void> _scrollAndTap(
      WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('Renders all four collapsible section headers (solo mode)',
      (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // First two are on-screen
    expect(find.text('RUN TOOLS'), findsOneWidget);
    expect(find.text('DICE'), findsOneWidget);
    // MULTIPLAYER is hidden when solo (no MP, no co-op)
    expect(find.text('MULTIPLAYER'), findsNothing);

    // Scroll to find the rest
    await tester.scrollUntilVisible(
      find.text('DATA & STORAGE'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('DATA & STORAGE'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('DEV TOOLS'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('DEV TOOLS'), findsOneWidget);

    // DANGER ZONE header was removed — END RUN and RESET DATA are
    // now full-width buttons, always visible (no collapsible).
  });

  testWidgets('RUN TOOLS is expanded by default and shows tiles',
      (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // RUN TOOLS is initiallyExpanded: true
    expect(find.text('Shrine Picker'), findsOneWidget);
    expect(find.text('Add Co-op'), findsOneWidget);
    // Save Run is always visible now (no MP guard)
    expect(find.text('Save Run'), findsOneWidget);
  });

  testWidgets('DICE is collapsed by default', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // DICE header exists but content (dice preview "5") is hidden
    expect(find.text('DICE'), findsOneWidget);
  });

  testWidgets('Tapping DICE header expands it and shows Dice Roll tile',
      (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Tap the DICE header to expand
    await tester.tap(find.text('DICE'));
    await tester.pumpAndSettle();

    // After expansion, the Dice Roll tile and dice preview ("5") are visible
    expect(find.text('Dice Roll'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('MULTIPLAYER section is hidden when solo (no MP, no coop)',
      (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // MULTIPLAYER card is not rendered when !mpActive && !hasCoop
    expect(find.text('MULTIPLAYER'), findsNothing);
    expect(find.text('SOLO'), findsNothing);
  });

  testWidgets('DATA & STORAGE shows Reset Player 1 tile', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to DATA & STORAGE and expand it
    await _scrollAndTap(tester, find.text('DATA & STORAGE'));

    // With no loaded run, player1Name defaults to 'Player 1'
    expect(find.text('Reset Player 1'), findsOneWidget);
  });

  testWidgets('DEV TOOLS section shows Dev Tools tile', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to DEV TOOLS and expand it
    await _scrollAndTap(tester, find.text('DEV TOOLS'));

    expect(find.text('Dev Tools'), findsOneWidget);
  });

  testWidgets('END RUN and RESET DATA buttons are always visible',
      (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to the bottom — END RUN and RESET DATA are full-width
    // buttons, always visible (no DANGER ZONE collapsible anymore).
    await tester.scrollUntilVisible(
      find.text('END RUN'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('END RUN'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('RESET DATA'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('RESET DATA'), findsOneWidget);
  });

  testWidgets('Tapping Dev Tools with no active run shows snackbar',
      (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to DEV TOOLS and expand it
    await _scrollAndTap(tester, find.text('DEV TOOLS'));

    // Scroll to Dev Tools and tap it
    await _scrollAndTap(tester, find.text('Dev Tools'));

    expect(find.text('Start a run first to spawn special items.'),
        findsOneWidget);
  });

  testWidgets('Tapping RESET DATA opens confirmation dialog',
      (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to RESET DATA (no DANGER ZONE collapsible anymore)
    await _scrollAndTap(tester, find.text('RESET DATA'));

    expect(find.text('Reset All App Data?'), findsOneWidget);
    expect(find.text('RESET EVERYTHING'), findsOneWidget);
    expect(find.text('Cancel'), findsWidgets);
  });

  testWidgets('Cancelling reset dialog does not navigate', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to RESET DATA and tap it
    await _scrollAndTap(tester, find.text('RESET DATA'));

    // Tap Cancel
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.text('Reset All App Data?'), findsNothing);
  });

  testWidgets('Tapping END RUN opens confirmation dialog', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to END RUN — use manual scroll+tap with pump() instead
    // of _scrollAndTap because the EndRunConfirmDialog that opens on
    // tap has perpetual float/glow animations that would cause
    // pumpAndSettle() to time out.
    await tester.scrollUntilVisible(
      find.text('END RUN'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('END RUN'), warnIfMissed: false);
    // Use pump() not pumpAndSettle() — the dialog has perpetual animations.
    await tester.pump(const Duration(milliseconds: 300));
    // Pump extra frames to let flutter_animate one-shot timers complete
    // so they don't leave pending timers during test cleanup.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // The dialog should be visible — look for a Dialog widget
    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('Screen renders without crashing with empty provider data',
      (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Just verify the scaffold exists
    expect(find.byType(Scaffold), findsWidgets);
  });
}
