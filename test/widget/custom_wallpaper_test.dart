import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/widgets/backgrounds/custom_wallpaper.dart';
import 'package:gungeon_mate/widgets/theme_overlay.dart';

/// Widget tests for CustomWallpaper — the custom-theme backdrop with
/// the optional immersive zoom/parallax mode.
///
/// Immersive mode runs a repeating AnimationController, so finite
/// pump() durations are used instead of pumpAndSettle().
void main() {
  const wp = CustomWallpaper(
    assetFileName: 'wp_07.webp',
    scrimColor: Color(0xFF1E1E22),
  );

  setUp(() {
    // Start every test from a clean prefs state.
    VisualPrefs.notifier.value = const VisualPrefs();
  });

  tearDown(() {
    VisualPrefs.notifier.value = const VisualPrefs();
  });

  group('CustomWallpaper widget', () {
    testWidgets('renders statically when immersive is off', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.expand(child: wp))),
      );
      await tester.pump();
      expect(find.byType(CustomWallpaper), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders + animates when immersive is on', (tester) async {
      VisualPrefs.notifier.value = const VisualPrefs(
        wallpaperImmersive: true,
      );
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.expand(child: wp))),
      );
      await tester.pump();
      // Let the zoom loop tick a few frames.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CustomWallpaper), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('immersive off→on→off transitions cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.expand(child: wp))),
      );
      await tester.pump();
      VisualPrefs.notifier.value = const VisualPrefs(
        wallpaperImmersive: true,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      VisualPrefs.notifier.value = const VisualPrefs();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduced-motion still renders the wallpaper', (tester) async {
      VisualPrefs.notifier.value = const VisualPrefs(
        wallpaperImmersive: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(body: SizedBox.expand(child: wp)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CustomWallpaper), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tilt stream does not crash immersive mode', (tester) async {
      VisualPrefs.notifier.value = const VisualPrefs(
        wallpaperImmersive: true,
      );
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.expand(child: wp))),
      );
      await tester.pump();
      // Simulate the accelerometer stream feeding tilt values.
      ThemeOverlay.tiltNotifier.value = const Offset(6, -4);
      await tester.pump(const Duration(milliseconds: 300));
      ThemeOverlay.tiltNotifier.value = Offset.zero;
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('no controller leak after disposal', (tester) async {
      VisualPrefs.notifier.value = const VisualPrefs(
        wallpaperImmersive: true,
      );
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.expand(child: wp))),
      );
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('VisualPrefs wallpaperImmersive', () {
    test('defaults to off', () {
      expect(const VisualPrefs().wallpaperImmersive, isFalse);
    });

    test('JSON round-trip preserves the flag', () {
      const prefs = VisualPrefs(wallpaperImmersive: true);
      final restored = VisualPrefs.fromJson(prefs.toJson());
      expect(restored.wallpaperImmersive, isTrue);
    });
  });
}
