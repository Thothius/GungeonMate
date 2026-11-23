import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/services/app_theme.dart';
import 'package:gungeon_mate/widgets/avatar_aura.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders child when disabled', (tester) async {
    await tester.pumpWidget(wrap(
      const AvatarAura(
        enabled: false,
        size: 48,
        child: Icon(Icons.person),
      ),
    ));
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every theme mode paints its aura style without exception',
      (tester) async {
    final before = AppTheme.mode;
    addTearDown(() async => AppTheme.setMode(before));

    for (final mode in AppThemeMode.values) {
      await AppTheme.setMode(mode);
      await tester.pumpWidget(wrap(
        const AvatarAura(
          size: 48,
          child: Icon(Icons.person, size: 32),
        ),
      ));
      // Advance the aura ticker a few frames.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull,
          reason: 'aura threw under mode $mode');
      expect(find.byType(AvatarAura), findsOneWidget);
    }
  });
}
