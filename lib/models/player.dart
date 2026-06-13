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

  Player({
    this.character,
    this.guns = const [],
    this.items = const [],
  });

  Player copyWith({
    Gungeoneer? character,
    List<Gun>? guns,
    List<Item>? items,
  }) {
    return Player(
      character: character ?? this.character,
      guns: guns ?? this.guns,
      items: items ?? this.items,
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
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        character: json['character'] != null
            ? Gungeoneer.fromJson(json['character'])
            : null,
        guns: (json['guns'] as List<dynamic>?)
                ?.map((g) => Gun.fromJson(g))
                .toList() ??
            const [],
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => Item.fromJson(i))
                .toList() ??
            const [],
      );
}
