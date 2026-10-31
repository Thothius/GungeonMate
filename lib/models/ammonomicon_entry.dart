/// A single entry in the GungeonMate Ammonomicon — covers Objects, Pickups, NPCs,
/// Enemies, and Bosses. All JSON files share the same shape, so one model
/// handles them all.
class AmmonomiconEntry {
  final String name;
  final String category;
  final String description;
  final String icon;
  final String wikiUrl;
  final String? location;
  final String? game;
  final String? health;
  final String? ammonomicon;
  final List<String> tips;

  AmmonomiconEntry({
    required this.name,
    this.category = '',
    this.description = '',
    this.icon = '',
    this.wikiUrl = '',
    this.location,
    this.game,
    this.health,
    this.ammonomicon,
    this.tips = const [],
  });

  factory AmmonomiconEntry.fromJson(Map<String, dynamic> j) {
    return AmmonomiconEntry(
      name: j['name'] as String? ?? '',
      category: j['category'] as String? ?? '',
      description: j['description'] as String? ?? '',
      icon: (j['game_icon'] as String? ?? j['icon'] as String? ?? ''),
      wikiUrl: j['wiki_url'] as String? ?? '',
      location: j['location'] as String?,
      game: j['game'] as String?,
      health: j['health'] as String?,
      ammonomicon: j['ammonomicon'] as String?,
      tips:
          (j['tips'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
    );
  }

  /// Local asset path for the icon. Objects use .png/.gif, pickups .png,
  /// NPCs .png — all stored in assets/images/{kind}/{slug}.{ext}.
  /// The icon field in JSON already carries the filename, so we just
  /// prefix the appropriate folder.
  String get assetPath {
    if (icon.isEmpty) return '';
    if (icon.startsWith('assets/')) return icon;
    // Determine folder from category or game field.
    final folder = _folderForCategory(category);
    return 'assets/images/$folder/$icon';
  }

  static String _folderForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'major npc':
      case 'minor npc':
      case 'other npc':
        return 'npcs';
      case 'guns':
        return 'guns';
      case 'items':
        return 'items';
      case 'synergies':
        return 'ammonomicon';
      default:
        // Pickups have their own categories like Currency, Health, etc.
        // Objects have categories like Barrel, Chest, Trap, etc.
        // We distinguish by the icon extension or by known pickup categories.
        return 'objects'; // default
    }
  }
}

/// Which ammonomicon section a list belongs to.
enum AmmonomiconSection { objects, pickups, npcs, enemies, bosses, guns, items, synergies, shrines, chapters, gameModes }

/// Helper to resolve the image folder for a ammonomicon section.
String ammonomiconImageFolder(AmmonomiconSection section) {
  switch (section) {
    case AmmonomiconSection.objects:
      return 'objects';
    case AmmonomiconSection.pickups:
      return 'pickups';
    case AmmonomiconSection.npcs:
      return 'npcs';
    case AmmonomiconSection.enemies:
      return 'enemies';
    case AmmonomiconSection.bosses:
      return 'bosses';
    case AmmonomiconSection.guns:
      return 'guns';
    case AmmonomiconSection.items:
      return 'items';
    case AmmonomiconSection.synergies:
      return 'ammonomicon';
    case AmmonomiconSection.shrines:
      return 'shrines';
    case AmmonomiconSection.chapters:
    case AmmonomiconSection.gameModes:
      return 'ammonomicon';
  }
}

/// Build the full asset path for a ammonomicon entry given its section.
/// Icons that already carry a folder prefix (e.g. `guns/x.png` from
/// cross-category fabrication like synergy anchor icons) are used
/// as-is rather than resolved under the section folder.
String ammonomiconAssetPath(AmmonomiconSection section, String icon) {
  if (icon.isEmpty) return '';
  if (icon.startsWith('assets/')) return icon;
  if (icon.contains('/')) return 'assets/images/$icon';
  return 'assets/images/${ammonomiconImageFolder(section)}/$icon';
}
