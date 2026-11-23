import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/screens/active_run_screen.dart';
import 'package:gungeon_mate/screens/experience_studio_screen.dart';
import 'package:gungeon_mate/screens/main_menu_screen.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/services/mp_session.dart';

/// S5.0 — visual-regression smoke net for the three highest-value
/// surfaces. Widget tests prove behavior; this suite proves the app
/// still *renders* — the U-001 blank-screen bug class. Each test pumps
/// the real screen, asserts key anchors exist, and requires
/// `takeException()` to be null (layout overflows fail silently
/// otherwise).
///
/// Perpetual animations (backdrop, particles) mean `pumpAndSettle`
/// never finishes — all pumps use fixed durations, and the final pump
/// clears RunProvider's ~400ms autosave debounce.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Tall surface so lazy lists build their children for asserts.
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher
        .implicitView!;
    view.physicalSize = const Size(800, 1600);
    view.devicePixelRatio = 1.0;
    AppTheme.previewNotifier.value = null;
    AppTheme.setCustomThemeData(CustomThemeData.defaultTheme);
    CustomThemeStore.notifier.value = [];
    VisualPrefs.notifier.value = const VisualPrefs();
  });

  tearDown(() {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher
        .implicitView!;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  Widget wrap(Widget child, {RunProvider? rp}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => rp ?? RunProvider()),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('smoke: main menu renders title + primary actions', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const MainMenuScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('GUNGEON MATE'), findsWidgets);
    expect(find.text('Local Run'), findsOneWidget);
    expect(find.text('Multiplayer'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('smoke: active run renders with a started run', (tester) async {
    final rp = _LoadedRunProvider();
    rp.startNewRun(Gungeoneer(name: 'Marine'));
    await tester.pumpWidget(wrap(const ActiveRunScreen(), rp: rp));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(ActiveRunScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('smoke: customization studio renders preset flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ExperienceStudioScreen()),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Choose-stage anchors: CUSTOMIZE header + the two flow cards.
    expect(find.text('CUSTOMIZE'), findsWidgets);
    expect(find.text('NEW PRESET'), findsOneWidget);
    expect(find.text('BROWSE PRESETS'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 500));
  });
}

/// Test-only RunProvider that bypasses the loading state — same
/// pattern as active_run_screen_test.dart.
class _LoadedRunProvider extends RunProvider {
  @override
  bool get isLoading => false;

  @override
  String? get error => null;
}
