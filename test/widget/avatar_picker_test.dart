import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/widgets/paradox/avatar_picker.dart';

/// Avatar picker contract — portrait grid shuffles per open, the
/// frame stage shows NONE + animated specials only, and the dialog
/// stays inside the viewport on tall screens (CONFIRM reachable).
///
/// NB: the animated special frames tick forever, so pumpAndSettle
/// never returns — use bounded pumps everywhere.
void main() {
  Widget opener(BuildContext c) => TextButton(
    onPressed: () => showAvatarPicker(c, 'g1_1'),
    child: const Text('open'),
  );

  Future<void> openPicker(WidgetTester t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: Builder(builder: opener))),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 600)); // dialog transition
    await t.tap(find.text('open'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
  }

  Future<void> openFrameStage(WidgetTester t) async {
    final grid = find.byType(GridView);
    expect(grid, findsOneWidget);
    final topLeft = t.getTopLeft(grid);
    final size = t.getSize(grid);
    await t.tapAt(
      Offset(topLeft.dx + size.width / 6, topLeft.dy + size.height / 6),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('frame stage shows only NONE + animated frames', (t) async {
    await openPicker(t);
    expect(t.takeException(), isNull);
    await openFrameStage(t);

    expect(find.text('PICK A FRAME'), findsOneWidget);
    expect(find.text('NONE'), findsWidgets);
    expect(find.text('RAINBOW'), findsOneWidget);
    expect(find.text('GLITCH'), findsOneWidget);
    // Static color frames are hidden from the picker.
    expect(find.text('VIOLET'), findsNothing);
    expect(find.text('CYAN'), findsNothing);
    expect(find.text('CONFIRM'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('dialog fits a tall phone viewport — CONFIRM tappable', (
    t,
  ) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);

    await openPicker(t);
    await openFrameStage(t);

    // No overflow exceptions; confirm exists in the tree and can be
    // scrolled into view + tapped.
    expect(t.takeException(), isNull);
    await t.ensureVisible(find.text('CONFIRM'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('CONFIRM'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600)); // pop transition
    expect(find.text('open'), findsOneWidget); // dialog popped
  });
}
