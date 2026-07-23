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
  final withUnderscores = lowered.replaceAll(
    RegExp(r'[^a-z0-9]+'),
    '_',
  );
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
