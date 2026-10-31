import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/screens/ammonomicon_screen.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';

/// Ammonomicon two-level navigation — grid of categories → tapped category
/// shows back button + title + content → back returns to the grid.
///
/// Skipped: the screen gates the grid behind `_loadData` (compute() +
/// asset reads) which can't finish under flutter_test — same limit as
/// _smoke_ammonomicon_test. Retained as a device/CI guard.
void main() {
  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => RunProvider()),
      ChangeNotifierProvider(create: (_) => MpSession(RunProvider())),
    ],
    child: MaterialApp(home: child),
  );

  testWidgets('ammonomicon opens on the 4-col category grid', skip: true, (t) async {
    await t.pumpWidget(wrap(const AmmonomiconScreen()));
    await t.pump();
    // Category tiles render immediately (static list).
    expect(find.text('NPCs'), findsOneWidget);
    expect(find.text('Enemies'), findsOneWidget);
    expect(find.text('Bosses'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
  });

  testWidgets('tapping a category opens it with title + back', skip: true, (
    t,
  ) async {
    await t.pumpWidget(wrap(const AmmonomiconScreen()));
    await t.pump();
    await t.tap(find.text('NPCs'));
    await t.pump();
    expect(t.takeException(), isNull);
    // Back button appears in the picked-category header.
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });

  testWidgets('back from a category returns to the grid', skip: true, (
    t,
  ) async {
    await t.pumpWidget(wrap(const AmmonomiconScreen()));
    await t.pump();
    await t.tap(find.text('Bosses'));
    await t.pump();
    await t.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await t.pump();
    // Grid categories visible again.
    expect(find.text('NPCs'), findsOneWidget);
    expect(find.text('Enemies'), findsOneWidget);
  });
}
