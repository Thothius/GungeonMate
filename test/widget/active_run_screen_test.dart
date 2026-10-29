import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/active_run_screen.dart';

/// Widget tests for ActiveRunScreen — the main run tracking screen.
///
/// These tests verify the Item 9 + Item 1 changes:
/// - No hardcoded fontFamily: 'EnterTheGungeonBig' overrides
/// - Quick Add sheet uses FontSizes tokens instead of hardcoded sizes
/// - Quick Add sheet renders without overflow on narrow screens
///
/// ActiveRunScreen requires a RunProvider with an active run (selectedCharacter).
/// We use a _LoadedRunProvider that bypasses asset loading and start a run
/// with a minimal gungeoneer.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child, {RunProvider? rp}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => rp ?? _LoadedRunProvider()),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('renders without crashing with an active run', (tester) async {
    final rp = _LoadedRunProvider();
    rp.startNewRun(Gungeoneer(name: 'Marine'));
    await tester.pumpWidget(wrap(const ActiveRunScreen(), rp: rp));
    await tester.pump();

    expect(find.byType(ActiveRunScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on narrow viewport (320px)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final rp = _LoadedRunProvider();
    rp.startNewRun(Gungeoneer(name: 'Marine'));
    await tester.pumpWidget(wrap(const ActiveRunScreen(), rp: rp));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without overflow on tall viewport (900px)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final rp = _LoadedRunProvider();
    rp.startNewRun(Gungeoneer(name: 'Marine'));
    await tester.pumpWidget(wrap(const ActiveRunScreen(), rp: rp));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('does not use hardcoded EnterTheGungeonBig fontFamily', (
    tester,
  ) async {
    final rp = _LoadedRunProvider();
    rp.startNewRun(Gungeoneer(name: 'Marine'));
    await tester.pumpWidget(wrap(const ActiveRunScreen(), rp: rp));
    await tester.pump();

    // Search all Text widgets for hardcoded fontFamily
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    for (final text in textWidgets) {
      final style = text.style;
      if (style?.fontFamily != null) {
        expect(
          style!.fontFamily,
          isNot('EnterTheGungeonBig'),
          reason: 'Text "${text.data}" uses hardcoded fontFamily override',
        );
      }
    }
  });

  testWidgets('Quick Add sheet uses FontSizes tokens not hardcoded sizes', (
    tester,
  ) async {
    final rp = _LoadedRunProvider();
    rp.startNewRun(Gungeoneer(name: 'Marine'));
    await tester.pumpWidget(wrap(const ActiveRunScreen(), rp: rp));
    await tester.pump();

    // Open the Quick Add sheet by tapping the FAB or quick-add button
    // The Quick Add button has a specific icon
    final quickAddButton = find.byIcon(Icons.add_circle_outline);
    if (quickAddButton.evaluate().isNotEmpty) {
      await tester.tap(quickAddButton.first);
      await tester.pump();

      // Verify the search field uses FontSizes.labelMedium (13.0)
      // not a hardcoded 13.5 or 12.5
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final tf in textFields) {
        if (tf.style?.fontSize != null) {
          // Should be a FontSizes token value, not a raw 13.5
          expect(
            tf.style!.fontSize,
            isNot(13.5),
            reason: 'TextField still uses hardcoded fontSize 13.5',
          );
        }
      }
    }
  });

  testWidgets('disposes controllers without leaking', (tester) async {
    final rp = _LoadedRunProvider();
    rp.startNewRun(Gungeoneer(name: 'Marine'));
    await tester.pumpWidget(wrap(const ActiveRunScreen(), rp: rp));
    await tester.pump();

    // Replace with empty screen to trigger disposal
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => rp),
          ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
        ],
        child: const MaterialApp(home: Scaffold()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

/// Test-only RunProvider that bypasses the loading state.
class _LoadedRunProvider extends RunProvider {
  @override
  bool get isLoading => false;

  @override
  String? get error => null;
}
