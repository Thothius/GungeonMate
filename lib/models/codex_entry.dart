/// A single entry in the GungeonMate Codex — covers Objects, Pickups, NPCs,
/// Enemies, and Bosses. All JSON files share the same shape, so one model
/// handles them all.
class CodexEntry {
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

  CodexEntry({
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

  factory CodexEntry.fromJson(Map<String, dynamic> j) {
    return CodexEntry(
      name: j['name'] as String? ?? '',
      category: j['category'] as String? ?? '',
      description: j['description'] as String? ?? '',
      icon: j['icon'] as String? ?? '',
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
        return 'codex';
      default:
        // Pickups have their own categories like Currency, Health, etc.
        // Objects have categories like Barrel, Chest, Trap, etc.
        // We distinguish by the icon extension or by known pickup categories.
        return 'objects'; // default
    }
  }
}

/// Which codex section a list belongs to.
enum CodexSection { objects, pickups, npcs, enemies, bosses, guns, items, synergies, shrines, chapters, gameModes }

/// Helper to resolve the image folder for a codex section.
String codexImageFolder(CodexSection section) {
  switch (section) {
    case CodexSection.objects:
      return 'objects';
    case CodexSection.pickups:
      return 'pickups';
    case CodexSection.npcs:
      return 'npcs';
    case CodexSection.enemies:
      return 'enemies';
    case CodexSection.bosses:
      return 'bosses';
    case CodexSection.guns:
      return 'guns';
    case CodexSection.items:
      return 'items';
    case CodexSection.synergies:
      return 'codex';
    case CodexSection.shrines:
      return 'shrines';
    case CodexSection.chapters:
    case CodexSection.gameModes:
      return 'codex';
  }
}

/// Build the full asset path for a codex entry given its section.
/// Icons that already carry a folder prefix (e.g. `guns/x.png` from
/// cross-category fabrication like synergy anchor icons) are used
/// as-is rather than resolved under the section folder.
String codexAssetPath(CodexSection section, String icon) {
  if (icon.isEmpty) return '';
  if (icon.contains('/')) return 'assets/images/$icon';
  return 'assets/images/${codexImageFolder(section)}/$icon';
}
