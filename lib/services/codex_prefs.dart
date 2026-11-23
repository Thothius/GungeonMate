import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Codex favorites + recently-viewed entries, persisted in
/// SharedPreferences. Keys are `'SectionName|Entry Name'` — stable
/// across sessions because both halves come from fixed enums/data.
///
/// UI listens to [favorites]/[recents] ValueNotifiers; mutations go
/// through the async methods which update the notifier first, then
/// persist (await persistence before pops is handled by callers that
/// need it — these are fire-and-forget safe).
class CodexPrefs {
  CodexPrefs._();

  static const _favsKey = 'codex_favorites';
  static const _recentsKey = 'codex_recents';
  static const _maxRecents = 16;

  static final favorites = ValueNotifier<Set<String>>(<String>{});
  static final recents = ValueNotifier<List<String>>(<String>[]);

  static Future<void>? _initFuture;

  @visibleForTesting
  static void debugReset() {
    _initFuture = null;
    favorites.value = <String>{};
    recents.value = <String>[];
  }

  /// Idempotent load — call once from the codex screen's initState.
  static Future<void> ensureLoaded() {
    return _initFuture ??= _load();
  }

  static Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      favorites.value =
          ((jsonDecode(prefs.getString(_favsKey) ?? '[]') as List?) ?? [])
              .map((e) => e as String)
              .toSet();
      recents.value =
          ((jsonDecode(prefs.getString(_recentsKey) ?? '[]') as List?) ?? [])
              .map((e) => e as String)
              .toList();
    } catch (_) {
      // Corrupt prefs → start clean rather than crash the codex.
      favorites.value = <String>{};
      recents.value = <String>[];
    }
  }

  static String keyFor(String section, String name) => '$section|$name';

  /// `'enemies|Hitbullet|True'` → `('enemies', 'Hitbullet|True')` —
  /// splits on the FIRST pipe so names containing '|' survive.
  static (String section, String name) parseKey(String key) {
    final i = key.indexOf('|');
    if (i < 0) return ('', key);
    return (key.substring(0, i), key.substring(i + 1));
  }

  static bool isFavorite(String key) => favorites.value.contains(key);

  static Future<void> toggleFavorite(String key) async {
    final next = {...favorites.value};
    if (!next.remove(key)) next.add(key);
    favorites.value = next;
    await _save();
  }

  /// Move [key] to the front of recents, deduped, capped at
  /// [_maxRecents].
  static Future<void> recordRecent(String key) async {
    recents.value = [
      key,
      ...recents.value.where((k) => k != key),
    ].take(_maxRecents).toList();
    await _save();
  }

  static Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_favsKey, jsonEncode(favorites.value.toList()));
      await prefs.setString(_recentsKey, jsonEncode(recents.value));
    } catch (_) {
      // Persistence failure is non-fatal — in-memory state still works.
    }
  }
}
