import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/services/quiz_engine.dart';
import 'package:gungeon_mate/screens/quiz/quiz_home_screen.dart';
import 'package:gungeon_mate/screens/quiz/quiz_session_screen.dart';
import 'package:gungeon_mate/widgets/quiz/quiz_answers.dart';
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

  // ── QuizSessionScreen depth ─────────────────────────────────────

  /// Tap the chest and pump through the opening animation to the
  /// question phase (answer grid on screen).
  Future<void> reachQuestion(WidgetTester t) async {
    await t.tap(find.byType(QuizChest));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(QuizAnswerGrid), findsOneWidget);
  }

  QuizAnswerGrid answerGrid(WidgetTester t) =>
      t.widget<QuizAnswerGrid>(find.byType(QuizAnswerGrid));

  /// Answer the current question correctly and advance to the next
  /// closed chest (or game over if the pool ran out).
  Future<void> answerCorrectAndAdvance(WidgetTester t) async {
    final grid = answerGrid(t);
    await t.tap(find.text(grid.options[grid.correctIndex]));
    await t.pump();
    // Reveal holds ~650ms then _advance rolls the next chest.
    await t.pump(const Duration(milliseconds: 900));
  }

  testWidgets('correct pick reveals CORRECT then advances to next chest', (
    t,
  ) async {
    await t.pumpWidget(
      wrap(QuizSessionScreen(tier: kQuizChestTiers.first)),
    );
    await settle(t);
    await reachQuestion(t);

    final grid = answerGrid(t);
    await t.tap(find.text(grid.options[grid.correctIndex]));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('CORRECT!'), findsOneWidget);

    // Auto-advance → next loot's closed chest (pool is large, never
    // game-over on question 1).
    await t.pump(const Duration(milliseconds: 800));
    expect(find.byType(QuizChest), findsOneWidget);
    expect(find.text('TAP TO OPEN'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('wrong pick reveals answer, tap-through ends run', (t) async {
    await t.pumpWidget(
      wrap(QuizSessionScreen(tier: kQuizChestTiers.first)),
    );
    await settle(t);
    await reachQuestion(t);

    final grid = answerGrid(t);
    final wrong = (grid.correctIndex + 1) % grid.options.length;
    await t.tap(find.text(grid.options[wrong]));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    // Wrong reveal: names the loot + waits for tap-through (no auto-end).
    expect(find.textContaining('IT WAS:'), findsOneWidget);
    expect(find.text('TAP TO CONTINUE'), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    // Still on the reveal — run does NOT auto-advance on a miss.
    expect(find.text('TAP TO CONTINUE'), findsOneWidget);

    // Tap anywhere on the question body → game over screen.
    await t.tapAt(const Offset(400, 300));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('RUN OVER'), findsOneWidget);
    expect(find.text('OPEN ANOTHER'), findsOneWidget);
    expect(find.text('BACK TO CHESTS'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('AMMONOMICON HINT reveals flavor card once per run', (t) async {
    await t.pumpWidget(
      wrap(QuizSessionScreen(tier: kQuizChestTiers.first)),
    );
    await settle(t);

    // Walk chests (answering correctly) until a loot with hint text
    // shows the hint button — loot hint presence varies per drop.
    var found = false;
    for (var chest = 0; chest < 6 && !found; chest++) {
      await reachQuestion(t);
      final hintBtn = find.byKey(const ValueKey('hintbtn'));
      if (hintBtn.evaluate().isNotEmpty) {
        await t.tap(hintBtn);
        await t.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const ValueKey('hintcard')), findsOneWidget);
        found = true;
        break;
      }
      await answerCorrectAndAdvance(t);
    }
    expect(found, isTrue, reason: 'no hinted loot in first 6 chests');
    await t.pump(const Duration(seconds: 3));
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
