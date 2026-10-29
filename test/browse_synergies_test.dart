import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/browse_screen.dart';
import 'package:gungeon_mate/services/mp_session.dart';

/// Browse rework — the SYNERGIES view lists guns/items that would
/// complete a synergy for the COMBINED inventories of both players.
/// Data loads in setUpAll (real async zone): inside testWidgets'
/// FakeAsync zone the compute() isolate futures never resolve.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RunProvider p;

  setUpAll(() async {
    p = RunProvider();
    await p.loadData();
  });

  Widget wrapBrowse() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: p),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: const MaterialApp(home: BrowseScreen()),
    );
  }

  Future<void> pumpFew(WidgetTester tester, [int n = 10]) async {
    // Bounded pumps — ambient animations never let pumpAndSettle finish.
    for (var i = 0; i < n; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('SYNERGIES mode lists combined-inventory candidates', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Find a 2-piece synergy whose pieces both resolve in the catalog —
    // seed one piece into the player's inventory; the other should then
    // appear as a "completes" candidate.
    final synergy = p.allSynergies.firstWhere(
      (s) =>
          s.items.length == 2 &&
          (p.allItems.any((i) => i.name == s.items[0]) ||
              p.allGuns.any((g) => g.name == s.items[0])) &&
          (p.allItems.any((i) => i.name == s.items[1]) ||
              p.allGuns.any((g) => g.name == s.items[1])),
      orElse: () => throw StateError('no 2-piece synergy in catalog'),
    );

    final ownedName = synergy.items[0];
    final candidateName = synergy.items[1];
    final ownedItem = p.allItems.where((i) => i.name == ownedName).firstOrNull;
    final ownedGun = p.allGuns.where((g) => g.name == ownedName).firstOrNull;
    if (ownedItem != null) {
      p.addItem(ownedItem, slot: PlayerSlot.main);
    } else {
      p.addGun(ownedGun!, slot: PlayerSlot.main);
    }

    await tester.pumpWidget(wrapBrowse());
    await pumpFew(tester);

    expect(find.text('SYNERGIES'), findsOneWidget);
    await tester.tap(find.text('SYNERGIES'));
    await pumpFew(tester);

    expect(find.text(candidateName), findsWidgets);
    expect(find.textContaining('COMPLETES'), findsWidgets);
  });

  testWidgets('TIERS mode filters to selected tiers only', (tester) async {
    // NOTE: browse rows overflow ~15px at ≤500px width — same narrow-
    // device issue as ParadoxBar. Testing at a wider viewport; the
    // overflow itself is tracked as a layout bug.
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sGun = p.allGuns.firstWhere(
      (g) => g.quality == 'S',
      orElse: () => throw StateError('no S-tier gun'),
    );
    final dItem = p.allItems.firstWhere(
      (i) => i.quality == 'D',
      orElse: () => throw StateError('no D-tier item'),
    );

    await tester.pumpWidget(wrapBrowse());
    await pumpFew(tester);

    await tester.tap(find.text('TIERS'));
    await pumpFew(tester);

    // The tier chip has a stable Key — 'S' text also appears inside
    // S-tier rows' quality pills, which made the old widgetWithText
    // finder ambiguous (it tapped a row and pushed the detail screen).
    final chip = find.byKey(const Key('tier_chip_S'));
    expect(chip, findsOneWidget);
    await tester.tap(chip);
    await pumpFew(tester);
    expect(find.text(sGun.name), findsWidgets);
    expect(find.text(dItem.name), findsNothing);
  });
}
