import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/run_log_entry.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/shrine_picker_screen.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/active_run/cool_curse_sheet.dart';

/// CoolCurseSheet — the quick-manage bottom sheet behind the COOL/CURSE
/// capsule taps. Big centered number, ±0.5/±1 steppers flanking it,
/// per-meter stat readout, STEAL (+1 curse) / CURSULA BUY (+2.5 curse)
/// actions, and a SHRINES lookup shortcut.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RunProvider rp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    rp = RunProvider();
    rp.startNewRun(Gungeoneer(name: 'Marine'));
    await rp.loadData();
  });

  Widget harness({required bool isCool}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RunProvider>.value(value: rp),
        ChangeNotifierProvider(create: (_) => MpSession(rp)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => Center(
              child: TextButton(
                onPressed: () =>
                    CoolCurseSheet.show(ctx, isCool: isCool),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester t, {required bool isCool}) async {
    await t.pumpWidget(harness(isCool: isCool));
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  group('CoolCurseSheet — curse variant', () {
    testWidgets('renders number, steppers, stats, and curse actions', (
      t,
    ) async {
      await openSheet(t, isCool: false);

      expect(find.text('CURSE'), findsOneWidget);
      expect(find.text('STEAL'), findsOneWidget);
      expect(find.text('CURSULA'), findsOneWidget);
      expect(find.text('+1 CURSE'), findsOneWidget);
      expect(find.text('+2.5 CURSE'), findsOneWidget);
      expect(find.text('SHRINES'), findsOneWidget);
      // Curse stat rows.
      expect(find.text('Jammed enemies'), findsOneWidget);
      expect(find.text('Ammo drops'), findsOneWidget);
      // Cool rows must not appear.
      expect(find.text('Chest fuse chance'), findsNothing);
      expect(find.text('Active cooldown'), findsNothing);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 5));
    });

    testWidgets('±1 and ±0.5 steppers adjust curse', (t) async {
      await openSheet(t, isCool: false);
      final before = rp.runState.curse;

      await t.tap(find.text('+1'));
      await t.pump();
      expect(rp.runState.curse, before + 1);

      await t.tap(find.text('+0.5'));
      await t.pump();
      expect(rp.runState.curse, before + 1.5);

      await t.tap(find.text('−1'));
      await t.pump();
      expect(rp.runState.curse, before + 0.5);

      await t.tap(find.text('−0.5'));
      await t.pump();
      expect(rp.runState.curse, before);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 5));
    });

    testWidgets('STEAL adds exactly +1 curse and logs the event', (
      t,
    ) async {
      await openSheet(t, isCool: false);
      final before = rp.runState.curse;
      final logLen = rp.runState.log.length;

      await t.tap(find.text('STEAL'));
      await t.pump();

      expect(rp.runState.curse, before + 1);
      expect(rp.runState.log.length, logLen + 1);
      final entry = rp.runState.log.last;
      expect(entry.category, RunLogCategory.steal);
      expect(entry.curseDelta, 1);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 5));
    });

    testWidgets('CURSULA BUY adds exactly +2.5 curse and logs the event', (
      t,
    ) async {
      await openSheet(t, isCool: false);
      final before = rp.runState.curse;
      final logLen = rp.runState.log.length;

      await t.tap(find.text('CURSULA'));
      await t.pump();

      expect(rp.runState.curse, before + 2.5);
      expect(rp.runState.log.length, logLen + 1);
      final entry = rp.runState.log.last;
      expect(entry.category, RunLogCategory.cursula);
      expect(entry.curseDelta, 2.5);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 5));
    });

    testWidgets('SHRINES shortcut pushes the shrine picker', (t) async {
      await openSheet(t, isCool: false);

      await t.tap(find.text('SHRINES'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      expect(find.byType(ShrinePickerScreen), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 5));
    });
  });

  group('CoolCurseSheet — cool variant', () {
    testWidgets('renders cool stats and hides curse actions', (t) async {
      await openSheet(t, isCool: true);

      expect(find.text('COOLNESS'), findsOneWidget);
      expect(find.text('STEAL'), findsNothing);
      expect(find.text('CURSULA'), findsNothing);
      expect(find.text('Chest fuse chance'), findsOneWidget);
      expect(find.text('Active cooldown'), findsOneWidget);
      expect(find.text('Jammed enemies'), findsNothing);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 5));
    });

    testWidgets('± steppers adjust coolness only', (t) async {
      await openSheet(t, isCool: true);
      final coolBefore = rp.runState.coolness;
      final curseBefore = rp.runState.curse;

      await t.tap(find.text('+1'));
      await t.pump();
      expect(rp.runState.coolness, coolBefore + 1);
      expect(rp.runState.curse, curseBefore);

      await t.tap(find.text('−0.5'));
      await t.pump();
      expect(rp.runState.coolness, coolBefore + 0.5);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 5));
    });
  });
}
