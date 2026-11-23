import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/gungeoneer.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/widgets/dashboards/dashboard_swiper.dart';
import 'package:gungeon_mate/widgets/dashboards/huntress_dashboard.dart';

/// U-004 — the 4 trackers cut in 3ef238a + deleted in cd6ddcd were
/// restored; this pins that every special panel builds a tab again.
void main() {
  test('all special panels produce tabs for owned loadout', () {
    final player = Player(
      guns: [
        Gun(name: 'Shellegun'),
        Gun(name: 'Chamber Gun'),
        Gun(name: 'Triple Gun'),
        Gun(name: 'Polaris'),
        Gun(name: 'Gunderfury'),
        Gun(name: 'Evolver'),
        Gun(name: 'Gunther'),
        Gun(name: 'Boxing Glove'),
      ],
      items: [
        Item(name: 'Ser Junkan 1'),
        Item(name: 'Gun Soul'),
        Item(name: 'Platinum Bullets'),
        Item(name: 'Iron Coin'),
        Item(name: 'Spice'),
        Item(name: 'Metronome'),
        Item(name: 'Sprun'),
        Item(name: 'Cigarettes'),
      ],
    );
    final tabs =
        buildDashboardTabs(player, PlayerSlot.main).map((t) => t.label).toSet();
    for (final label in [
      'Shellegun',
      'Chamber Gun',
      'Triple Gun',
      'Polaris',
      'Gunderfury',
      'Evolver',
      'Gunther',
      'Boxing Glove',
      'Junkan',
      'Gun Soul',
      'Platinum',
      'Iron Coin',
      'Spice',
      'Metronome',
      'Sprun',
      'Cigarettes',
    ]) {
      expect(tabs, contains(label), reason: 'missing dashboard tab: $label');
    }
  });

  test('no special items -> no tabs', () {
    final player = Player(guns: [Gun(name: 'Marine Sidearm')]);
    expect(buildDashboardTabs(player, PlayerSlot.main), isEmpty);
  });

  test('huntress + robot character tabs build (U-045 coverage)', () {
    for (final (char, label) in [
      ('The Hunter', 'Huntress'),
      ('The Robot', 'Robot'),
    ]) {
      final tabs = buildDashboardTabs(
        Player(character: Gungeoneer(name: char)),
        PlayerSlot.main,
      );
      expect(tabs.map((t) => t.label), contains(label), reason: char);
    }
  });

  test('huntress tab carries the owning player slot (U-044)', () {
    final tabs = buildDashboardTabs(
      Player(character: Gungeoneer(name: 'The Hunter')),
      PlayerSlot.coop,
    );
    final huntress = tabs.firstWhere((t) => t.label == 'Huntress');
    expect(huntress.widget, isA<HuntressDashboardSliver>());
    expect(
      (huntress.widget as HuntressDashboardSliver).slot,
      PlayerSlot.coop,
    );
  });

  testWidgets('swiper body: pill selects, active pill collapses (U-046)', (
    t,
  ) async {
    DashboardTab tab(String label, String body) => DashboardTab(
      label: label,
      iconPath: '',
      color: Colors.cyanAccent,
      widget: SliverToBoxAdapter(child: Text(body)),
    );
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DashboardSwiperCardBody(
            tabs: [tab('AAA', 'panel-a'), tab('BBB', 'panel-b')],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();

    // First tab selected by default, its content visible.
    expect(find.text('panel-a'), findsOneWidget);

    // Tap second pill -> switches content and expands.
    await t.tap(find.text('BBB'));
    await t.pumpAndSettle();
    expect(find.text('panel-b'), findsOneWidget);

    // Tap active pill again -> collapses content, pills stay.
    await t.tap(find.text('BBB'));
    await t.pumpAndSettle();
    expect(find.text('panel-b'), findsNothing);
    expect(find.text('AAA'), findsOneWidget);
    expect(find.text('BBB'), findsOneWidget);
  });
}
