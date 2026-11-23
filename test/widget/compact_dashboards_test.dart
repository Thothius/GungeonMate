import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/dashboards/compact_dashboards.dart';
import 'package:gungeon_mate/widgets/dashboards/special_gun_dashboards.dart';

void main() {
  late RunProvider p;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    p = RunProvider();
    await p.loadData();
  });

  // Every dashboard widget returns a sliver — wrap in CustomScrollView.
  Widget wrapSliver(Widget sliver) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: p),
      ChangeNotifierProvider(create: (_) => MpSession(p)),
    ],
    child: MaterialApp(
      home: Scaffold(body: CustomScrollView(slivers: [sliver])),
    ),
  );

  void dashTests(String label, Widget Function(PlayerSlot) build) {
    for (final slot in PlayerSlot.values) {
      testWidgets('$label renders for $slot', (t) async {
        await t.pumpWidget(wrapSliver(build(slot)));
        await t.pump();
        expect(t.takeException(), isNull);
      });
    }
  }

  group('compact item dashboards', () {
    dashTests('PlatinumBullets', (s) => PlatinumBulletsDashboard(slot: s));
    dashTests('IronCoin', (s) => IronCoinDashboard(slot: s));
    dashTests('Spice', (s) => SpiceDashboard(slot: s));
    dashTests('Metronome', (s) => MetronomeDashboard(slot: s));
    dashTests('Gunther', (s) => GuntherDashboard(slot: s));
    dashTests('Shellegun', (s) => ShellegunDashboard(slot: s));
    dashTests('ChamberGun', (s) => ChamberGunDashboard(slot: s));
    dashTests('Polaris', (s) => PolarisDashboard(slot: s));
    dashTests('Sprun', (s) => SprunDashboard(slot: s));
    dashTests('BoxingGlove', (s) => BoxingGloveDashboard(slot: s));
    dashTests('Cigarettes', (s) => CigarettesDashboard(slot: s));
    dashTests('GunSoul', (s) => GunSoulDashboard(slot: s));
  });

  group('special-gun evo dashboards', () {
    dashTests('Gunderfury', (s) => GunderfuryDashboardSliver(slot: s));
    dashTests('Evolver', (s) => EvolverDashboardSliver(slot: s));
    dashTests('TripleGun', (s) => TripleGunDashboardSliver(slot: s));
  });
}
