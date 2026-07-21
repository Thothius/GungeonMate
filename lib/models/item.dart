import '../utils/asset_paths.dart';
import 'rich_text.dart';

class Item {
  final String name;
  final String icon;
  final String type;
  final String effect;
  final String quote;
  final String quality;
  final String sellPrice;
  final String chestColor;
  final String rechargeTime;

  /// How long the active effect lasts (e.g. "10s", "5 seconds").
  /// Empty for passive items and actives without a duration.
  final String duration;

  final double curse;
  final double coolness;

  /// Rich wiki sections (Effects/Interactions/Notes/Tips/Trivia) sourced
  /// from `parse_wiki_rich.py`. May be [WikiContent.empty] for the small
  /// number of items whose wiki page wasn't in cache.
  final WikiContent wiki;

  Item({
    required this.name,
    this.icon = '',
    this.type = '',
    this.effect = '',
    this.quote = '',
    this.quality = '',
    this.sellPrice = '',
    this.chestColor = '',
    this.rechargeTime = '',
    this.duration = '',
    this.curse = 0.0,
    this.coolness = 0.0,
    this.wiki = WikiContent.empty,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return Item(
      name: name,
      icon: localItemIcon(name),
      type: json['type'] ?? '',
      effect: json['effect'] ?? '',
      quote: json['quote'] ?? '',
      quality: json['quality'] ?? '',
      sellPrice: json['sell_price']?.toString() ?? '',
      chestColor: json['chest_color'] ?? '',
      rechargeTime: json['recharge_time'] ?? '',
      duration: json['duration'] ?? '',
      curse: (json['curse'] ?? 0).toDouble(),
      coolness: (json['coolness'] ?? 0).toDouble(),
      wiki: WikiContent.fromJson(json['wiki'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'type': type,
      'effect': effect,
      'quote': quote,
      'quality': quality,
      'sell_price': sellPrice,
      'chest_color': chestColor,
      'recharge_time': rechargeTime,
      'duration': duration,
      'curse': curse,
      'coolness': coolness,
    };
  }

  /// Is this a companion item? Wiki data doesn't distinguish companions —
  /// they're all tagged "Passive". Detect heuristically from effect text
  /// or a known-companion allow-list.
  static const Set<String> _knownCompanions = {
    'dog',
    'owl',
    'r2g2',
    'space friend',
    'super space turtle',
    'baby good mimic',
    'baby good shelleton',
    'chicken flute',
    'ser junkan',
    'ser junkan 1',
    'turkey',
    'wolf',
    'pig',
    'orange',
    'huntsman',
    'badge',
    'clown mask',
    'wingman',
  };

  bool get isCompanion {
    if (_knownCompanions.contains(name.toLowerCase())) return true;
    final t = type.toLowerCase();
    if (t.contains('companion')) return true;
    final e = effect.toLowerCase();
    if (e.contains('follows the player') ||
        e.contains('follows you') ||
        e.contains('follows the gungeoneer') ||
        e.contains('summons a friendly') ||
        e.contains('is a companion')) {
      return true;
    }
    return false;
  }

  String get qualityDisplay {
    switch (quality.toUpperCase()) {
      case 'S':
        return 'S-Tier';
      case '1S':
        return 'S-Tier';
      case 'A':
        return 'A-Tier';
      case 'B':
        return 'B-Tier';
      case 'C':
        return 'C-Tier';
      case 'D':
        return 'D-Tier';
      case 'N':
        return 'Starting';
      default:
        return quality;
    }
  }

  bool get isActive => type.toLowerCase().contains('active');
  bool get isPassive => type.toLowerCase().contains('passive');

  /// Heuristic: this active item is destroyed / consumed when used, so
  /// after use it leaves the loadout. Scans the effect text for common
  /// wiki phrases that indicate single-use consumption.
  bool get isDestroyedOnUse {
    if (!isActive) return false;
    final e = effect.toLowerCase();
    // Direct keyword hits — wiki writers vary wording a lot.
    const phrases = [
      'is consumed on use',
      'consumed on use',
      'is consumed when used',
      'consumed when used',
      'is destroyed on use',
      'destroyed on use',
      'is destroyed when used',
      'destroyed when used',
      'single-use',
      'single use',
      'one-time use',
      'one use only',
      'disappears after use',
      'breaks on use',
      'shatters on use',
      'one-shot',
      'this consumes the item',
      'consumes itself',
    ];
    for (final p in phrases) {
      if (e.contains(p)) return true;
    }
    return false;
  }

  /// Chest color for display. Uses the explicit field if present,
  /// otherwise derives from quality (D=brown, C=blue, B=green, A=red,
  /// S/1S=black). Returns empty for N (starting) items.
  String get chestColorDisplay {
    if (chestColor.isNotEmpty) return chestColor;
    switch (quality.toUpperCase()) {
      case 'D':
        return 'brown';
      case 'C':
        return 'blue';
      case 'B':
        return 'green';
      case 'A':
        return 'red';
      case 'S':
      case '1S':
        return 'black';
    }
    return '';
  }
}
