import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/widgets/codex/ammonomicon_tabs.dart';

/// Widget tests for AmmonomiconTabStrip — the bookmark-style category tabs.
///
/// These tests verify the Item 3 change: inactive tab icons should NOT
/// be tinted/recolored via BlendMode.srcIn. The pixel art should show
/// at full opacity for both active and inactive states.
///
/// AmmonomiconTabStrip uses flutter_animate entrance animations, so
/// pumpAndSettle is safe after animations complete.
void main() {
  final _testTabs = <AmmonomiconTab>[
    const AmmonomiconTab(
      label: 'Guns',
      icon: Icons.gps_fixed,
      color: Colors.amber,
      isSpecial: false,
    ),
    const AmmonomiconTab(
      label: 'Items',
      icon: Icons.inventory_2,
      color: Colors.cyan,
      isSpecial: false,
    ),
    const AmmonomiconTab(
      label: 'NPCs',
      icon: Icons.person,
      color: Colors.green,
      isSpecial: true,
    ),
  ];

  Widget _wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('renders all tab labels', (tester) async {
    await tester.pumpWidget(_wrap(
      AmmonomiconTabStrip(
        tabs: _testTabs,
        selected: 0,
        collapsed: false,
        onSelect: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Guns'), findsOneWidget);
    expect(find.text('Items'), findsOneWidget);
    expect(find.text('NPCs'), findsOneWidget);
  });

  testWidgets('renders Material icons for tabs without asset icons',
      (tester) async {
    await tester.pumpWidget(_wrap(
      AmmonomiconTabStrip(
        tabs: _testTabs,
        selected: 0,
        collapsed: false,
        onSelect: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('inactive tab icons do not use BlendMode.srcIn color tint',
      (tester) async {
    await tester.pumpWidget(_wrap(
      AmmonomiconTabStrip(
        tabs: _testTabs,
        selected: 0, // First tab active, others inactive
        collapsed: false,
        onSelect: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    // Check all Image widgets — none should have color + BlendMode.srcIn
    final images = tester.widgetList<Image>(find.byType(Image));
    for (final img in images) {
      if (img.color != null) {
        expect(
          img.colorBlendMode,
          isNot(BlendMode.srcIn),
          reason: 'Image should not use BlendMode.srcIn — it replaces '
              'pixel art with a solid color silhouette',
        );
      }
    }
  });

  testWidgets('active tab icon also does not use BlendMode.srcIn',
      (tester) async {
    await tester.pumpWidget(_wrap(
      AmmonomiconTabStrip(
        tabs: _testTabs,
        selected: 1, // Second tab active
        collapsed: false,
        onSelect: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    final images = tester.widgetList<Image>(find.byType(Image));
    for (final img in images) {
      if (img.color != null) {
        expect(
          img.colorBlendMode,
          isNot(BlendMode.srcIn),
          reason: 'Active tab image should not use BlendMode.srcIn',
        );
      }
    }
  });

  testWidgets('tapping a tab calls onSelect with correct index',
      (tester) async {
    int? selectedIndex;
    await tester.pumpWidget(_wrap(
      AmmonomiconTabStrip(
        tabs: _testTabs,
        selected: 0,
        collapsed: false,
        onSelect: (i) => selectedIndex = i,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Items'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
  });

  testWidgets('renders without overflow on narrow viewport (320px)',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(
      AmmonomiconTabStrip(
        tabs: _testTabs,
        selected: 0,
        collapsed: false,
        onSelect: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders collapsed state without crashing', (tester) async {
    await tester.pumpWidget(_wrap(
      AmmonomiconTabStrip(
        tabs: _testTabs,
        selected: 0,
        collapsed: true,
        onSelect: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders with asset icon tabs without crashing', (tester) async {
    final assetTabs = <AmmonomiconTab>[
      AmmonomiconTab(
        label: 'Guns',
        assetIcon: 'guns_tab',
        color: Colors.amber,
        isSpecial: false,
      ),
      AmmonomiconTab(
        label: 'Items',
        assetIcon: 'items_tab',
        color: Colors.cyan,
        isSpecial: false,
      ),
    ];

    await tester.pumpWidget(_wrap(
      AmmonomiconTabStrip(
        tabs: assetTabs,
        selected: 0,
        collapsed: false,
        onSelect: (_) {},
      ),
    ));
    await tester.pumpAndSettle();

    // Asset images will fail to load in tests (no real assets), but
    // the errorBuilder should fall back to Material icons
    expect(tester.takeException(), isNull);
  });
}
