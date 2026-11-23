import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/widgets/active_run/dice_roll.dart';
import 'package:gungeon_mate/widgets/scale_button.dart';

/// Single-die rework coverage:
///  - solo roll lands 1–6 and finishes with "ROLL AGAIN"
///  - co-op duel compares one die per player — clear winner
///  - ties auto-reroll (round increments, stale rounds ignored)
///  - mid-roll close leaves no pending timers
void main() {
  late MpSession session;

  Widget wrap(Widget child) {
    return ChangeNotifierProvider.value(
      value: session,
      child: MaterialApp(home: Scaffold(body: Center(child: child))),
    );
  }

  Future<void> openDialog(
    WidgetTester t, {
    bool challenged = false,
    List<int>? rolls,
  }) async {
    await t.pumpWidget(
      wrap(
        DiceRollDialog(isChallenged: challenged, debugRollValues: rolls),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }

  /// Tap the ScaleButton wrapping [label] — the label sits inside an
  /// IgnorePointer, so tapping the text itself warns as unhittable.
  Future<void> tapRoll(WidgetTester t, String label) async {
    await t.tap(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(ScaleButton),
      ),
    );
  }

  /// Tap ROLL and run the 1.1s spin + landing.
  Future<void> rollAndLand(WidgetTester t) async {
    await tapRoll(t, 'ROLL');
    await t.pump();
    await t.pump(const Duration(milliseconds: 1200));
  }

  setUp(() {
    session = MpSession.placeholder();
  });

  tearDown(() {
    session.dispose();
  });

  group('solo', () {
    testWidgets('roll lands a 1-6 face and offers ROLL AGAIN', (t) async {
      await openDialog(t, rolls: [4]);

      await tapRoll(t, 'ROLL THE DIE!');
      await t.pump();
      await t.pump(const Duration(milliseconds: 1200));

      expect(find.text('GUNFORTUNA HAS DECIDED YOUR FATE!'), findsOneWidget);
      expect(find.text('ROLL AGAIN'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('closing mid-roll cancels timers cleanly', (t) async {
      await openDialog(t, rolls: [2]);

      await tapRoll(t, 'ROLL THE DIE!');
      await t.pump(const Duration(milliseconds: 200));

      // Pop the dialog while the die is still spinning.
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
    });
  });

  group('co-op duel', () {
    testWidgets('higher roll wins — loser sees partner victory', (t) async {
      session.enableDemo();
      await openDialog(t, challenged: true, rolls: [3]);

      await rollAndLand(t);
      expect(find.text('ROLLED!'), findsOneWidget);
      expect(find.text('Your roll: 3'), findsOneWidget);

      // Peer rolls 5 — I lose.
      session.onDiceResult!(5, [5], 1);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      expect(
        find.text('GUNFORTUNA DECLARES SIDEKICK VICTORIOUS!'),
        findsOneWidget,
      );
      expect(find.text('VS'), findsOneWidget);
      expect(find.text('REMATCH'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('tie auto-rerolls until a winner emerges', (t) async {
      session.enableDemo();
      await openDialog(t, challenged: true, rolls: [3, 5]);

      // Round 1: I roll 3.
      await rollAndLand(t);
      expect(find.text('Your roll: 3'), findsOneWidget);

      // Peer also rolls 3 → TIE, round 2 auto-starts.
      session.onDiceResult!(3, [3], 1);
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('TIE!'), findsOneWidget);
      expect(find.text('ROUND 2'), findsOneWidget);

      // A stale round-1 result arriving now must be ignored.
      session.onDiceResult!(6, [6], 1);
      await t.pump();
      expect(find.textContaining('TIE!'), findsOneWidget);

      // Auto-reroll fires (~1s), die spins (~1.1s), lands on 5.
      await t.pump(const Duration(milliseconds: 1100));
      await t.pump(const Duration(milliseconds: 1200));
      expect(find.text('Your roll: 5'), findsOneWidget);

      // Peer rolls 4 in round 2 → I win, decided on round 2.
      session.onDiceResult!(4, [4], 2);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));

      expect(
        find.text('GUNFORTUNA DECLARES YOU VICTORIOUS!'),
        findsOneWidget,
      );
      expect(find.text('Decided on round 2'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });
}
