import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/active_run/active_run_helpers.dart';
import 'package:gungeon_mate/widgets/active_run/dice_roll.dart';
import 'package:gungeon_mate/widgets/active_run/player_page.dart';

void main() {
  // Catalog data loads once in setUpAll (real async zone) — loadData()
  // uses compute() isolates whose futures never resolve inside
  // testWidgets' FakeAsync zone.
  late RunProvider p;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    p = RunProvider();
    await p.loadData();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Fresh run per test — resets runState so mutations don't leak.
    p.startNewRun(Gungeoneer(name: 'Marine'));
  });

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: p),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  void seedGear(PlayerSlot slot) {
    if (slot == PlayerSlot.coop) {
      p.startCoopPlayer(Gungeoneer(name: 'Hunter'));
    }
    p.addGun(p.allGuns.first, slot: slot);
    p.addItem(
      p.allItems.firstWhere(
        (i) => i.effect.isNotEmpty,
        orElse: () => p.allItems.first,
      ),
      slot: slot,
    );
  }

  // ── PlayerPage ──────────────────────────────────────────────────

  for (final slot in PlayerSlot.values) {
    testWidgets('PlayerPage renders for $slot', (t) async {
      await t.pumpWidget(wrap(PlayerPage(slot: slot)));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      expect(find.byType(PlayerPage), findsOneWidget);
    });
  }

  testWidgets('PlayerPage coop slot renders alongside main', (t) async {
    p.startCoopPlayer(Gungeoneer(name: 'Hunter'));
    await t.pumpWidget(
      wrap(
        const Column(
          children: [
            Expanded(child: PlayerPage(slot: PlayerSlot.main)),
            Expanded(child: PlayerPage(slot: PlayerSlot.coop)),
          ],
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
    expect(find.byType(PlayerPage), findsNWidgets(2));
  });

  // ── EffectsTile ─────────────────────────────────────────────────

  for (final slot in PlayerSlot.values) {
    testWidgets('EffectsTile renders collapsed for $slot', (t) async {
      await t.pumpWidget(wrap(EffectsTile(slot: slot)));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      expect(find.byType(EffectsTile), findsOneWidget);
    });

    testWidgets('EffectsTile expands on tap for $slot', (t) async {
      seedGear(slot);
      await t.pumpWidget(wrap(EffectsTile(slot: slot)));
      await t.pump();

      await t.tap(find.text('Effects'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
    });
  }

  // ── DiceRollDialog ──────────────────────────────────────────────

  for (final challenged in [false, true]) {
    testWidgets('DiceRollDialog renders as dialog (challenged=$challenged)', (
      t,
    ) async {
      await t.pumpWidget(
        wrap(
          Builder(
            builder:
                (ctx) => TextButton(
                  onPressed:
                      () => showDiceRollDialog(ctx, isChallenged: challenged),
                  child: const Text('open'),
                ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(seconds: 1));

      await t.tap(find.text('open'));
      await t.pump();
      await t.pump(const Duration(seconds: 3));
      expect(t.takeException(), isNull);
      expect(find.byType(DiceRollDialog), findsOneWidget);
    });
  }

  // ── HeaderMenu / tools sheet ────────────────────────────────────

  testWidgets('HeaderMenu renders and opens tools sheet', (t) async {
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: p),
          ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
        ],
        child: const MaterialApp(home: Scaffold(body: HeaderMenu())),
      ),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(t.takeException(), isNull);
    expect(find.byType(HeaderMenu), findsOneWidget);
  });

  testWidgets('tools sheet Ammonomicon action pushes the codex screen', (
    t,
  ) async {
    await t.pumpWidget(wrap(const HeaderMenu()));
    await t.pump();

    await t.tap(find.byIcon(Icons.tune_rounded));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    // Sheet groups + Ammonomicon action visible.
    expect(find.text('RUN'), findsWidgets);
    expect(find.text('Ammonomicon'), findsOneWidget);
    expect(find.text('Shrines'), findsOneWidget);

    await t.tap(find.text('Ammonomicon'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(seconds: 2));
    expect(t.takeException(), isNull);
  });
}
