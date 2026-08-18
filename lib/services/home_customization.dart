import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home-screen customization state: which gungeoneer (if any) rotates in
/// the vortex, and which "junk" pickups (money, blanks, guon stones,
/// hearts) drift through it.
///
/// Persisted to SharedPreferences so the user's choices survive app
/// restarts. Exposed via a single [ValueNotifier] ([HomeCustomization.notifier]).
class HomeCustomization {
  /// Whether a gungeoneer model is shown rotating in the vortex center.
  final bool showGungeoneer;

  /// Selected gungeoneer name, or '' to cycle a random gungeoneer.
  final String gungeoneerName;

  /// Whether junk pickups drift through the vortex.
  final bool showJunk;

  /// Per-junk-type counts. Keys are the asset stems in
  /// `assets/images/home/junk/`. A count of 0 means "hidden".
  final Map<String, int> junkCounts;

  const HomeCustomization({
    this.showGungeoneer = false,
    this.gungeoneerName = '',
    this.showJunk = false,
    this.junkCounts = const {},
  });

  /// All supported junk types in display order, with a human label and
  /// the asset stem (file name without extension). Grouped: pickups
  /// first, then enemies, then items.
  static const junkTypes = <_JunkType>[
    // ── Pickups ──
    _JunkType('Money', 'Money'),
    _JunkType('Money x5', 'Money_5'),
    _JunkType('Golden Shell', 'Golden_Shell'),
    _JunkType('Blank', 'Blank'),
    _JunkType('Glass Guon Stone', 'Glass_Guon_Stone'),
    _JunkType('Half Heart', 'Half_Heart'),
    _JunkType('Heart', 'Pickup_Heart'),
    _JunkType('Armor', 'Pickup_Armor'),
    _JunkType('Key', 'Pickup_Key'),
    _JunkType('Pickup Blank', 'Pickup_Blank'),
    // ── Enemies ──
    _JunkType('Bullet Kin', 'Bullet_Kin'),
    _JunkType('Arrowkin', 'Arrowkin'),
    _JunkType('Bullat', 'Bullat'),
    _JunkType('Blobulin', 'Blobulin'),
    _JunkType('Shotgat', 'Shotgat'),
    _JunkType('Skullet', 'Skullet'),
    _JunkType('Gun Nut', 'Gun_Nut'),
    _JunkType('Bookllet', 'Bookllet'),
    // ── Items ──
    _JunkType('Bomb', 'Bomb'),
    _JunkType('Blue Guon Stone', 'Blue_Guon_Stone'),
    _JunkType('Spice', 'Spice'),
    _JunkType('Iron Coin', 'Iron_Coin'),
  ];

  /// Total number of junk sprites currently configured.
  int get totalJunk => junkCounts.values.fold(0, (a, b) => a + b);

  /// Asset path for a junk stem. Pickup/enemy sprites are .png, items
  /// are .webp. The extension is inferred from the stem prefix.
  static String junkAssetPath(String stem) {
    // Pickups and enemies use .png, items use .webp.
    final isPng = stem.startsWith('Pickup_') ||
        stem.startsWith('Bullet_') ||
        stem.startsWith('Arrow') ||
        stem.startsWith('Bullat') ||
        stem.startsWith('Blob') ||
        stem.startsWith('Shotgat') ||
        stem.startsWith('Skullet') ||
        stem.startsWith('Gun_Nut') ||
        stem.startsWith('Bookllet');
    final ext = isPng ? 'png' : 'webp';
    return 'assets/images/home/junk/$stem.$ext';
  }

  HomeCustomization copyWith({
    bool? showGungeoneer,
    String? gungeoneerName,
    bool? showJunk,
    Map<String, int>? junkCounts,
  }) {
    return HomeCustomization(
      showGungeoneer: showGungeoneer ?? this.showGungeoneer,
      gungeoneerName: gungeoneerName ?? this.gungeoneerName,
      showJunk: showJunk ?? this.showJunk,
      junkCounts: junkCounts ?? this.junkCounts,
    );
  }

  static const _kShowGun = 'home.show_gungeoneer';
  static const _kGunName = 'home.gungeoneer_name';
  static const _kShowJunk = 'home.show_junk';
  static const _kJunkCounts = 'home.junk_counts';

  static final ValueNotifier<HomeCustomization> notifier =
      ValueNotifier(const HomeCustomization());

  /// Load persisted state into [notifier]. Call once at startup.
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final showGun = p.getBool(_kShowGun) ?? false;
    final gunName = p.getString(_kGunName) ?? '';
    final showJunk = p.getBool(_kShowJunk) ?? false;
    final countsRaw = p.getString(_kJunkCounts);
    Map<String, int> counts = {};
    if (countsRaw != null && countsRaw.isNotEmpty) {
      countsRaw.split(',').forEach((pair) {
        final i = pair.indexOf(':');
        if (i > 0) {
          counts[pair.substring(0, i)] =
              int.tryParse(pair.substring(i + 1)) ?? 0;
        }
      });
    }
    notifier.value = HomeCustomization(
      showGungeoneer: showGun,
      gungeoneerName: gunName,
      showJunk: showJunk,
      junkCounts: counts,
    );
  }

  static Future<void> _persist(HomeCustomization c) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kShowGun, c.showGungeoneer);
    await p.setString(_kGunName, c.gungeoneerName);
    await p.setBool(_kShowJunk, c.showJunk);
    final countsStr = c.junkCounts.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    await p.setString(_kJunkCounts, countsStr);
  }

  static void setShowGungeoneer(bool v) {
    final c = notifier.value.copyWith(showGungeoneer: v);
    notifier.value = c;
    _persist(c);
  }

  static void setGungeoneerName(String name) {
    final c = notifier.value.copyWith(
      gungeoneerName: name,
      showGungeoneer: true,
    );
    notifier.value = c;
    _persist(c);
  }

  static void setShowJunk(bool v) {
    final c = notifier.value.copyWith(showJunk: v);
    notifier.value = c;
    _persist(c);
  }

  /// Set the count for a junk stem. A count <= 0 removes it.
  static void setJunkCount(String stem, int count) {
    final counts = Map<String, int>.from(notifier.value.junkCounts);
    if (count <= 0) {
      counts.remove(stem);
    } else {
      counts[stem] = count.clamp(1, 12);
    }
    final c = notifier.value.copyWith(junkCounts: counts);
    notifier.value = c;
    _persist(c);
  }
}

class _JunkType {
  final String label;
  final String stem;
  const _JunkType(this.label, this.stem);
}
