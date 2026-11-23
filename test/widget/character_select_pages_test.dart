import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/character_select_screen.dart';
import 'package:gungeon_mate/screens/item_detail_screen.dart';
import 'package:gungeon_mate/services/mp_session.dart';

/// Widget tests for the reworked _GungeoneerPage — the uniform
/// per-character layout: DESC on top, GUNS | ITEMS side-by-side with
/// tappable tiles that open ItemDetailScreen, PLAYSTYLE card, armor
/// chip. Every character renders the same anatomy.
///
/// Uses a fully-loaded RunProvider (setUpAll + loadData) so gun/item
/// name resolution and detail navigation work for real.
void main() {
  late RunProvider p;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    p = RunProvider();
    await p.loadData();
  });

  Gungeoneer char(String name) =>
      p.allGungeoneers.firstWhere((g) => g.name == name);

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: p),
      ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
    ],
    child: MaterialApp(home: child),
  );

  Widget selectFor(Gungeoneer g) =>
      CharacterSelectScreen(gungeoneers: [g]);

  Future<void> pumpSelect(
    WidgetTester t,
    Gungeoneer g, {
    double width = 400,
  }) async {
    t.view.physicalSize = Size(width, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(wrap(selectFor(g)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
  }

  group('uniform page anatomy', () {
    testWidgets('Marine: DESC top, GUNS|ITEMS columns, PLAYSTYLE, armor', (
      t,
    ) async {
      await pumpSelect(t, char('The Marine'));

      // DESC card on top with the short_desc body.
      expect(find.text('DESC'), findsOneWidget);
      expect(
        find.text(
          'A reliable soldier who starts with extra armor and accurate weaponry.',
        ),
        findsOneWidget,
      );

      // Side-by-side loadout columns.
      expect(find.text('GUNS'), findsOneWidget);
      expect(find.text('ITEMS'), findsOneWidget);
      expect(find.text('Marine Sidearm'), findsOneWidget);
      expect(find.text('Military Training'), findsOneWidget);
      expect(find.text('Supply Drop'), findsOneWidget);

      // Armor chip + playstyle card.
      expect(find.text('1 ARMOR'), findsOneWidget);
      expect(find.text('PLAYSTYLE'), findsOneWidget);
    });

    testWidgets('Robot: same anatomy, 6 ARMOR chip', (t) async {
      await pumpSelect(t, char('The Robot'));

      expect(find.text('DESC'), findsOneWidget);
      expect(find.text('GUNS'), findsOneWidget);
      expect(find.text('ITEMS'), findsOneWidget);
      expect(find.text('6 ARMOR'), findsOneWidget);
      expect(find.text("Robot's Right Hand"), findsOneWidget);
      expect(find.text('Battery Bullets'), findsOneWidget);
      expect(find.text('PLAYSTYLE'), findsOneWidget);
    });

    testWidgets('Convict: two guns render side by side in GUNS column', (
      t,
    ) async {
      await pumpSelect(t, char('The Convict'));

      expect(find.text('Budget Revolver'), findsOneWidget);
      expect(find.text('Sawed-Off'), findsOneWidget);
      expect(find.text('GUNS'), findsOneWidget);
      expect(find.text('ITEMS'), findsOneWidget);
    });

    testWidgets('Paradox: Random tiles render, no detail chevrons needed', (
      t,
    ) async {
      await pumpSelect(t, char('The Paradox'));

      // Both columns show the Random shuffle tile.
      expect(find.text('Random'), findsNWidgets(2));
      expect(find.text('GUNS'), findsOneWidget);
      expect(find.text('ITEMS'), findsOneWidget);
      expect(find.text('PLAYSTYLE'), findsOneWidget);
    });
  });

  group('tappable loadout tiles', () {
    testWidgets('Tapping a starting item opens ItemDetailScreen', (
      t,
    ) async {
      // Wider viewport — ItemDetailHeader's badge/button row has a
      // known ≤~390px overflow (U-024, foreign WIP file).
      await pumpSelect(t, char('The Marine'), width: 480);

      await t.tap(find.text('Military Training'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      expect(find.byType(ItemDetailScreen), findsOneWidget);
    });

    testWidgets('Tapping a starting gun opens ItemDetailScreen', (t) async {
      await pumpSelect(t, char('The Hunter'), width: 480);

      await t.ensureVisible(find.text('Crossbow'));
      await t.pump();
      await t.tap(find.text('Crossbow'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      expect(find.byType(ItemDetailScreen), findsOneWidget);
    });
  });
}
