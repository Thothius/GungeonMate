import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/shrine_picker_screen.dart';

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
    child: MaterialApp(home: child),
  );

  // flutter_animate stagger delays need a long pump to flush.
  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(seconds: 3));
  }

  testWidgets('ShrinePickerScreen renders shrine grid', (t) async {
    await t.pumpWidget(wrap(const ShrinePickerScreen()));
    await settle(t);
    expect(t.takeException(), isNull);
    expect(find.text('Use a Shrine'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('tapping a shrine opens the activation sheet', (t) async {
    await t.pumpWidget(wrap(const ShrinePickerScreen()));
    await settle(t);

    // Tap the first shrine tile (GestureDetector inside the grid).
    final tiles = find.byType(GestureDetector);
    expect(tiles, findsWidgets);
    await t.tap(tiles.first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));

    expect(t.takeException(), isNull);
    // The sheet shows a Use/Mark button.
    expect(find.text('Cancel'), findsOneWidget);
    expect(
      find.textContaining('Use Shrine').evaluate().isNotEmpty ||
          find.textContaining('Mark as Used').evaluate().isNotEmpty,
      isTrue,
    );
  });

  testWidgets('activating a shrine applies it and shows result', (t) async {
    await t.pumpWidget(wrap(const ShrinePickerScreen()));
    await settle(t);
    final before = p.runState.shrinesUsed.length;

    await t.tap(find.byType(GestureDetector).first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));

    final useBtn = find.text('Use Shrine');
    final markBtn = find.text('Mark as Used');
    final btn = useBtn.evaluate().isNotEmpty ? useBtn : markBtn;
    await t.tap(btn.first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await settle(t);

    expect(t.takeException(), isNull);
    expect(p.runState.shrinesUsed.length, greaterThan(before));
  });

  testWidgets('used-shrines chip opens the log dialog', (t) async {
    await t.pumpWidget(wrap(const ShrinePickerScreen()));
    await settle(t);

    // The app-bar chip shows "N used".
    final chip = find.textContaining('used');
    expect(chip, findsWidgets);
    await t.tap(chip.first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(t.takeException(), isNull);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('resolveShrineIcon overrides ammo/angel assets', (t) async {
    expect(
      resolveShrineIcon('Ammo Shrine', 'default.png'),
      'assets/images/shrines/Ammo_Shrine.webp',
    );
    expect(
      resolveShrineIcon('Fallen Angel', 'default.png'),
      'assets/images/shrines/Angel_Shrine.webp',
    );
    expect(resolveShrineIcon('Other', 'default.png'), 'default.png');
  });
}
