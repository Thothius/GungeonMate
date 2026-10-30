// Helpers for deriving local asset paths from entity names.
//
// Background: the bundled JSON data files (`guns.json`, `items.json`,
// `gungeoneers.json`, `shrines.json`) carry the wiki's full HTTPS URL
// in their `icon` field — we don't fetch from the wiki at runtime.
// Local sprite files in `assets/images/<kind>/<slug>.webp` are
// pre-bundled with the build, named after each entity using a simple
// slug rule:
//
//   "AC-15"           → ac_15.webp
//   "Smiley's Revolver" → smiley_s_revolver.webp
//   "Mr. Accretion Jr." → mr_accretion_jr.webp
//   "The Marine"       → the_marine.webp
//
// Rule: lowercase the name, replace every run of non-alphanumeric
// characters with a single `_`, then trim leading/trailing `_`.
// Append `.webp`.
//
// Each model's `fromJson` calls one of the kind-specific helpers
// below so the live `entity.icon` always points at a local asset.
// The wiki URL in JSON is intentionally ignored — keeping the JSON
// faithful to the scrape source while the runtime stays offline.

/// Single source of truth for the app version string. Keep this in sync
/// with the `version:` field in pubspec.yaml. Used by main.dart, the
/// main menu, the changelog button, and the MP handshake.
const String kAppVersion = '3.3.0';

// Slug a free-form display name into the canonical asset filename
// stem (no extension). Pure function — given the same name, always
// returns the same slug. Cheap; safe to call per-build if needed.
String slugForAssetName(String name) {
  if (name.isEmpty) return '';
  // RegExp is allocated per-call but the analyser's hot paths don't
  // hit this in inner loops; keeping it inline avoids a top-level
  // mutable static.
  final lowered = name.toLowerCase();
  // Replace any non-[a-z0-9] run with a single underscore.
  final withUnderscores = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  // Trim leading/trailing underscores left over from punctuation at
  // the edges (e.g. "'94 Vamp" → "_94_vamp" → "94_vamp").
  return withUnderscores.replaceAll(RegExp(r'^_+|_+$'), '');
}

String _pathFor(String dir, String name) {
  final slug = slugForAssetName(name);
  if (slug.isEmpty) return '';
  return 'assets/images/$dir/$slug.webp';
}

String localGunIcon(String name) => _pathFor('guns', name);
String localItemIcon(String name) => _pathFor('items', name);
String localGungeoneerIcon(String name) => _pathFor('gungeoneers', name);

/// Path to the animated in-game GIF for a gungeoneer (used on the MP
/// Summary page). Falls back to the static .webp icon if no GIF exists.
String gungeoneerGifPath(String name) {
  final slug = slugForAssetName(name);
  if (slug.isEmpty) return '';
  return 'assets/images/gungeoneers/$slug.gif';
}

String localShrineIcon(String name) => _pathFor('shrines', name);
String localSynergyIcon(String name) => _pathFor('synergies', name);

/// Returns the path to a gungeoneer's map icon (9x9px pixel art from wiki).
/// Returns null if no map icon exists for the given name.
String? gungeoneerMapIconPath(String name) {
  final slug = slugForAssetName(name);
  if (slug.isEmpty) return null;
  return 'assets/images/gungeoneers/${slug}_map.png';
}

/// Path to the splash image for a theme mode slug (e.g. 'unicorn',
/// 'forge_master'). Returns '' if no splash exists for the slug.
String themeSplashPath(String slug) {
  if (slug.isEmpty) return '';
  return 'assets/images/themes/splash/$slug.jpg';
}

/// Paradox Mode avatar registry — cosmetic player avatars exchanged
/// between peers by id over the wire. Append-only: never reorder or
/// remove entries, since peers resolve ids positionally by string
/// equality and an unknown id falls back to the character map icon.
const List<String> kAvatarIds = <String>[
  'the_paradox',
  'the_cultist',
  'the_marine',
  'the_hunter',
  'the_pilot',
  'the_convict',
  'the_bullet',
  'the_robot',
  'the_gunslinger',
  // Unicorn set — sliced from the user's 9unis.jpg 3x3 grid.
  'uni_1',
  'uni_2',
  'uni_3',
  'uni_4',
  'uni_5',
  'uni_6',
  'uni_7',
  'uni_8',
  'uni_9',
  // Grid sets — sliced from the user's 12 3x3 grids (g<set>_<n>).
  'g1_1',
  'g1_2',
  'g1_3',
  'g1_4',
  'g1_5',
  'g1_6',
  'g1_7',
  'g1_8',
  'g1_9',
  'g2_1',
  'g2_2',
  'g2_3',
  'g2_4',
  'g2_5',
  'g2_6',
  'g2_7',
  'g2_8',
  'g2_9',
  'g3_1',
  'g3_2',
  'g3_3',
  'g3_4',
  'g3_5',
  'g3_6',
  'g3_7',
  'g3_8',
  'g3_9',
  'g4_1',
  'g4_2',
  'g4_3',
  'g4_4',
  'g4_5',
  'g4_6',
  'g4_7',
  'g4_8',
  'g4_9',
  'g5_1',
  'g5_2',
  'g5_3',
  'g5_4',
  'g5_5',
  'g5_6',
  'g5_7',
  'g5_8',
  'g5_9',
  'g6_1',
  'g6_2',
  'g6_3',
  'g6_4',
  'g6_5',
  'g6_6',
  'g6_7',
  'g6_8',
  'g6_9',
  'g7_1',
  'g7_2',
  'g7_3',
  'g7_4',
  'g7_5',
  'g7_6',
  'g7_7',
  'g7_8',
  'g7_9',
  'g8_1',
  'g8_2',
  'g8_3',
  'g8_4',
  'g8_5',
  'g8_6',
  'g8_7',
  'g8_8',
  'g8_9',
  'g9_1',
  'g9_2',
  'g9_3',
  'g9_4',
  'g9_5',
  'g9_6',
  'g9_7',
  'g9_8',
  'g9_9',
  'g10_1',
  'g10_2',
  'g10_3',
  'g10_4',
  'g10_5',
  'g10_6',
  'g10_7',
  'g10_8',
  'g10_9',
  'g11_1',
  'g11_2',
  'g11_3',
  'g11_4',
  'g11_5',
  'g11_6',
  'g11_7',
  'g11_8',
  'g11_9',
  'g12_1',
  'g12_2',
  'g12_3',
  'g12_4',
  'g12_5',
  'g12_6',
  'g12_7',
  'g12_8',
  'g12_9',
];

