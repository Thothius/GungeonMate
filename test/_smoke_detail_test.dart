import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/screens/item_detail_screen.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/item_detail/gun_synergies_tab.dart';

void main() {
  late RunProvider p;
  setUpAll(() async {
    p = RunProvider();
    await p.loadData();
  });

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: p),
      ChangeNotifierProvider(create: (_) => MpSession(p)),
    ],
    child: MaterialApp(home: child),
  );

  testWidgets('detail renders body for a gun', (t) async {
    await t.pumpWidget(wrap(ItemDetailScreen(gun: p.allGuns.first)));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.byType(CustomScrollView), findsOneWidget);
    // The scrollable must have real height — the original bug was a
    // Center+ConstrainedBox wrapper collapsing it to zero.
    final size = t.getSize(find.byType(CustomScrollView));
    expect(size.height, greaterThan(100));
    expect(size.width, greaterThan(100));
  });
  testWidgets('detail renders body for an item', (t) async {
    await t.pumpWidget(wrap(ItemDetailScreen(item: p.allItems.first)));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.byType(CustomScrollView), findsOneWidget);
    // The scrollable must have real height — the original bug was a
    // Center+ConstrainedBox wrapper collapsing it to zero.
    final size = t.getSize(find.byType(CustomScrollView));
    expect(size.height, greaterThan(100));
    expect(size.width, greaterThan(100));
  });

  // ── Gun flat rework — stats, then collapsible SYN/NOTES/REFS tabs,
  // all closed by default ──
  testWidgets('gun detail shows SYN/NOTES/REFS tabs, all closed', (t) async {
    await t.pumpWidget(wrap(ItemDetailScreen(gun: p.allGuns.first)));
    await t.pump();
    expect(t.takeException(), isNull);
    // Tab headers sit below the stats block — scroll them into view.
    await t.scrollUntilVisible(
      find.text('REFS'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await t.pump();
    // Tab headers are visible; the old always-open sections are not.
    for (final label in ['SYN', 'NOTES', 'REFS']) {
      expect(find.text(label), findsWidgets, reason: 'missing $label');
    }
    expect(find.text('STATS'), findsNothing);
    expect(find.text('SYNERGIES'), findsNothing);
    // Closed by default — no synergy content rendered yet.
    expect(find.textContaining('LICH'), findsNothing);
  });

  /// Scroll to a detail tab header and expand it.
  Future<void> openDetailTab(WidgetTester t, String label) async {
    await t.scrollUntilVisible(
      find.text(label),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 30,
    );
    await t.pump();
    await t.tap(find.text(label));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('STATS tab is the default and shows hero stats', (t) async {
    // Pick a gun guaranteed to have the hero stats.
    final gun = p.allGuns.firstWhere(
      (g) => g.range.isNotEmpty || g.spread.isNotEmpty || g.force.isNotEmpty,
      orElse: () => p.allGuns.first,
    );
    await t.pumpWidget(wrap(ItemDetailScreen(gun: gun)));
    await t.pump();
    expect(t.takeException(), isNull);
    // Stat grid — uniform label-over-number cells (DPS leads).
    final heroFound = [
      'DPS',
      'RANGE',
      'SPREAD',
      'FORCE',
      'DAMAGE',
    ].any((l) => find.text(l).evaluate().isNotEmpty);
    expect(heroFound, true);
  });

  testWidgets('notes render at the bottom of the flat scroll', (t) async {
    final gun = p.allGuns.firstWhere(
      (g) => g.notes.isNotEmpty,
      orElse: () => p.allGuns.first,
    );
    await t.pumpWidget(wrap(ItemDetailScreen(gun: gun)));
    await t.pump();
    await openDetailTab(t, 'NOTES');
    await t.scrollUntilVisible(find.text('EFFECT'), 400);
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text('EFFECT'), findsOneWidget);
  });

  testWidgets('synergies render inside the SYN tab', (t) async {
    await t.pumpWidget(wrap(ItemDetailScreen(gun: p.allGuns.first)));
    await t.pump();
    await openDetailTab(t, 'SYN');
    // LEB mode is the default — every gun lists all its synergies as
    // simulated rows. '38 Special' has 4 synergies in the catalog.
    await t.scrollUntilVisible(
      find.textContaining('LICH'),
      400,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    await t.pump();
    expect(t.takeException(), isNull);
    // Ghost rows skip LEB-excluded (dual-wield etc.) and 3+-piece
    // synergies — assert on the first one that does render.
    final gun = p.allGuns.first;
    final rendered = p
        .getSynergiesFor(gun.name)
        .firstWhere(
          (s) =>
              !isLebExcludedSynergy(s) && !lebNeedsRealPieces(s),
        );
    expect(find.text(rendered.name), findsOneWidget);
  });

  testWidgets('gun detail lists locked synergies when LEB toggle is off', (
    t,
  ) async {
    await VisualPrefs.setShowLichEyeBulletsSynergies(false);
    addTearDown(() => VisualPrefs.setShowLichEyeBulletsSynergies(true));
    await t.pumpWidget(wrap(ItemDetailScreen(gun: p.allGuns.first)));
    await t.pump();
    await openDetailTab(t, 'SYN');
    // Empty run state → every synergy is LOCKED, but still listed.
    await t.scrollUntilVisible(
      find.text('LOCKED'),
      400,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text('Detective Magnum'), findsOneWidget);
  });
}
