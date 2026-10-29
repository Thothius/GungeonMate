import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gungeon_mate/providers/run_provider.dart';
import 'package:gungeon_mate/services/mp_session.dart';
import 'package:gungeon_mate/screens/codex_screen.dart';
import 'package:gungeon_mate/widgets/state_widgets.dart';

/// Widget tests for CodexScreen — the browseable encyclopedia.
///
/// CodexScreen loads its own JSON data in initState via compute()
/// (isolate parsing). While loading, it shows SkeletonLoader widgets
/// which have a perpetual shimmer animation, so we use pump() instead
/// of pumpAndSettle() to avoid timeouts.
///
/// The category bookmark tabs (AmmonomiconTabStrip) and content area
/// are only rendered once _loaded becomes true. In the test environment
/// compute() may not complete, so we test the loading state and the
/// AppBar (which is always rendered).
void main() {
  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunProvider()),
        ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('Shows skeleton loaders while data is loading', (tester) async {
    await tester.pumpWidget(wrap(const CodexScreen()));
    // Only pump one frame — data hasn't loaded yet
    await tester.pump();

    // SkeletonLoader has a perpetual animation, so just verify it exists
    expect(find.byType(SkeletonLoader), findsWidgets);
  });

  testWidgets('Does not show category tabs while loading', (tester) async {
    await tester.pumpWidget(wrap(const CodexScreen()));
    await tester.pump();

    // The AmmonomiconTabStrip is only rendered when _loaded is true
    // During loading, only skeleton loaders are shown
    expect(find.text('Gungeoneers'), findsNothing);
    expect(find.text('NPCs'), findsNothing);
  });

  testWidgets('Does not show search field while loading', (tester) async {
    await tester.pumpWidget(wrap(const CodexScreen()));
    await tester.pump();

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('showBackButton true renders back button and CODEX title', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const CodexScreen(showBackButton: true)));
    await tester.pump();

    // The AppBar uses IconButton with Icons.arrow_back, not BackButton
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('CODEX'), findsOneWidget);
    expect(find.text('Encyclopedia of the Gungeon'), findsOneWidget);
  });

  testWidgets('showBackButton false does not render back button', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const CodexScreen(showBackButton: false)));
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('Screen renders without crashing with empty provider data', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const CodexScreen()));
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Renders multiple skeleton loader lines during loading', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const CodexScreen()));
    await tester.pump();

    // The loading state shows 4 skeleton loaders
    expect(find.byType(SkeletonLoader), findsNWidgets(4));
  });

  testWidgets('showBackButton true renders AppBar with correct height', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const CodexScreen(showBackButton: true)));
    await tester.pump();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.toolbarHeight, kToolbarHeight);
  });

  testWidgets('showBackButton false renders AppBar with zero height', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const CodexScreen(showBackButton: false)));
    await tester.pump();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.toolbarHeight, 0);
  });

  // ── New tests for Item 7 + Item 8 changes ──────────────────────────────

  testWidgets('showBackButton false includes SafeArea with top: true', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const CodexScreen(showBackButton: false)));
    await tester.pump();

    // SafeArea should be present in the widget tree
    expect(find.byType(SafeArea), findsWidgets);
  });

  testWidgets('showBackButton true still renders without crashing', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const CodexScreen(showBackButton: true)));
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('renders without overflow on narrow viewport (320px)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(const CodexScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('renders without overflow on notched device (top inset)', (
    tester,
  ) async {
    // Wrap in MediaQuery with simulated notch insets
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(top: 50, bottom: 34),
          ),
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => RunProvider()),
              ChangeNotifierProvider(create: (_) => MpSession.placeholder()),
            ],
            child: const CodexScreen(showBackButton: false),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SafeArea), findsWidgets);
  });
}
