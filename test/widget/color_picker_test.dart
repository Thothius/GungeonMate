import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/widgets/color_picker_dialog.dart';

/// Widget tests for the HSV color picker dialog.
void main() {
  testWidgets('Dialog renders title, SV panel, hue slider, hex input, and buttons',
      (tester) async {
    Color? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showColorPickerDialog(
                  context,
                  initialColor: Colors.red,
                  title: 'Pick Primary',
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Pick Primary'), findsOneWidget);
    expect(find.text('HEX'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);
    // TextField for hex input
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('DONE returns the current color', (tester) async {
    Color? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showColorPickerDialog(
                  context,
                  initialColor: Colors.blue,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    // The returned color should be blue (or very close — HSV round-trip)
    expect(result!.blue, greaterThan(200));
  });

  testWidgets('CANCEL returns null', (tester) async {
    Color? result = Colors.red; // sentinel
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showColorPickerDialog(
                  context,
                  initialColor: Colors.red,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('Hex input shows initial color hex', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showColorPickerDialog(
                context,
                initialColor: const Color(0xFFFF0000),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // The hex input should show #FF0000
    final textField = find.byType(TextField);
    expect(textField, findsOneWidget);
    final controller = tester.widget<TextField>(textField).controller;
    expect(controller!.text, '#FF0000');
  });

  testWidgets('Tapping SV panel updates hex input', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showColorPickerDialog(
                context,
                initialColor: Colors.white,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Tap on the SV panel — it's the first GestureDetector with onPanDown
    final svPanel = find.byType(GestureDetector).first;
    await tester.tap(svPanel, warnIfMissed: false);
    await tester.pump();

    // Hex should have changed from #FFFFFF
    final controller = tester.widget<TextField>(find.byType(TextField)).controller;
    expect(controller!.text, isNot('#FFFFFF'));
  });
}
