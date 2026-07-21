/// A single entry in the GungeonMate Codex — covers Objects, Pickups, and NPCs.
/// All three JSON files (objects.json, pickups.json, npcs.json) share the same
/// shape, so one model handles them all.
class CodexEntry {
  final String name;
  final String category;
  final String description;
  final String icon;
  final String wikiUrl;
  final String? location;
  final String? game;

  CodexEntry({
    required this.name,
    this.category = '',
    this.description = '',
    this.icon = '',
    this.wikiUrl = '',
    this.location,
    this.game,
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
      default:
        // Pickups have their own categories like Currency, Health, etc.
        // Objects have categories like Barrel, Chest, Trap, etc.
        // We distinguish by the icon extension or by known pickup categories.
        return 'objects'; // default
    }
  }
}

/// Which codex section a list belongs to.
enum CodexSection { objects, pickups, npcs }

/// Helper to resolve the image folder for a codex section.
String codexImageFolder(CodexSection section) {
  switch (section) {
    case CodexSection.objects:
      return 'objects';
    case CodexSection.pickups:
      return 'pickups';
    case CodexSection.npcs:
      return 'npcs';
  }
}

/// Build the full asset path for a codex entry given its section.
String codexAssetPath(CodexSection section, String icon) {
  if (icon.isEmpty) return '';
  return 'assets/images/${codexImageFolder(section)}/$icon';
}