/// Asset path for a Paradox avatar id ('' if unknown). Empty or
/// unknown ids should fall back to the gungeoneer map icon.
/// Frame suffixes ("g1_1:rainbow") are stripped — the wire format
/// carries the picked frame in the same string.
String avatarPath(String id) {
  if (id.isEmpty) return '';
  final base = id.split(':').first;
  return 'assets/images/avatars/${slugForAssetName(base)}.webp';
}

/// Frame slug from a composite avatar id ('' = plain/no frame).
String avatarFrameId(String id) => id.contains(':') ? id.split(':').last : '';

/// Base portrait slug without the frame suffix.
String avatarBaseId(String id) => id.split(':').first;

/// Path to the animated card GIF (or webp for Cultist) for a gungeoneer.
/// Files live in assets/images/gungeoneers/animated/ and use a different
/// naming convention than the static icons (e.g. "Marine_Card_Animated.gif").
/// Returns empty string if no animated card exists for the character.
String gungeoneerAnimatedCardPath(String name) {
  final slug = slugForAssetName(name);
  switch (slug) {
    case 'the_marine':
      return 'assets/images/gungeoneers/animated/Marine_Card_Animated.gif';
    case 'the_pilot':
      return 'assets/images/gungeoneers/animated/Pilot_Card_Animated.gif';
    case 'the_convict':
      return 'assets/images/gungeoneers/animated/Convict_Card_Animated.gif';
    case 'the_hunter':
      return 'assets/images/gungeoneers/animated/Hunter_Card_Animated.gif';
    case 'the_bullet':
      return 'assets/images/gungeoneers/animated/The_Bullet_Animated.gif';
    case 'the_robot':
      return 'assets/images/gungeoneers/animated/Robot_Card_Animated.gif';
    case 'the_cultist':
      return 'assets/images/gungeoneers/animated/Cultist_Card.webp';
    case 'the_paradox':
      return 'assets/images/gungeoneers/animated/Paradox_Card_Animated.gif';
    case 'the_gunslinger':
      return 'assets/images/gungeoneers/animated/Gunslinger_Card_Animated.gif';
    default:
      return '';
  }
}

/// Path to an animated idle GIF for an NPC, if one exists.
/// Files live in assets/animations/ and are named like "Bello_idle.gif".
/// Returns empty string if no idle animation exists for the NPC.
///
/// Mapping is by NPC display name → known idle GIF filename. Not all NPCs
/// have idle animations — only the shopkeepers and a few key NPCs.
String npcIdleGifPath(String npcName) {
  // Normalize the name for matching.
  final lower = npcName.toLowerCase();
  // Direct name → file mapping. The GIF filenames use the NPC's
  // first name or common short name.
  final map = <String, String>{
    'bello': 'Bello_idle.gif',
    'cursula': 'Cursula_idle.gif',
    'flynt': 'Flynt_idle.gif',
    'frifle and the grey mauser': 'Frifle_idle.gif',
    'professor goopton': 'Goopton_idle.gif',
    'greymauser': 'Greymauser_idle.gif',
    'old red': 'Oldred_idle.gif',
    'sell creep': 'Sellcreep_idle.gif',
    'tailor': 'Tailor_idle.gif',
    'vampire': 'Vampire_idle.gif',
    'winchester': 'Winchester_idle.gif',
  };
  // Try exact match first.
  final exact = map[lower];
  if (exact != null) return 'assets/animations/$exact';
  // Try starts-with match (e.g. "Winchester" matches "Winchester's Game").
  for (final entry in map.entries) {
    if (lower.startsWith(entry.key)) {
      return 'assets/animations/${entry.value}';
    }
  }
  return '';
}
