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
      baseMode: AppThemeMode.values[j['baseMode'] as int],
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
  static ValueNotifier<List<SavedCustomTheme>> notifier =
      ValueNotifier<List<SavedCustomTheme>>([]);

  static List<SavedCustomTheme> get themes => notifier.value;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json != null) {
        final list = jsonDecode(json) as List;
        notifier.value =
            list
                .map(
                  (j) => SavedCustomTheme.fromJson(j as Map<String, dynamic>),
                )
                .toList();
      }
    } catch (_) {}
  }

  static Future<void> save(SavedCustomTheme theme) async {
    final updated = [...notifier.value, theme];
    notifier.value = updated;
    await _persist(updated);
  }

  static Future<void> delete(String id) async {
    final updated = notifier.value.where((t) => t.id != id).toList();
    notifier.value = updated;
    await _persist(updated);
  }

  static Future<void> _persist(List<SavedCustomTheme> themes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(themes.map((t) => t.toJson()).toList());
      await prefs.setString(_key, json);
    } catch (_) {}
  }
}

/// Static holder for the live [AppThemeMode]. Mutated via [setMode] and
/// rebroadcast through [notifier] so the root [MaterialApp] rebuilds
/// with the new palette + every descendant picks up the new flair.
