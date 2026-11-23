import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/damage_breakdown_screen.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/active_run/dash_capsules.dart';
import 'package:gungeon_mate/widgets/gungeoneer_header.dart';

/// Tests for the pinnable dash-capsule system: prefs persistence, the
/// picker sheet's Actions/Info groups + 3-cap toggle, the header's
/// capsule row, and the DPS breakdown screen.
void main() {
  late RunProvider p;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    p = RunProvider();
    await p.loadData();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    p.startNewRun(Gungeoneer(name: 'Marine'));
  });

  Widget wrapProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: p),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  GungeoneerHeader header({
    List<DashCapsule> pins = const [],
    ValueChanged<DashCapsule>? onTap,
    VoidCallback? onEdit,
    double topGunDps = 0,
  }) {
    return GungeoneerHeader(
      character: Gungeoneer(name: 'Marine'),
      gunCount: 2,
      itemCount: 1,
      activeSynergies: 1,
      partialSynergies: 2,
      dashCapsules: pins,
      onDashCapsuleTap: onTap,
      onDashCapsulesEdit: onEdit,
      topGunDps: topGunDps,
    );
  }

  // ── Persistence ────────────────────────────────────────────────

  test('save/load round-trips pins per slot', () async {
    await saveDashCapsules(PlayerSlot.main, [
      DashCapsule.dps,
      DashCapsule.steal,
    ]);
    expect(await loadDashCapsules(PlayerSlot.main), [
      DashCapsule.dps,
      DashCapsule.steal,
    ]);
    // Coop slot is independent.
    expect(await loadDashCapsules(PlayerSlot.coop), isEmpty);
  });

  test('load drops unknown ids, dedupes, and caps at 3', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'dash.capsules.main',
      'syn,steal,not_a_capsule,syn,dps,useShrine',
    );
    final loaded = await loadDashCapsules(PlayerSlot.main);
    expect(loaded, [
      DashCapsule.syn,
      DashCapsule.steal,
      DashCapsule.dps,
    ]);
  });

  // ── Header capsule row ─────────────────────────────────────────

  testWidgets('header shows COOL, CURSE and ADD with no pins', (t) async {
    await t.pumpWidget(wrapProviders(header(onEdit: () {})));
    await t.pump();
    expect(find.text('COOL'), findsOneWidget);
    expect(find.text('CURSE'), findsOneWidget);
    expect(find.text('ADD'), findsOneWidget);
    expect(find.text('SYN'), findsNothing);
    expect(find.text('DPS'), findsNothing);
  });

  testWidgets('header renders pinned capsules with live values', (t) async {
    var tapped = DashCapsule.steal;
    await t.pumpWidget(
      wrapProviders(
        header(
          pins: const [DashCapsule.syn, DashCapsule.dps],
          topGunDps: 56.4,
          onTap: (c) => tapped = c,
        ),
      ),
    );
    await t.pump();
    expect(find.text('SYN'), findsOneWidget);
    expect(find.text('1|2'), findsOneWidget); // active|partial synergies
    expect(find.text('DPS'), findsOneWidget);
    expect(find.text('56.4'), findsOneWidget);

    await t.tap(find.text('DPS'));
    await t.pump();
    expect(tapped, DashCapsule.dps);
  });

  testWidgets('ADD capsule hidden when no edit callback', (t) async {
    await t.pumpWidget(wrapProviders(header()));
    await t.pump();
    expect(find.text('ADD'), findsNothing);
    expect(find.text('COOL'), findsOneWidget);
  });

  // ── Picker sheet ───────────────────────────────────────────────

  testWidgets('picker shows ACTIONS/INFO groups and toggles pins', (t) async {
    List<DashCapsule>? result;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (ctx) => TextButton(
                  onPressed:
                      () => showDashCapsulePicker(
                        context: ctx,
                        pinned: const [DashCapsule.syn],
                        onChanged: (next) => result = next,
                      ),
                  child: const Text('open'),
                ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));

    expect(find.text('DASH CAPSULES'), findsOneWidget);
    expect(find.text('ACTIONS'), findsOneWidget);
    expect(find.text('INFO'), findsOneWidget);
    expect(find.text('STEAL'), findsOneWidget);
    expect(find.text('SHRINE'), findsOneWidget);
    expect(find.text('SYN'), findsOneWidget);
    expect(find.text('DPS'), findsOneWidget);
    expect(find.text('1/3 pinned'), findsOneWidget);

    // Tapping STEAL pins it (1 existing + 1 = 2 ≤ 3).
    await t.tap(find.text('STEAL'));
    await t.pump();
    expect(result, [DashCapsule.syn, DashCapsule.steal]);

    // Tapping already-pinned SYN unpins it — note: parent owns state,
    // so the sheet still shows the original `pinned` list; the toggle
    // result is what matters.
    await t.tap(find.text('SYN'));
    await t.pump();
    expect(result, [DashCapsule.steal]);
  });

  // ── Damage breakdown screen ────────────────────────────────────

  testWidgets('damage breakdown lists guns by live DPS', (t) async {
    p.addGun(p.allGuns.first, slot: PlayerSlot.main);
    await t.pumpWidget(
      wrapProviders(const DamageBreakdownScreen(slot: PlayerSlot.main)),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));

    expect(find.text('DAMAGE BREAKDOWN'), findsOneWidget);
    expect(find.text('ARMORY'), findsOneWidget);
    expect(find.text(p.allGuns.first.name), findsOneWidget);
    expect(find.text('TOP GUN'), findsOneWidget);
    expect(find.text('ARMORY DPS'), findsOneWidget);
  });

  testWidgets('damage breakdown empty state without guns', (t) async {
    p.startNewRun(Gungeoneer(name: 'Marine'));
    await t.pumpWidget(
      wrapProviders(const DamageBreakdownScreen(slot: PlayerSlot.coop)),
    );
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.text('No player'), findsOneWidget);
  });
}
