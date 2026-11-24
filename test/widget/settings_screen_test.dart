import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/app_data_reset.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/settings_screen.dart';
import 'package:gungeon_mate/widgets/active_run/active_run_helpers.dart';

/// Widget tests for SettingsScreen — the prefs-only settings screen.
///
/// IA split (v3.7.x): run-scoped actions (RUN TOOLS sheet, per-player
/// DATA resets) live in the active-run tools sheet. What remains:
/// a status strip, RUN DISPLAY panels (SYNERGY READOUT / DICE STYLE /
/// SPECIAL PANELS), a STUDIO shortcut, DEV TOOLS (active run only),
/// and DANGER ZONE (END RUN while a run is active + RESET ALL DATA).
///
/// The EndRunConfirmDialog has perpetual float/glow animations, so we
/// use pump() after opening it. Sections below the fold need
/// scrollUntilVisible before tapping.
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

  testWidgets('Renders status strip + run-display panels, no run-scoped cards', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Run-display panels with live summaries; dice preview renders
    // inside the (collapsed-by-default) DICE STYLE panel.
    expect(find.text('RUN DISPLAY'), findsOneWidget);
    expect(find.text('SYNERGY READOUT'), findsOneWidget);
    expect(find.text('DICE STYLE'), findsOneWidget);
    expect(find.text('SPECIAL PANELS'), findsOneWidget);
    // Live dice preview is visible without expanding anything.
    expect(find.text('5'), findsOneWidget);

    // Studio shortcut
    expect(find.text('STUDIO'), findsOneWidget);
    expect(find.text('Customization'), findsOneWidget);

    // Run-scoped actions live in the tools sheet — none render here.
    expect(find.text('Shrine Picker'), findsNothing);
    expect(find.text('Add Co-op'), findsNothing);
    expect(find.text('Save Run'), findsNothing);
    expect(find.text('MULTIPLAYER'), findsNothing);
    expect(find.text('DATA & STORAGE'), findsNothing);
    expect(find.text('Reset Player 1'), findsNothing);
  });

  testWidgets('Tapping a panel header expands it', (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('DICE STYLE'));
    await tester.pumpAndSettle();

    expect(find.text('Dice Roll'), findsOneWidget);
    expect(find.text('Roll dice for run buffs'), findsOneWidget);
  });

  testWidgets('DEV TOOLS is hidden without an active run (U-027)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    // Scroll to the bottom — DEV TOOLS must not render at all rather
    // than offering a dead-end tile.
    await tester.scrollUntilVisible(
      find.text('RESET ALL DATA'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('DEV TOOLS'), findsNothing);
    expect(find.text('Special Items & Guns'), findsNothing);
  });

  testWidgets('DEV TOOLS appears while a run is active', (tester) async {
    final p = _LoadedRunProvider();
    p.startNewRun(Gungeoneer(name: 'Marine'));

    await tester.pumpWidget(wrap(const SettingsScreen(), provider: p));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Special Items & Guns'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('DEV TOOLS'), findsOneWidget);
    expect(find.text('Special Items & Guns'), findsOneWidget);
    // Flush the run-save debounce scheduled by startNewRun.
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('RESET ALL DATA is always visible; END RUN hidden with no run', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('RESET ALL DATA'),
      100.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('DANGER ZONE'), findsOneWidget);
    expect(find.text('RESET ALL DATA'), findsOneWidget);
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
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(Dialog), findsOneWidget);
  });

  testWidgets('Tapping RESET ALL DATA opens confirmation dialog', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.text('RESET ALL DATA'));

    expect(find.text('Reset All App Data?'), findsOneWidget);
    expect(find.text('RESET ALL DATA'), findsWidgets);
    expect(find.text('Cancel'), findsWidgets);
  });

  testWidgets('Cancelling reset dialog does not navigate', (tester) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();

    await scrollAndTap(tester, find.text('RESET ALL DATA'));
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    expect(find.text('Reset All App Data?'), findsNothing);
  });

  testWidgets('Screen renders without crashing with empty provider data', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const SettingsScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsWidgets);
  });

  // ── Run tools sheet grouping (U-031) ─────────────────────────────

  testWidgets('Tools sheet groups actions RUN → RESET → DANGER', (
    tester,
  ) async {
    final p = _LoadedRunProvider();
    p.startNewRun(Gungeoneer(name: 'Marine'));

    await tester.pumpWidget(wrap(const HeaderMenu(), provider: p));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Group labels in order — the APP group was cut in the sheet
    // declutter; app-level rows live in Settings / the Paradox panel.
    expect(find.text('RUN'), findsOneWidget);
    expect(find.text('RESET'), findsOneWidget);
    expect(find.text('APP'), findsNothing);
    expect(find.text('DANGER'), findsOneWidget);

    // Representative keep-list actions with subtitles.
    expect(find.text('Shrines'), findsOneWidget);
    expect(find.text('Spend keys on blessings'), findsOneWidget);
    expect(find.text('End Run'), findsOneWidget);
    expect(find.text('Finish the run and return to menu'), findsOneWidget);
  });

  // ── resetAllAppData service (U-026) ──────────────────────────────

  test('resetAllAppData clears prefs and in-memory run state', () async {
    SharedPreferences.setMockInitialValues({
      'favourites_v1': ['Marine'],
      'haptics.intensity': 0,
      'special.gunderfury.level': 5,
    });
    final p = _LoadedRunProvider();
    p.startNewRun(Gungeoneer(name: 'Marine'));
    p.toggleFavourite('Marine');
    // Let the fire-and-forget favourites write land before the wipe.
    await Future<void>.delayed(Duration.zero);
    final session = MpSession.placeholder();

    await resetAllAppData(runProvider: p, session: session);

    final prefs = await SharedPreferences.getInstance();
    // In-flight fire-and-forget writes may re-persist empty defaults
    // after clear() — assert wiped values are gone or empty.
    final favs = prefs.getStringList('favourites_v1');
    expect(favs == null || favs.isEmpty, isTrue);
    expect(prefs.getInt('special.gunderfury.level'), isNull);
    expect(prefs.getInt('haptics.intensity'), isNull);
    expect(p.runState.main.character, isNull);
    expect(p.favouritesCount, 0);
    expect(p.gunderfuryLevel, 1);
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
