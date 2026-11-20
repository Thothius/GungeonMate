import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_theme.dart';
import '../utils/asset_paths.dart';

/// One catalogued asset the Asset Viewer can show + vote on.
class AssetEntry {
  /// Stable vote key, e.g. `font:dmSans`, `bg:wp_07`, `avatar:custom_12`.
  final String id;
  final String category; // 'font' | 'bg' | 'avatar'
  final String name;
  final String detail; // family name, file name, etc.
  final String? imagePath; // null for fonts (rendered as text)
  final String? fontFamily; // non-null for fonts

  const AssetEntry({
    required this.id,
    required this.category,
    required this.name,
    required this.detail,
    this.imagePath,
    this.fontFamily,
  });
}

/// Local YAY/NAY voting on bundled assets — the feedback loop that
/// tells us which fonts/backgrounds/avatars to keep or cut. Votes are
/// device-local (SharedPreferences) and exported as JSON via the
/// viewer's EXPORT button; disliked assets are marked `nay` for removal.
class AssetVotes extends ChangeNotifier {
  static const _prefsKey = 'asset_votes_v1';

  /// id → 'yay' | 'nay'
  final Map<String, String> _votes = {};

  /// Full asset catalog — fonts, wallpapers/theme splashes, avatars.
  /// Built lazily; image paths verified against known bundles.
  static List<AssetEntry> catalog() {
    final entries = <AssetEntry>[];

    // Only fonts with a bundled asset — deprecated enum members kept
    // for index-stable prefs have no TTF on disk anymore.
    for (final f in AppFont.values.where(AppFontLabel.isOffered)) {
      entries.add(
        AssetEntry(
          id: 'font:${f.name}',
          category: 'font',
          name: f.label,
          detail: f.description,
          fontFamily: f.bundledFontFamily,
        ),
      );
    }

    // Wallpapers — 46 custom webp picks.
    for (var i = 1; i <= 46; i++) {
      final file = 'wp_${i.toString().padLeft(2, '0')}.webp';
      entries.add(
        AssetEntry(
          id: 'bg:$file',
          category: 'bg',
          name: 'Wallpaper ${i.toString().padLeft(2, '0')}',
          detail: file,
          imagePath: 'assets/images/wallpapers/custom/$file',
        ),
      );
    }

    // Theme splash art — the 14 JPGs that actually exist on disk.
    const splashSlugs = [
      'cat_lady',
      'custom',
      'dragunfire',
      'forge_master',
      'gunpowder',
      'lichs_domain',
      'moonlit_chamber',
      'mr_robot',
      'robots_core',
      'storm_caller',
      'the_bullet',
      'the_paradox',
      'unicorn',
      'valor_of_marines',
    ];
    for (final slug in splashSlugs) {
      entries.add(
        AssetEntry(
          id: 'bg:splash_$slug',
          category: 'bg',
          name: 'Splash — ${slug.replaceAll('_', ' ')}',
          detail: '$slug.jpg',
          imagePath: 'assets/images/themes/splash/$slug.jpg',
        ),
      );
    }

    // Avatars — every registered id resolves to a webp.
    for (final id in kAvatarIds) {
      final path = avatarPath(id);
      if (path.isEmpty) continue;
      entries.add(
        AssetEntry(
          id: 'avatar:$id',
          category: 'avatar',
          name: id.replaceAll('_', ' '),
          detail: path.split('/').last,
          imagePath: path,
        ),
      );
    }

    return entries;
  }

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _votes
        ..clear()
        ..addEntries(
          map.entries
              .where((e) => e.value == 'yay' || e.value == 'nay')
              .map((e) => MapEntry(e.key, e.value as String)),
        );
      notifyListeners();
    } catch (_) {
      // Corrupt prefs → start clean rather than crash the viewer.
      _votes.clear();
    }
  }

  String? voteFor(String id) => _votes[id];

  int get yayCount => _votes.values.where((v) => v == 'yay').length;
  int get nayCount => _votes.values.where((v) => v == 'nay').length;

  /// Set or clear a vote. [verdict] is 'yay', 'nay', or null to clear.
  Future<void> setVote(String id, String? verdict) async {
    if (verdict == null) {
      _votes.remove(id);
    } else {
      _votes[id] = verdict;
    }
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_prefsKey, jsonEncode(_votes));
    } catch (e) {
      debugPrint('[AssetVotes] persist failed: $e');
    }
  }

  /// Export payload — every catalogued asset with its current verdict
  /// ('yay' | 'nay' | 'unrated'). `nay` rows are the removal candidates.
  Map<String, dynamic> toExportJson() {
    final assets = [
      for (final e in catalog())
        {
          'id': e.id,
          'category': e.category,
          'name': e.name,
          'detail': e.detail,
          'verdict': _votes[e.id] ?? 'unrated',
        },
    ];
    return {
      'app': 'GungeonMate',
      'exportedAt': DateTime.now().toIso8601String(),
      'counts': {
        'yay': yayCount,
        'nay': nayCount,
        'unrated': assets.where((a) => a['verdict'] == 'unrated').length,
      },
      'assets': assets,
    };
  }
}
