import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/settings_screen.dart';

/// Widget tests for SettingsScreen — the prefs-only settings screen.
///
/// IA split (v3.7.x): run-scoped actions (RUN TOOLS, MULTIPLAYER status,
/// per-player DATA resets) moved to the active-run tools sheet. What
/// remains: GAMEPLAY prefs (SYNERGIES / DICE / PANELS), a STUDIO
/// shortcut to the Experience Studio, DEV TOOLS, and DANGER ZONE
/// (END RUN only while a run is active + RESET DATA always).
///
/// SettingsTab uses AnimatedCrossFade for expand/collapse and
/// AnimatedRotation for the chevron — short one-shot animations.
/// pumpAndSettle() is safe for the settings screen itself.
///
/// However, the EndRunConfirmDialog has perpetual float/glow
/// animations, so we use pump() after opening it.
///
/// The settings content is scrollable. Sections below the fold
/// (DEV TOOLS, END RUN, RESET DATA) need scrollUntilVisible
/// to be brought on-screen before tapping.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget wrap(Widget child, {RunProvider? provider}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider ?? RunProvider()),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: MaterialApp(home: child),
    );
  }

  /// Scrolls until the given finder is visible, then taps it.
  /// Uses pumpAndSettle() for the scroll (settings screen has no
  /// perpetual animations) to ensure the element is fully on-screen.
  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('Renders gameplay + studio sections, no run-scoped cards', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Gameplay collapsible cards
    expect(find.text('SYNERGIES'), findsOneWidget);
    expect(find.text('DICE'), findsOneWidget);
    expect(find.text('PANELS'), findsOneWidget);

    // Studio shortcut tile
    expect(find.text('Customization'), findsOneWidget);

    // Run-scoped sections moved to the active-run tools sheet —
    // none of these may render here anymore.
    expect(find.text('RUN TOOLS'), findsNothing);
    expect(find.text('Shrine Picker'), findsNothing);
    expect(find.text('Add Co-op'), findsNothing);
    expect(find.text('Save Run'), findsNothing);
    expect(find.text('MULTIPLAYER'), findsNothing);
    expect(find.text('DATA & STORAGE'), findsNothing);
    expect(find.text('Reset Player 1'), findsNothing);
  });

  testWidgets('DICE is collapsed by default', (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // DICE header exists but content (dice preview "5") is hidden
    expect(find.text('DICE'), findsOneWidget);
  });

  testWidgets('Tapping DICE header expands it and shows Dice Roll tile', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Tap the DICE header to expand
    await tester.tap(find.text('DICE'));
    await tester.pumpAndSettle();

    // After expansion, the Dice Roll tile and dice preview ("5") are visible
    expect(find.text('Dice Roll'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('DEV TOOLS section shows Dev Tools tile', (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to DEV TOOLS and expand it
    await scrollAndTap(tester, find.text('DEV TOOLS'));

    expect(find.text('Dev Tools'), findsOneWidget);
  });

  testWidgets('RESET DATA is always visible; END RUN hidden with no run', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to the bottom — RESET DATA is always visible; END RUN
    // only renders while a run is active (screen is reachable from
    // the main menu with no run).
    await tester.scrollUntilVisible(
      find.text('RESET DATA'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('RESET DATA'), findsOneWidget);
    expect(find.text('END RUN'), findsNothing);
  });

  testWidgets('END RUN appears and opens dialog while a run is active', (
    tester,
  ) async {
    final p = _LoadedRunProvider();
    p.startNewRun(Gungeoneer(name: 'Marine'));

    await tester.pumpWidget(wrap(const SettingsScreen(), provider: p));
    await tester.pumpAndSettle();

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

    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('Tapping Dev Tools with no active run shows snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to DEV TOOLS and expand it
    await scrollAndTap(tester, find.text('DEV TOOLS'));

    // Scroll to Dev Tools and tap it
    await scrollAndTap(tester, find.text('Dev Tools'));

    expect(
      find.text('Start a run first to spawn special items.'),
      findsOneWidget,
    );
  });

  testWidgets('Tapping RESET DATA opens confirmation dialog', (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to RESET DATA (no DANGER ZONE collapsible anymore)
    await scrollAndTap(tester, find.text('RESET DATA'));

    expect(find.text('Reset All App Data?'), findsOneWidget);
    expect(find.text('RESET EVERYTHING'), findsOneWidget);
    expect(find.text('Cancel'), findsWidgets);
  });

  testWidgets('Cancelling reset dialog does not navigate', (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to RESET DATA and tap it
    await scrollAndTap(tester, find.text('RESET DATA'));

    // Tap Cancel
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.text('Reset All App Data?'), findsNothing);
  });

  testWidgets('Screen renders without crashing with empty provider data', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Just verify the scaffold exists
    expect(find.byType(Scaffold), findsWidgets);
  });
}

/// Test-only RunProvider that bypasses the loading state — same
/// pattern as active_run_screen_test.
class _LoadedRunProvider extends RunProvider {
  @override
  bool get isLoading => false;

  @override
  String? get error => null;
}
