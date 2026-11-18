part of '../app_theme.dart';

// Split from theme_models.dart — same library, no import changes.

class SavedCustomTheme {
  final String id; // unique timestamp-based ID
  final String name; // user-given name
  final String splashSlug; // graphic asset key from a premade
  final AppThemeMode baseMode; // the premade theme this was built from
  final VisualPrefs prefs; // the visual settings at save time
  final CustomThemeData?
  customData; // custom palette (only when baseMode == custom)
  final String icon; // Material icon codePoint as string (e.g. "0xe3af")

  const SavedCustomTheme({
    required this.id,
    required this.name,
    required this.splashSlug,
    required this.baseMode,
    required this.prefs,
    this.customData,
    this.icon = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'splashSlug': splashSlug,
    'baseMode': baseMode.index,
    'prefs': prefs.toJson(),
    if (customData != null) 'customData': customData!.toJson(),
    if (icon.isNotEmpty) 'icon': icon,
  };

  factory SavedCustomTheme.fromJson(Map<String, dynamic> j) {
    return SavedCustomTheme(
      id: j['id'] as String,
      name: j['name'] as String,
      splashSlug: j['splashSlug'] as String,
      // Clamp — a preset saved before an enum shrink/reorder must not
      // throw (one bad entry used to fail the entire gallery load).
      baseMode: AppThemeMode.values[
        (j['baseMode'] as int? ?? 0).clamp(
          0,
          AppThemeMode.values.length - 1,
        )
      ],
      prefs: VisualPrefs.fromJson(j['prefs'] as Map<String, dynamic>),
      customData:
          j['customData'] != null
              ? CustomThemeData.fromJson(
                j['customData'] as Map<String, dynamic>,
              )
              : null,
      icon: j['icon'] as String? ?? '',
    );
  }
}

/// Persisted store of user-saved custom themes. Stored as a JSON list
/// in SharedPreferences. Unlimited count.
class CustomThemeStore {
  static const _key = 'custom.themes.v1';
  static final ValueNotifier<List<SavedCustomTheme>> notifier =
      ValueNotifier<List<SavedCustomTheme>>([]);

  static List<SavedCustomTheme> get themes => notifier.value;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json != null) {
        final list = jsonDecode(json) as List;
        // Per-item resilience — one malformed entry must not wipe the
        // whole gallery (a single bad cast used to nuke every preset).
        final parsed = <SavedCustomTheme>[];
        for (final j in list) {
          if (j is! Map<String, dynamic>) continue;
          try {
            parsed.add(SavedCustomTheme.fromJson(j));
          } catch (_) {}
        }
        notifier.value = parsed;
      }
    } catch (_) {}
  }

  /// Persist [theme] to the gallery. Serializes and writes to
  /// SharedPreferences FIRST — only on success does the in-memory
  /// gallery update. Returns false on failure so callers can surface
  /// it; previously a persist failure left a ghost preset that showed
  /// in-session but vanished on restart.
  static Future<bool> save(SavedCustomTheme theme) async {
    final updated = [...notifier.value, theme];
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(updated.map((t) => t.toJson()).toList());
      final ok = await prefs.setString(_key, json);
      if (!ok) return false;
      notifier.value = updated;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> delete(String id) async {
    final updated = notifier.value.where((t) => t.id != id).toList();
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(updated.map((t) => t.toJson()).toList());
      final ok = await prefs.setString(_key, json);
      if (!ok) return false;
      notifier.value = updated;
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// Static holder for the live [AppThemeMode]. Mutated via [setMode] and
/// rebroadcast through [notifier] so the root [MaterialApp] rebuilds
/// with the new palette + every descendant picks up the new flair.
