import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/item_detail_screen.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/item_detail/description_blocks.dart';
import 'package:gungeon_mate/widgets/item_detail/item_body.dart';
import 'package:gungeon_mate/widgets/item_detail/gun_stats.dart';

void main() {
  late RunProvider p;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    p = RunProvider();
    await p.loadData();
  });

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: p),
      ChangeNotifierProvider(create: (_) => MpSession(p)),
    ],
    child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
  );

  Item itemNamed(String name) =>
      p.allItems.firstWhere((i) => i.name.toLowerCase() == name);
  Gun gunNamed(String name) =>
      p.allGuns.firstWhere((g) => g.name.toLowerCase() == name);

  // ── ItemBody special-info branches ──────────────────────────────

  for (final name in [
    'ser junkan 1',
    'spice',
    'sprun',
    'clown mask',
    'drill',
    'loot bag',
    'platinum bullets',
    'iron coin',
    'prime primer',
    'arcane gunpowder',
    'planar lead',
    'obsidian shell casing',
  ]) {
    testWidgets('ItemBody renders special info for "$name"', (t) async {
      await t.pumpWidget(wrap(ItemBody(item: itemNamed(name))));
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.byType(ItemBody), findsOneWidget);
    });
  }

  testWidgets('ItemBody renders active-item charge/duration pills', (t) async {
    // Any isActive item exercises the Charge/Duration StatPill row.
    final active = p.allItems.firstWhere(
      (i) => i.isActive,
      orElse: () => p.allItems.first,
    );
    await t.pumpWidget(wrap(ItemBody(item: active)));
    await t.pump();
    expect(t.takeException(), isNull);
  });

  testWidgets('ItemBody renders effect description block', (t) async {
    final withEffect = p.allItems.firstWhere(
      (i) => i.effect.isNotEmpty,
      orElse: () => p.allItems.first,
    );
    await t.pumpWidget(wrap(ItemBody(item: withEffect)));
    await t.pump();
    expect(t.takeException(), isNull);
  });

  // ── ItemDetailScreen field surfacing (S3.4) ─────────────────────
  // Feedback item 5: item `effect` + `ammonomicon_entry` were parsed
  // but never rendered. Both now surface — header effect line and the
  // AmmonomiconCard block. Pin it so a layout refactor can't silently
  // drop them again.

  testWidgets('ItemDetailScreen surfaces effect line + AmmonomiconCard', (
    t,
  ) async {
    final item = p.allItems.firstWhere(
      (i) => i.effect.isNotEmpty && i.ammonomiconEntry.isNotEmpty,
    );
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: p),
          ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
        ],
        child: MaterialApp(home: ItemDetailScreen(item: item)),
      ),
    );
    await t.pump();
    // Flush the RunProvider autosave debounce + flutter_animate delays.
    await t.pump(const Duration(seconds: 3));
    expect(t.takeException(), isNull);
    // Effect line lives in ItemBody at the top of the detail view —
    // assert it before scrolling (off-screen slivers unbuild).
    expect(find.textContaining(item.effect), findsWidgets);
    // AmmonomiconCard sits in a lazy SliverToBoxAdapter below the fold —
    // scroll the detail view until it builds.
    await t.dragUntilVisible(
      find.byType(AmmonomiconCard),
      find.byType(Scrollable).last,
      const Offset(0, -400),
    );
    await t.pump();
    expect(find.byType(AmmonomiconCard), findsOneWidget);
    expect(find.textContaining(item.ammonomiconEntry), findsWidgets);
  });

  // ── GunStats special-info branches ──────────────────────────────

  for (final name in [
    'gunderfury',
    'triple gun',
    'evolver',
    'shellegun',
    'chamber gun',
    'casey',
  ]) {
    testWidgets('GunStats renders special info for "$name"', (t) async {
      await t.pumpWidget(wrap(GunStats(gun: gunNamed(name))));
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.byType(GunStats), findsOneWidget);
    });
  }

  testWidgets('GunStats renders stat grid for a plain gun', (t) async {
    final plain = p.allGuns.firstWhere(
      (g) => ![
        'gunderfury',
        'triple gun',
        'evolver',
        'shellegun',
        'chamber gun',
        'casey',
      ].contains(g.name.toLowerCase()),
    );
    await t.pumpWidget(wrap(GunStats(gun: plain)));
    await t.pump();
    expect(t.takeException(), isNull);
    // DPS always leads the grid.
    expect(find.text('DPS'), findsOneWidget);
  });
}
