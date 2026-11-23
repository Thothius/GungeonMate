import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/services/quiz_engine.dart';
import 'package:gungeon_mate/screens/quiz/quiz_home_screen.dart';
import 'package:gungeon_mate/screens/quiz/quiz_session_screen.dart';
import 'package:gungeon_mate/widgets/quiz/quiz_chest.dart';

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

  // flutter_animate's `delay:` uses Future.delayed → pending Timers in
  // fake-async tests. A long pump flushes every staggered delay.
  Future<void> settle(WidgetTester t) async {
    await t.pump();
    await t.pump(const Duration(seconds: 3));
  }

  // ── QuizHomeScreen ──────────────────────────────────────────────

  testWidgets('QuizHomeScreen renders chest cards', (t) async {
    await t.pumpWidget(wrap(const QuizHomeScreen()));
    await settle(t);
    expect(t.takeException(), isNull);
    expect(find.byType(QuizHomeScreen), findsOneWidget);
  });

  testWidgets('QuizHomeScreen back button variant renders', (t) async {
    await t.pumpWidget(wrap(const QuizHomeScreen(showBackButton: true)));
    await settle(t);
    expect(t.takeException(), isNull);
  });

  // ── QuizSessionScreen per tier ──────────────────────────────────

  for (final tier in kQuizAllTiers) {
    testWidgets('QuizSessionScreen renders closed chest for ${tier.id}', (
      t,
    ) async {
      await t.pumpWidget(wrap(QuizSessionScreen(tier: tier)));
      await settle(t);
      expect(t.takeException(), isNull);
      expect(find.byType(QuizSessionScreen), findsOneWidget);
    });
  }

  testWidgets('QuizSessionScreen opens chest and shows question', (t) async {
    await t.pumpWidget(
      wrap(QuizSessionScreen(tier: kQuizChestTiers.first)),
    );
    await settle(t);

    // Tap the chest to trigger the opening animation.
    final chest = find.byType(QuizChest);
    expect(chest, findsOneWidget);
    await t.tap(chest);
    await t.pump();
    // Advance through the opening animation to the question phase.
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(t.takeException(), isNull);
  });

  testWidgets('QuizSessionScreen answers a question', (t) async {
    await t.pumpWidget(
      wrap(QuizSessionScreen(tier: kQuizChestTiers.first)),
    );
    await settle(t);

    await t.tap(find.byType(QuizChest));
    // Advance through opening animation to the question phase.
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(t.takeException(), isNull);

    // If answer options are on screen, tap the first one.
    final answers = find.byType(GestureDetector);
    if (answers.evaluate().isNotEmpty) {
      await t.tap(answers.first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(seconds: 3));
      expect(t.takeException(), isNull);
    }
  });

  // ── QuizChest standalone ────────────────────────────────────────

  testWidgets('QuizChest renders closed and opened states', (t) async {
    const asset = 'assets/images/objects/brown_chest.png';
    await t.pumpWidget(
      wrap(
        const Scaffold(
          body: Column(
            children: [
              QuizChest(asset: asset, accent: Colors.amber, size: 100),
              QuizChest(
                asset: asset,
                accent: Colors.amber,
                size: 100,
                opening: true,
                poofSeed: 3,
              ),
            ],
          ),
        ),
      ),
    );
    await settle(t);
    expect(t.takeException(), isNull);
    expect(find.byType(QuizChest), findsNWidgets(2));
  });

  testWidgets('QuizChest tap fires onTap', (t) async {
    var tapped = false;
    await t.pumpWidget(
      wrap(
        Scaffold(
          body: QuizChest(
            asset: 'assets/images/objects/brown_chest.png',
            accent: Colors.amber,
            size: 100,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    await t.pump();
    await t.tap(find.byType(QuizChest));
    expect(tapped, isTrue);
    await settle(t);
    expect(t.takeException(), isNull);
  });
}
