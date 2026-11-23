import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/screens/ammonomicon_screen.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';

/// Ammonomicon navigation — the overview landing shows category cards;
/// tapping one drills into the category view where the horizontal chip
/// strip is the nav and each category has its own search field.
///
/// `debugStartLoaded` skips asset loads entirely — these tests cover
/// navigation chrome, not data. The real-load path is covered by
/// _smoke_ammonomicon_test.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AmmonomiconScreen.debugStartLoaded = true;
  });
  tearDown(() {
    AmmonomiconScreen.debugStartLoaded = false;
  });

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => RunProvider()),
      ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
    ],
    child: MaterialApp(home: child),
  );

  testWidgets('overview renders category cards', (t) async {
    await t.pumpWidget(wrap(const AmmonomiconScreen()));
    await t.pump();
    expect(find.text('BROWSE THE CODEX'), findsOneWidget);
    // The grid is lazily built — walk it with scrollUntilVisible so
    // every category card is verified regardless of fold position.
    const labels = [
      'GUNGEONEERS',
      'NPCS',
      'ENEMIES',
      'BOSSES',
      'PICKUPS',
      'OBJECTS',
      'GUNS',
      'ITEMS',
      'SYNERGIES',
      'SHRINES',
      'CHAPTERS',
      'GAME MODES',
    ];
    for (final label in labels) {
      await t.scrollUntilVisible(
        find.text(label),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsWidgets, reason: 'missing card $label');
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('tapping a card selects it and shows its search field', (
    t,
  ) async {
    await t.pumpWidget(wrap(const AmmonomiconScreen()));
    await t.pump();
    await t.tap(find.text('ENEMIES'));
    await t.pump();

    expect(find.text('Search enemies...'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('switching chips swaps the content category', (t) async {
    await t.pumpWidget(wrap(const AmmonomiconScreen()));
    await t.pump();
    await t.tap(find.text('BOSSES'));
    await t.pump();
    expect(find.text('Search bosses...'), findsOneWidget);

    await t.tap(find.text('NPCS'));
    await t.pump();
    expect(find.text('Search npcs...'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('category back button returns to the overview', (t) async {
    await t.pumpWidget(wrap(const AmmonomiconScreen()));
    await t.pump();
    await t.tap(find.text('ENEMIES'));
    await t.pump();
    expect(find.text('Search enemies...'), findsOneWidget);

    await t.tap(find.byTooltip('Back'));
    await t.pump();
    expect(find.text('BROWSE THE CODEX'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
