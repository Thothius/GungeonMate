import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/screens/ammonomicon_screen.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';

/// Ammonomicon navigation — the horizontal category chip strip is the
/// nav (no picker grid, no back button). Tapping a chip swaps the
/// content area and reveals that category's search field.
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

  testWidgets('category chips render when loaded', (t) async {
    await t.pumpWidget(wrap(const AmmonomiconScreen()));
    await t.pump();
    for (final label in ['NPCS', 'ENEMIES', 'BOSSES', 'PICKUPS', 'OBJECTS']) {
      expect(find.text(label), findsWidgets, reason: 'missing chip $label');
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('tapping a chip selects it and shows its search field', (
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
}
