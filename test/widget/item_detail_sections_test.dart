import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/services/mp_session.dart';
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
