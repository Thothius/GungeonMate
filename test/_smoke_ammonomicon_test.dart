import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/screens/ammonomicon_screen.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/state_widgets.dart';

/// Smoke: AmmonomiconScreen loads real JSON assets and renders the
/// category strip without exceptions. `debugParseInline` replaces the
/// compute() isolates that can't run under flutter_test.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AmmonomiconScreen.debugParseInline = true;
  });
  tearDown(() {
    AmmonomiconScreen.debugParseInline = false;
  });

  testWidgets('ammonomicon loads data and renders category chips', (t) async {
    await t.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RunProvider()),
          ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
        ],
        child: const MaterialApp(
          home: AmmonomiconScreen(showBackButton: false),
        ),
      ),
    );
    // Asset loadString uses real async I/O — poll with runAsync until
    // the skeleton loaders are gone; parses run inline.
    for (var i = 0; i < 25; i++) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await t.pump();
      if (find.byType(SkeletonLoader).evaluate().isEmpty) break;
    }

    // Overview landing: first card row visible immediately, lower
    // rows need a scroll (grid is lazily built).
    expect(find.text('GUNGEONEERS'), findsWidgets);
    expect(find.text('NPCS'), findsWidgets);
    for (final label in ['ENEMIES', 'BOSSES']) {
      await t.scrollUntilVisible(
        find.text(label),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsWidgets);
    }
    expect(t.takeException(), isNull);
  });
}
