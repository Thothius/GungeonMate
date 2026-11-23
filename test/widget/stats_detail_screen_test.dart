import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/stats_detail_screen.dart';
import 'package:gungeon_mate/widgets/active_run/gungeon_meter.dart';

/// StatsDetailScreen — coolness/curse detail cards: value readout,
/// breakdown line, slider, ±0.5/±1 buttons, GungeonMeter, appbar reset.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(StatType type, RunProvider rp) {
    return ChangeNotifierProvider<RunProvider>.value(
      value: rp,
      child: MaterialApp(home: StatsDetailScreen(statType: type)),
    );
  }

  testWidgets('coolness card renders value, slider, steppers, meter', (
    tester,
  ) async {
    final rp = RunProvider();
    await tester.pumpWidget(wrap(StatType.coolness, rp));
    await tester.pump();

    expect(find.text('Coolness'), findsWidgets);
    expect(find.text('0.0'), findsWidgets);
    expect(find.byType(Slider), findsOneWidget);
    for (final label in ['-1.0', '-0.5', '+0.5', '+1.0']) {
      expect(find.text(label), findsOneWidget, reason: 'missing $label');
    }
    expect(find.textContaining('Cooldown reduction'), findsOneWidget);
    expect(find.byType(GungeonMeter), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('+0.5 button adjusts the manual coolness base', (tester) async {
    final rp = RunProvider();
    await tester.pumpWidget(wrap(StatType.coolness, rp));
    await tester.pump();

    await tester.tap(find.text('+0.5'));
    await tester.pump();

    expect(rp.runState.coolness, 0.5);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('curse card shows threat meter + breakdown after adjust', (
    tester,
  ) async {
    final rp = RunProvider();
    rp.adjustCurse(-2);
    await tester.pumpWidget(wrap(StatType.curse, rp));
    await tester.pump();

    expect(find.text('Curse'), findsWidgets);
    expect(find.text('-2.0'), findsWidgets);
    expect(find.textContaining('Jammed enemy chance:'), findsOneWidget);
    expect(find.textContaining('Base'), findsWidgets);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('appbar reset returns a nonzero base to zero', (tester) async {
    final rp = RunProvider();
    rp.adjustCoolness(3);
    await tester.pumpWidget(wrap(StatType.coolness, rp));
    await tester.pump();

    // Reset only appears when the manual base is nonzero.
    final reset = find.byIcon(Icons.restart_alt);
    expect(reset, findsOneWidget);
    await tester.tap(reset);
    await tester.pump();

    expect(rp.runState.coolness, 0);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('reset hidden when manual base is already zero', (tester) async {
    final rp = RunProvider();
    await tester.pumpWidget(wrap(StatType.coolness, rp));
    await tester.pump();

    expect(find.byIcon(Icons.restart_alt), findsNothing);

    await tester.pump(const Duration(seconds: 4));
  });
}
