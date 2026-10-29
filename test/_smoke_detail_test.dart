import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/screens/item_detail_screen.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';

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

  // ── Gun flat rework — no tab row, one scroll: stats → synergies →
  // notes last ──
  testWidgets('gun detail has no STATS/NOTES/SYNERGIES tab row', (t) async {
    await t.pumpWidget(wrap(ItemDetailScreen(gun: p.allGuns.first)));
    await t.pump();
    expect(t.takeException(), isNull);
    for (final label in ['STATS', 'NOTES', 'SYNERGIES']) {
      expect(find.text(label), findsNothing);
    }
  });

  testWidgets('STATS tab is the default and shows hero stats', (t) async {
    // Pick a gun guaranteed to have the hero stats.
    final gun = p.allGuns.firstWhere(
      (g) => g.range.isNotEmpty || g.spread.isNotEmpty || g.force.isNotEmpty,
      orElse: () => p.allGuns.first,
    );
    await t.pumpWidget(wrap(ItemDetailScreen(gun: gun)));
    await t.pump();
    expect(t.takeException(), isNull);
    // Hero row — DPS panel + Range/Spread/Force cards.
    final heroFound = [
      'Range',
      'Spread',
      'Force',
      'Damage / sec',
    ].any((l) => find.textContaining(l).evaluate().isNotEmpty);
    expect(heroFound, true);
  });

  testWidgets('notes render at the bottom of the flat scroll', (t) async {
    final gun = p.allGuns.firstWhere(
      (g) => g.notes.isNotEmpty,
      orElse: () => p.allGuns.first,
    );
    await t.pumpWidget(wrap(ItemDetailScreen(gun: gun)));
    await t.pump();
    await t.scrollUntilVisible(find.text('EFFECT'), 400);
    await t.pump();
    expect(t.takeException(), isNull);
    expect(find.text('EFFECT'), findsOneWidget);
  });

  testWidgets('synergies render flat inside the same scroll', (t) async {
    await t.pumpWidget(wrap(ItemDetailScreen(gun: p.allGuns.first)));
    await t.pump();
    // Either the grouped lists or the empty state renders — scroll
    // until one of them appears.
    await t.scrollUntilVisible(
      find.text('No synergies to show.'),
      400,
      maxScrolls: 20,
    );
    await t.pump();
    expect(t.takeException(), isNull);
  });
}
