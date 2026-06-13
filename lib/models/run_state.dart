import 'gun.dart';
import 'item.dart';
import 'gungeoneer.dart';
import 'player.dart';

/// State of an ongoing dungeon run. Coolness/curse are shared "dungeon
/// state" — they aren't attributed to one player. Each player has its
/// own loadout of guns+items.
class RunState {
  final Player main;
  final Player? coop;
  final double coolness;
  final double curse;

  /// Chronological log of shrine names used this run. Supports the
  /// Summary page "N shrines used" stat and could power an achievements
  /// system later.
  final List<String> shrinesUsed;

  RunState({
    Player? main,
    this.coop,
    this.coolness = 0.0,
    this.curse = 0.0,
    this.shrinesUsed = const [],
  }) : main = main ?? Player();

  bool get hasCoop => coop != null;

  RunState copyWith({
    Player? main,
    Player? coop,
    bool clearCoop = false,
    double? coolness,
    double? curse,
    List<String>? shrinesUsed,
  }) {
    return RunState(
      main: main ?? this.main,
      coop: clearCoop ? null : (coop ?? this.coop),
      coolness: coolness ?? this.coolness,
      curse: curse ?? this.curse,
      shrinesUsed: shrinesUsed ?? this.shrinesUsed,
    );
  }

  // --- Backward-compatible getters (solo-only callers) -------------------
  Gungeoneer? get selectedCharacter => main.character;
  List<Gun> get activeGuns => main.guns;
  List<Item> get activeItems => main.items;

  /// Names across BOTH players — used for synergy detection where the
  /// dungeon's combined inventory matters. For strictly per-player
  /// perspective use `main.allItemNames` / `coop?.allItemNames`.
  List<String> get allItemNames {
    final out = <String>[...main.allItemNames];
    if (coop != null) out.addAll(coop!.allItemNames);
    return out;
  }

  /// Coolness total = manual base + sum across both players' items/guns.
  double get totalCoolness {
    double total = coolness;
    for (final g in main.guns) { total += g.coolness; }
    for (final i in main.items) { total += i.coolness; }
    if (coop != null) {
      for (final g in coop!.guns) { total += g.coolness; }
      for (final i in coop!.items) { total += i.coolness; }
    }
    return total;
  }

  double get totalCurse {
    double total = curse;
    for (final g in main.guns) { total += g.curse; }
    for (final i in main.items) { total += i.curse; }
    if (coop != null) {
      for (final g in coop!.guns) { total += g.curse; }
      for (final i in coop!.items) { total += i.curse; }
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
        'main': main.toJson(),
        if (coop != null) 'coop': coop!.toJson(),
        'coolness': coolness,
        'curse': curse,
        if (shrinesUsed.isNotEmpty) 'shrines_used': shrinesUsed,
      };

  factory RunState.fromJson(Map<String, dynamic> json) {
    // Handle both new and legacy (pre-0.4.0) serialized formats.
    Player main;
    if (json['main'] != null) {
      main = Player.fromJson(json['main']);
    } else {
      // Legacy shape: {selected_character, active_guns, active_items}
      main = Player(
        character: json['selected_character'] != null
            ? Gungeoneer.fromJson(json['selected_character'])
            : null,
        guns: (json['active_guns'] as List<dynamic>?)
                ?.map((g) => Gun.fromJson(g))
                .toList() ??
            const [],
        items: (json['active_items'] as List<dynamic>?)
                ?.map((i) => Item.fromJson(i))
                .toList() ??
            const [],
      );
    }
    final coop = json['coop'] != null ? Player.fromJson(json['coop']) : null;
    return RunState(
      main: main,
      coop: coop,
      coolness: (json['coolness'] ?? 0).toDouble(),
      curse: (json['curse'] ?? 0).toDouble(),
      shrinesUsed: (json['shrines_used'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
