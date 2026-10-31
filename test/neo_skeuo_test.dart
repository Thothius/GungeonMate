import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/main_menu_screen.dart';
import 'package:gungeon_mate/widgets/home/home_backdrop.dart';
import 'package:gungeon_mate/widgets/skeuo/skeuo_backdrop.dart';
import 'package:gungeon_mate/widgets/skeuo/skeuo_tokens.dart';
import 'package:gungeon_mate/utils/contrast.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Neo-Skeuo mode tests — the alternate hand-drawn skin: theme-mode
/// plumbing, enter/exit restore semantics, list membership rules,
/// light-scheme wiring, and the skeuo home-menu swap.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppTheme.previewNotifier.value = null;
    AppTheme.notifier.value = AppThemeMode.paperInk;
    VisualPrefs.notifier.value = const VisualPrefs();
  });

  group('Neo-Skeuo mode plumbing', () {
    test('is in kVisibleThemes (persists through init migration)', () {
      expect(kVisibleThemes, contains(AppThemeMode.neoSkeuo));
    });

    test('is NOT in kPickerThemes (toggle-only, studio locked)', () {
      expect(kPickerThemes, isNot(contains(AppThemeMode.neoSkeuo)));
    });

    test('flair carries no font so entering never clobbers VisualPrefs', () {
      expect(AppThemeMode.neoSkeuo.flair.font, isNull);
      expect(kThemeCuration[AppThemeMode.neoSkeuo], isNull);
      expect(kThemeParticleDefaults[AppThemeMode.neoSkeuo], isNull);
    });

    test('themeFor resolves the bundled sketch font + light scheme', () {
      final theme = AppTheme.themeFor(AppThemeMode.neoSkeuo);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'ArchitectsDaughter');
    });

    test('ink on paper passes body-text contrast', () {
      expect(
        Contrast.passesBody(Skeuo.ink, Skeuo.paper),
        isTrue,
        reason: 'ink on cream must clear 4.5:1',
      );
      expect(Contrast.passesBody(Skeuo.pencil, Skeuo.paper), isTrue);
      expect(Contrast.passesBody(Skeuo.ink, Skeuo.card), isTrue);
    });
  });

  group('enter/exit restore', () {
    test('enterSkeuo saves prev mode + font, exit restores both', () async {
      AppTheme.notifier.value = AppThemeMode.unicorn;
      await VisualPrefs.setFont(AppFont.fredoka);

      await AppTheme.enterSkeuo();
      expect(AppTheme.mode, AppThemeMode.neoSkeuo);
      expect(AppTheme.isSkeuo, isTrue);

      await AppTheme.exitSkeuo();
      expect(AppTheme.mode, AppThemeMode.unicorn);
      expect(AppTheme.isSkeuo, isFalse);
      expect(VisualPrefs.notifier.value.font, AppFont.fredoka);
    });

    test('exit without a saved prev falls back to defaults', () async {
      AppTheme.notifier.value = AppThemeMode.neoSkeuo;
      await AppTheme.exitSkeuo();
      expect(AppTheme.mode, AppThemeMode.paperInk);
      expect(VisualPrefs.notifier.value.font, AppFont.gungeon);
    });

    test('enterSkeuo is a no-op when already skeuo', () async {
      AppTheme.notifier.value = AppThemeMode.neoSkeuo;
      await AppTheme.enterSkeuo();
      expect(AppTheme.mode, AppThemeMode.neoSkeuo);
    });
  });

  group('skeuo home menu', () {
    Widget wrap(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RunProvider()),
          ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
        ],
        child: MaterialApp(
          theme: AppTheme.themeFor(AppThemeMode.neoSkeuo),
          home: child,
        ),
      );
    }

    testWidgets('skeuo menu shows paper backdrop, DEMO, locked Customization', (
      tester,
    ) async {
      AppTheme.notifier.value = AppThemeMode.neoSkeuo;
      await tester.pumpWidget(wrap(const MainMenuScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SkeuoPaperBackdrop), findsOneWidget);
      expect(find.byType(MainMenuBackdrop), findsNothing);
      expect(find.text('Style Demo'), findsOneWidget);
      expect(find.text('Customization'), findsOneWidget);
      expect(find.text('Local Run'), findsOneWidget);
      // Locked button shows the lock icon instead of the palette.
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.draw_rounded), findsOneWidget);
    });

    testWidgets('toggle exits skeuo back to ember menu', (tester) async {
      AppTheme.notifier.value = AppThemeMode.neoSkeuo;
      await tester.pumpWidget(wrap(const MainMenuScreen()));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.draw_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 600));

      expect(AppTheme.isSkeuo, isFalse);
      expect(find.byType(MainMenuBackdrop), findsOneWidget);
      expect(find.text('Style Demo'), findsNothing);
    });
  });
}
