import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/models/gun.dart';
import 'package:gungeon_mate/models/item.dart';
import 'package:gungeon_mate/models/player.dart';
import 'package:gungeon_mate/widgets/dashboards/dashboard_swiper.dart';

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
}
