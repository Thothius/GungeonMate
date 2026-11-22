import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/cool_curse_screen.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/active_run/player_page.dart';

/// Cool & Curse screen — unified stat colors, ±0.5 controls, labeled
/// reset that clears only the manual base, and solo reachability via
/// the header capsule long-press.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  RunProvider loadedRp() {
    final rp = RunProvider();
    rp.startNewRun(Gungeoneer(name: 'Marine'));
    return rp;
  }

  Widget wrap(Widget child, RunProvider rp) {
    return ChangeNotifierProvider<RunProvider>.value(
      value: rp,
      child: MaterialApp(home: child),
    );
  }

  group('CoolCurseScreen', () {
    testWidgets('renders both meter panels with step + reset controls', (
      tester,
    ) async {
      final rp = loadedRp();
      await tester.pumpWidget(wrap(const CoolCurseScreen(), rp));
      await tester.pump();

      expect(find.text('COOLNESS'), findsOneWidget);
      expect(find.text('CURSE'), findsWidgets); // panel title + explainer
      // ±1 and ±0.5 on each panel.
      expect(find.text('−1'), findsNWidgets(2));
      expect(find.text('+1'), findsNWidgets(2));
      expect(find.text('−.5'), findsNWidgets(2));
      expect(find.text('+.5'), findsNWidgets(2));
      // Labeled reset affordance.
      expect(find.text('RESET'), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('+0.5 step adjusts the manual base by half a point', (
      tester,
    ) async {
      final rp = loadedRp();
      await tester.pumpWidget(wrap(const CoolCurseScreen(), rp));
      await tester.pump();

      await tester.tap(find.text('+.5').first);
      await tester.pump();

      expect(rp.runState.coolness, 0.5);
      expect(rp.runState.totalCoolness, 0.5);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('RESET clears base without poisoning item contributions', (
      tester,
    ) async {
      final rp = loadedRp();
      rp.adjustCoolness(3);
      rp.addItem(Item(name: 'Cool Trinket', coolness: 5));
      expect(rp.runState.totalCoolness, 8);

      await tester.pumpWidget(wrap(const CoolCurseScreen(), rp));
      await tester.pump();

      // First RESET belongs to the COOLNESS panel.
      await tester.tap(find.text('RESET').first);
      await tester.pump();

      expect(rp.runState.coolness, 0);
      expect(
        rp.runState.totalCoolness,
        5,
        reason: 'Item contribution must survive a manual-base reset',
      );

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('negative totals render with a single minus sign', (
      tester,
    ) async {
      final rp = loadedRp();
      rp.adjustCurse(-2);
      await tester.pumpWidget(wrap(const CoolCurseScreen(), rp));
      await tester.pump();

      // The CURSE panel shows the total (-2) — plain '-2', never '+-2'.
      expect(find.text('-2'), findsWidgets);
      expect(find.textContaining('+-'), findsNothing);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('explainer jam wording matches the live formulas', (
      tester,
    ) async {
      final rp = loadedRp();
      await tester.pumpWidget(wrap(const CoolCurseScreen(), rp));
      await tester.pump();
      // Scroll the explainer into view.
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();

      expect(
        find.textContaining('4% per point vs normal enemies'),
        findsOneWidget,
      );
      expect(find.textContaining('roughly 4%/2%'), findsNothing);

      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('Solo reachability', () {
    testWidgets('long-pressing the CURSE capsule opens CoolCurseScreen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final rp = loadedRp();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<RunProvider>.value(value: rp),
            ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
          ],
          child: const MaterialApp(home: PlayerPage(slot: PlayerSlot.main)),
        ),
      );
      await tester.pump();

      // The capsule label 'CURSE' sits in the header; long-press it.
      final capsule = find.text('CURSE');
      expect(capsule, findsWidgets);
      await tester.longPress(capsule.first);
      await tester.pumpAndSettle();

      expect(find.byType(CoolCurseScreen), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
    });
  });
}
