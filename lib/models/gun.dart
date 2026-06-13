import '../utils/asset_paths.dart';
import 'rich_text.dart';

class Gun {
  final String name;
  final String icon;
  final String notes;
  final String quote;
  final String quality;
  final String type;
  final String dps;
  final String magazineSize;
  final String ammoCapacity;
  final String damage;
  final String fireRate;
  final String reloadTime;
  final String shotSpeed;
  final String range;
  final String force;
  final String spread;
  final String gunClass;
  final String sellPrice;
  final String chestColor;
  final double curse;
  final double coolness;

  /// Rich wiki sections (Effects/Interactions/Notes/Tips/Trivia) sourced
  /// from `parse_wiki_rich.py`. May be [WikiContent.empty] for the small
  /// number of guns whose wiki page wasn't in cache.
  final WikiContent wiki;

  Gun({
    required this.name,
    this.icon = '',
    this.notes = '',
    this.quote = '',
    this.quality = '',
    this.type = '',
    this.dps = '',
    this.magazineSize = '',
    this.ammoCapacity = '',
    this.damage = '',
    this.fireRate = '',
    this.reloadTime = '',
    this.shotSpeed = '',
    this.range = '',
    this.force = '',
    this.spread = '',
    this.gunClass = '',
    this.sellPrice = '',
    this.chestColor = '',
    this.curse = 0.0,
    this.coolness = 0.0,
    this.wiki = WikiContent.empty,
  });

  /// Numeric DPS for sorting. Returns 0 if not parseable.
  double get dpsValue {
    if (dps.isEmpty) return 0;
    final m = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(dps);
    return m == null ? 0 : double.tryParse(m.group(0)!) ?? 0;
  }

  /// Calculates dynamic, form-stateful DPS for weapons with multiple modes
  /// (Gunderfury, Triple Gun, Evolver) based on active state parameters.
  double getDynamicDps({int gunderLevel = 1, int tripleForm = 1, int evolverStage = 1}) {
    final nameLower = name.toLowerCase();
    if (nameLower == 'gunderfury') {
      if (gunderLevel < 30) return 22.5;
      if (gunderLevel < 60) return 45.5;
      return 75.0;
    }
    if (nameLower == 'triple gun') {
      if (tripleForm == 1) return 18.0;
      if (tripleForm == 2) return 28.5;
      return 55.0;
    }
    if (nameLower == 'evolver') {
      switch (evolverStage) {
        case 1: return 13.5;
        case 2: return 19.1;
        case 3: return 25.8;
        case 4: return 34.5;
        case 5: return 23.0;
        default: return 93.8;
      }
    }
    return dpsValue;
  }

  factory Gun.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return Gun(
      name: name,
      // Ignore the JSON's wiki URL — bundled local sprite by name slug.
      icon: localGunIcon(name),
      notes: json['notes'] ?? '',
      quote: json['quote'] ?? '',
      quality: json['quality'] ?? '',
      type: json['type'] ?? '',
      dps: json['dps'] ?? '',
      magazineSize: json['magazine_size'] ?? '',
      ammoCapacity: json['ammo_capacity'] ?? '',
      damage: json['damage'] ?? '',
      fireRate: json['fire_rate'] ?? '',
      reloadTime: json['reload_time'] ?? '',
      shotSpeed: json['shot_speed'] ?? '',
      range: json['range'] ?? '',
      force: json['force'] ?? '',
      spread: json['spread'] ?? '',
      gunClass: json['class'] ?? '',
      sellPrice: json['sell_price']?.toString() ?? '',
      chestColor: json['chest_color'] ?? '',
      curse: (json['curse'] ?? 0).toDouble(),
      coolness: (json['coolness'] ?? 0).toDouble(),
      wiki: WikiContent.fromJson(json['wiki'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'notes': notes,
      'quote': quote,
      'quality': quality,
      'type': type,
      'dps': dps,
      'magazine_size': magazineSize,
      'ammo_capacity': ammoCapacity,
      'damage': damage,
      'fire_rate': fireRate,
      'reload_time': reloadTime,
      'shot_speed': shotSpeed,
      'range': range,
      'force': force,
      'spread': spread,
      'class': gunClass,
      'sell_price': sellPrice,
      'chest_color': chestColor,
      'curse': curse,
      'coolness': coolness,
    };
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

  /// Chest color for display. Uses the explicit field if present,
  /// otherwise derives from quality.
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
