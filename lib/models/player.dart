import 'gun.dart';
import 'item.dart';
import 'gungeoneer.dart';

/// Which player slot in a (potentially co-op) run.
enum PlayerSlot { main, coop }

/// A single Gungeoneer loadout in an active run. In solo play, only the
/// `main` slot is used. For local co-op tracking, the `coop` slot holds
/// a second independent loadout.
class Player {
  final Gungeoneer? character;
  final List<Gun> guns;
  final List<Item> items;

  /// Names of gear stashed in this player's Backpack, keyed
  /// `'g:<GunName>'` / `'i:<ItemName>'`. Stashed gear stays in
  /// [guns]/[items] — it still counts for synergies, passives, DPS and
  /// coolness/curse; the keys only hide it from the open inventory
  /// grid. Local per-player, per-run; serialized with the run.
  final Set<String> backpackKeys;

  Player({
    this.character,
    this.guns = const [],
    this.items = const [],
    this.backpackKeys = const {},
  });

  Player copyWith({
    Gungeoneer? character,
    List<Gun>? guns,
    List<Item>? items,
    Set<String>? backpackKeys,
  }) {
    return Player(
      character: character ?? this.character,
      guns: guns ?? this.guns,
      items: items ?? this.items,
      backpackKeys: backpackKeys ?? this.backpackKeys,
    );
  }

  /// Names of all owned guns + items (preserves original casing).
  List<String> get allItemNames => [
    ...guns.map((g) => g.name),
    ...items.map((i) => i.name),
  ];

  Map<String, dynamic> toJson() => {
    'character': character?.toJson(),
    'guns': guns.map((g) => g.toJson()).toList(),
    'items': items.map((i) => i.toJson()).toList(),
    if (backpackKeys.isNotEmpty) 'backpack': backpackKeys.toList(),
  };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
    character:
        json['character'] != null
            ? Gungeoneer.fromJson(json['character'])
            : null,
    guns:
        (json['guns'] as List<dynamic>?)
            ?.map((g) => Gun.fromJson(g))
            .toList() ??
        const [],
    items:
        (json['items'] as List<dynamic>?)
            ?.map((i) => Item.fromJson(i))
            .toList() ??
        const [],
    backpackKeys:
        (json['backpack'] as List<dynamic>?)?.cast<String>().toSet() ??
        const {},
  );
}
