import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../utils/asset_paths.dart';

/// One sprite in the Paradox chat/emote catalog. `key` is the wire
/// token embedded in chat text as `:key:` — built from kind + slug so
/// both sides resolve to the same local asset.
class EmoteSprite {
  final String key; // e.g. 'gun_rusty_sidearm' / 'pickup_heart'
  final String label; // display name
  final String kind; // 'gun' | 'item' | 'object' | 'pickup'
  final String assetPath; // local asset path

  const EmoteSprite({
    required this.key,
    required this.label,
    required this.kind,
    required this.assetPath,
  });
}

/// Lazily-built catalog of every sprite usable in Paradox chat —
/// guns + items from [RunProvider]'s loaded datasets, objects +
/// pickups read straight from their JSON assets on first use.
class EmoteSpriteCatalog {
  EmoteSpriteCatalog._();

  static List<EmoteSprite> _all = [];
  static final Map<String, EmoteSprite> _byKey = {};
  static bool _loaded = false;

  static List<EmoteSprite> get all => _all;
  static EmoteSprite? byKey(String key) => _byKey[key];

  /// Load the catalog (idempotent). Safe to call from initState —
  /// guns/items are already in memory, objects/pickups are small JSON.
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    _all = [];
    _byKey.clear();
    void add(String kind, String name, String iconPath) {
      final slug = slugForAssetName(name);
      if (slug.isEmpty || iconPath.isEmpty) return;
      final sprite = EmoteSprite(
        key: '${kind}_$slug',
        label: name,
        kind: kind,
        assetPath: iconPath,
      );
      _all.add(sprite);
      _byKey[sprite.key] = sprite;
    }

    // Guns + items — names from JSON, local sprite path derived via the
    // same slug rule the models use (JSON icon fields are wiki URLs).
    for (final spec in const [
      ('gun', 'assets/data/guns.json', 'gun'),
      ('item', 'assets/data/items.json', 'item'),
    ]) {
      try {
        final raw = await rootBundle.loadString(spec.$2);
        final list =
            (json.decode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
        for (final j in list) {
          final name = j['name'] as String? ?? '';
          if (name.isEmpty) continue;
          final path =
              spec.$1 == 'gun' ? localGunIcon(name) : localItemIcon(name);
          add(spec.$1, name, path);
        }
      } catch (_) {}
    }

    // Objects + pickups — loaded once from their JSON assets. The icon
    // field carries the filename inside the matching images folder.
    for (final spec in const [
      ('object', 'assets/data/objects.json', 'objects'),
      ('pickup', 'assets/data/pickups.json', 'pickups'),
    ]) {
      try {
        final raw = await rootBundle.loadString(spec.$2);
        final list =
            (json.decode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
        for (final j in list) {
          final name = j['name'] as String? ?? '';
          final icon = j['icon'] as String? ?? '';
          if (icon.isEmpty) continue;
          add(spec.$1, name, 'assets/images/${spec.$3}/$icon');
        }
      } catch (_) {}
    }
  }

  /// Search helper for picker + `:autocomplete` — case-insensitive
  /// substring on label and key, capped for perf.
  static List<EmoteSprite> search(
    String query, {
    String? kind,
    int limit = 24,
  }) {
    final q = query.trim().toLowerCase();
    final out = <EmoteSprite>[];
    for (final s in _all) {
      if (kind != null && s.kind != kind) continue;
      if (q.isEmpty || s.label.toLowerCase().contains(q) || s.key.contains(q)) {
        out.add(s);
        if (out.length >= limit) break;
      }
    }
    return out;
  }
}
