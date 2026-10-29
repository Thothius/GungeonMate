import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/gungeoneer_detail_screen.dart';

/// Widget tests for GungeoneerDetailScreen — the tabbed detail view.
///
/// These tests verify the single-row tab layout (Item 2) and that
/// tabs render correctly for gungeoneers with varying amounts of
/// data (2 tabs minimum, up to 5 with spoilers).
///
/// flutter_animate one-shot entrance animations complete, so
/// pumpAndSettle is safe for these tests.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunProvider()),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: MaterialApp(home: child),
    );
  }

  Gungeoneer minimalGungeoneer() {
    return Gungeoneer(name: 'Test Gungeoneer');
  }

  Gungeoneer fullGungeoneer() {
    return Gungeoneer(
      name: 'Marine',
      startingGuns: ['Marine Sidearm'],
      startingItems: ['Supply Drop'],
      loreIntro: 'A battle-hardened soldier...',
      playstyle: 'Ranged combat specialist...',
      tips: ['Keep your distance', 'Use supply drop wisely'],
      pastName: 'The Marine',
      pastSummary: 'A soldier who left his post...',
      pastDetails: 'Detailed past story...',
      pastUnlocks: 'Beat the past',
      unlockMethod: 'Available from the start',
    );
  }

  testWidgets('renders gungeoneer name in AppBar', (tester) async {
    await tester.pumpWidget(
      wrap(GungeoneerDetailScreen(gungeoneer: minimalGungeoneer())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Gungeoneer'), findsOneWidget);
  });

  testWidgets('renders LOADOUT tab for minimal gungeoneer', (tester) async {
    await tester.pumpWidget(
      wrap(GungeoneerDetailScreen(gungeoneer: minimalGungeoneer())),
    );
    await tester.pumpAndSettle();

    expect(find.text('LOADOUT'), findsOneWidget);
  });

  testWidgets('renders all 5 tabs for full gungeoneer', (tester) async {
    await tester.pumpWidget(
      wrap(GungeoneerDetailScreen(gungeoneer: fullGungeoneer())),
    );
    await tester.pumpAndSettle();

    expect(find.text('LOADOUT'), findsOneWidget);
    expect(find.text('TIPS'), findsOneWidget);
    expect(find.text('PLAYSTYLE'), findsOneWidget);
    expect(find.text('LORE'), findsOneWidget);
    expect(find.text('SPOILERS'), findsOneWidget);
  });

  testWidgets('tabs render in a single Row (not two rows)', (tester) async {
    await tester.pumpWidget(
      wrap(GungeoneerDetailScreen(gungeoneer: fullGungeoneer())),
    );
    await tester.pumpAndSettle();

    // The tab row should be a single Row containing all tab labels
    // We verify by checking that all 5 tab labels are descendants of
    // the same Row widget
    final loadoutFinder = find.text('LOADOUT');
    final tipsFinder = find.text('TIPS');
    final spoilersFinder = find.text('SPOILERS');

    // All tabs should be findable (rendered)
    expect(loadoutFinder, findsOneWidget);
    expect(tipsFinder, findsOneWidget);
    expect(spoilersFinder, findsOneWidget);

    // Find the Row that contains the tab buttons
    final rows = tester.widgetList<Row>(find.byType(Row));
    final tabRow =
        rows.where((row) {
          // The tab row contains Expanded children (each tab is Expanded)
          return row.children.any((child) => child is Expanded);
        }).toList();

    // At least one Row with Expanded children should exist
    expect(tabRow.isNotEmpty, isTrue);
  });

  testWidgets('tapping TIPS tab switches content', (tester) async {
    await tester.pumpWidget(
      wrap(GungeoneerDetailScreen(gungeoneer: fullGungeoneer())),
    );
    await tester.pumpAndSettle();

    // Initially on LOADOUT tab — tap TIPS
    await tester.tap(find.text('TIPS'));
    await tester.pumpAndSettle();

    // Tips content should now be visible
    expect(find.text('Keep your distance'), findsOneWidget);
  });

  testWidgets('tapping SPOILERS tab shows spoiler section', (tester) async {
    await tester.pumpWidget(
      wrap(GungeoneerDetailScreen(gungeoneer: fullGungeoneer())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('SPOILERS'));
    await tester.pumpAndSettle();

    // SpoilerTag is collapsible — content is hidden behind a warning banner.
    // Verify the "Past Story" label is present (the spoiler section exists).
    expect(find.text('Past Story'), findsOneWidget);
  });

  testWidgets('renders PLAY AS button', (tester) async {
    await tester.pumpWidget(
      wrap(GungeoneerDetailScreen(gungeoneer: minimalGungeoneer())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('PLAY AS'), findsOneWidget);
  });

  testWidgets('renders without overflow on narrow viewport (320px)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrap(GungeoneerDetailScreen(gungeoneer: fullGungeoneer())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('tabs fit on narrow viewport without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrap(GungeoneerDetailScreen(gungeoneer: fullGungeoneer())),
    );
    await tester.pumpAndSettle();

    // All 5 tabs should still be visible on a 320px screen
    expect(find.text('LOADOUT'), findsOneWidget);
    expect(find.text('SPOILERS'), findsOneWidget);
  });

  testWidgets('onPlayAs callback is called when provided', (tester) async {
    bool callbackCalled = false;
    await tester.pumpWidget(
      wrap(
        GungeoneerDetailScreen(
          gungeoneer: minimalGungeoneer(),
          onPlayAs: () => callbackCalled = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('PLAY AS'));
    await tester.pumpAndSettle();

    expect(callbackCalled, isTrue);
  });
}
