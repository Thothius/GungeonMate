part of '../app_theme.dart';

// Split from theme_models.dart — same library, no import changes.

class CustomThemeData {
  final String name;
  final Color scaffold;
  final Color card;
  final Color primary;
  final Color secondary;
  final Color headlineStat;
  final Color bulletColor;
  final AvatarAuraStyle auraStyle;
  final AppFont font;

  const CustomThemeData({
    required this.name,
    required this.scaffold,
    required this.card,
    required this.primary,
    required this.secondary,
    required this.headlineStat,
    required this.bulletColor,
    this.auraStyle = AvatarAuraStyle.none,
    this.font = AppFont.gungeon,
  });

  /// Serialize for embedding inside SavedCustomTheme.
  Map<String, dynamic> toJson() => {
    'name': name,
    'scaffold': scaffold.toARGB32(),
    'card': card.toARGB32(),
    'primary': primary.toARGB32(),
    'secondary': secondary.toARGB32(),
    'headlineStat': headlineStat.toARGB32(),
    'bulletColor': bulletColor.toARGB32(),
    'auraStyle': auraStyle.index,
    'font': font.index,
  };

  /// Deserialize from embedded JSON. Color fields fall back to defaults
  /// if missing (handles legacy/partial JSON gracefully).
  factory CustomThemeData.fromJson(Map<String, dynamic> j) {
    final d = CustomThemeData.defaultTheme;
    return CustomThemeData(
      name: j['name'] as String? ?? 'Custom',
      scaffold: Color(j['scaffold'] as int? ?? d.scaffold.toARGB32()),
      card: Color(j['card'] as int? ?? d.card.toARGB32()),
      primary: Color(j['primary'] as int? ?? d.primary.toARGB32()),
      secondary: Color(j['secondary'] as int? ?? d.secondary.toARGB32()),
      headlineStat: Color(
        j['headlineStat'] as int? ?? d.headlineStat.toARGB32(),
      ),
      bulletColor: Color(j['bulletColor'] as int? ?? d.bulletColor.toARGB32()),
      auraStyle: AvatarAuraStyle.values[j['auraStyle'] as int? ?? 0],
      font: AppFont.values[j['font'] as int? ?? 0],
    );
  }

  /// Copy with optional overrides (used by color picker).
  CustomThemeData copyWith({
    String? name,
    Color? scaffold,
    Color? card,
    Color? primary,
    Color? secondary,
    Color? headlineStat,
    Color? bulletColor,
    AvatarAuraStyle? auraStyle,
    AppFont? font,
  }) {
    return CustomThemeData(
      name: name ?? this.name,
      scaffold: scaffold ?? this.scaffold,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      headlineStat: headlineStat ?? this.headlineStat,
      bulletColor: bulletColor ?? this.bulletColor,
      auraStyle: auraStyle ?? this.auraStyle,
      font: font ?? this.font,
    );
  }

  static const String _prefsKey = 'custom.theme.data';

  /// Check if a custom theme has been saved.
  static Future<bool> hasSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_prefsKey);
    } catch (_) {
      return false;
    }
  }

  /// Delete the saved custom theme from disk.
  static Future<void> delete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e) {
      debugPrint('[AppTheme] prefs error: $e');
    }
  }

  /// Async load for actual usage in flairFor()
  static Future<CustomThemeData> loadAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefsKey);
      if (jsonStr != null) {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        return CustomThemeData(
          name: json['name'] as String? ?? 'Custom',
          scaffold: Color(json['scaffold'] as int),
          card: Color(json['card'] as int),
          primary: Color(json['primary'] as int),
          secondary: Color(json['secondary'] as int),
          headlineStat: Color(json['headlineStat'] as int),
          bulletColor: Color(json['bulletColor'] as int),
          auraStyle: AvatarAuraStyle.values[json['auraStyle'] as int? ?? 0],
          font:
              AppFont.values[json['font'] as int? ??
                  0], // Default to Gungeon (index 0)
        );
      }
    } catch (e) {
      debugPrint('[AppTheme] prefs error: $e');
    }
    return defaultTheme;
  }

  /// Save custom theme to disk.
  static Future<void> save(CustomThemeData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode({
        'name': data.name,
        'scaffold': data.scaffold.toARGB32(),
        'card': data.card.toARGB32(),
        'primary': data.primary.toARGB32(),
        'secondary': data.secondary.toARGB32(),
        'headlineStat': data.headlineStat.toARGB32(),
        'bulletColor': data.bulletColor.toARGB32(),
        'auraStyle': data.auraStyle.index,
        'font': data.font.index,
      });
      await prefs.setString(_prefsKey, json);
    } catch (e) {
      debugPrint('[AppTheme] prefs error: $e');
    }
  }

  /// Default custom theme (fallback).
  static const CustomThemeData defaultTheme = CustomThemeData(
    name: 'Custom',
    scaffold: Color(0xFF1A1A1A),
    card: Color(0xFF252525),
    primary: Color(0xFF4CAF50),
    secondary: Color(0xFF2196F3),
    headlineStat: Color(0xFF4CAF50),
    bulletColor: Color(0xFF4CAF50),
    auraStyle: AvatarAuraStyle.none,
    font: AppFont.gungeon,
  );

  /// Generate a random custom theme with a lore-style name.
  static CustomThemeData random() {
    final rng = math.Random();
    final nameGen = _RandomNameGenerator(rng);
    final colorGen = _RandomColorGenerator(rng);
    final colors = colorGen.getColors();
    return CustomThemeData(
      name: nameGen.generate(),
      scaffold: colors[0],
      card: colors[1],
      primary: colors[2],
      secondary: colors[3],
      headlineStat: colors[4],
      bulletColor: colors[5],
      auraStyle:
          AvatarAuraStyle.values[rng.nextInt(AvatarAuraStyle.values.length)],
      font: AppFont.values[rng.nextInt(AppFont.values.length)],
    );
  }
}

/// Helper for generating lore-style random theme names.

class _RandomNameGenerator {
  static const _adjectives = [
    'Angry',
    'Jammed',
    'Cursed',
    'Glitched',
    'Mimic',
    'Tactical',
    'Duct-Taped',
    'Searing',
    'Spectral',
    'Toxic',
    'Golden',
    'Rusty',
    'Dragun',
    'High-Tier',
    'Coolmaxing',
    'Synergy',
    'Shunted',
    'Blazing',
    'Hollowed',
    'Shaking',
    'Wobbling',
    'Goopian',
    'Archival',
    'Bullet-Bore',
  ];
  static const _entities = [
    'Bulletkin',
    'Cultist',
    'Beholster',
    'Blobulord',
    'Gorgun',
    'Dragun',
    'Mine Flayer',
    'Rat',
    'Gatling Gull',
    'Gunnut',
    'Lead Maiden',
    'Ammolet',
    'Shell',
    'Casey',
    'Master Round',
    'Hegemony',
    'Synergrace',
    'Bello',
    'Winchester',
    'Frifle',
    'Manuel',
    'Gunfortuna',
    'Gungeoneer',
    'Shellmet',
  ];

  final math.Random _rng;

  _RandomNameGenerator(this._rng);

  String generate() {
    final adj = _adjectives[_rng.nextInt(_adjectives.length)];
    final ent = _entities[_rng.nextInt(_entities.length)];
    return '$adj $ent';
  }
}

/// Helper for generating random harmonious colors.

class _RandomColorGenerator {
  final math.Random _rng;

  // 20 Lore-Authentic, curated Gungeon color schemas (Scaffold, Card, Primary, Secondary, Headline, Bullet)
  static const List<List<Color>> _schemas = [
    // 1. Gungeon Green (Oubliette)
    [
      Color(0xFF0D140E),
      Color(0xFF162218),
      Color(0xFF39FF14),
      Color(0xFF00FF87),
      Color(0xFFCCFF00),
      Color(0xFF39FF14),
    ],
    // 2. Bullet Kin Brass
    [
      Color(0xFF111112),
      Color(0xFF1E1C1A),
      Color(0xFFFF9F1C),
      Color(0xFFCD9F73),
      Color(0xFFFFD166),
      Color(0xFFFF9F1C),
    ],
    // 3. Hollow Chill Spectral
    [
      Color(0xFF081016),
      Color(0xFF111E29),
      Color(0xFF00D2FF),
      Color(0xFF90A4AE),
      Color(0xFFE0F7FA),
      Color(0xFF00D2FF),
    ],
    // 4. Dragun Fire
    [
      Color(0xFF090706),
      Color(0xFF191210),
      Color(0xFFFF4500),
      Color(0xFFFFB74D),
      Color(0xFFFFD54F),
      Color(0xFFFF4500),
    ],
    // 5. Gungeon Blue (The Breach)
    [
      Color(0xFF0E1116),
      Color(0xFF1B1E26),
      Color(0xFF00E5FF),
      Color(0xFF5C6BC0),
      Color(0xFF80DEEA),
      Color(0xFF00E5FF),
    ],
    // 6. Lich Purple (Bullet Hell)
    [
      Color(0xFF08030C),
      Color(0xFF160721),
      Color(0xFFCE93D8),
      Color(0xFF990000),
      Color(0xFFFF007F),
      Color(0xFFCE93D8),
    ],
    // 7. High-Tier Chest Red (Synergy)
    [
      Color(0xFF14070A),
      Color(0xFF261014),
      Color(0xFFFF1E27),
      Color(0xFFFFD700),
      Color(0xFFFF8A80),
      Color(0xFFFF1E27),
    ],
    // 8. Cultist Pink
    [
      Color(0xFF140D1D),
      Color(0xFF231633),
      Color(0xFFFF4081),
      Color(0xFFE040FB),
      Color(0xFFF8BBD0),
      Color(0xFFFF4081),
    ],
    // 9. Glitch Chest Neon
    [
      Color(0xFF0B1214),
      Color(0xFF152226),
      Color(0xFF00E5FF),
      Color(0xFFFF007F),
      Color(0xFFE040FB),
      Color(0xFF00E5FF),
    ],
    // 10. Gunfortuna Gold
    [
      Color(0xFF0D0C0B),
      Color(0xFF1C1916),
      Color(0xFFFFD700),
      Color(0xFFFFB74D),
      Color(0xFFFFFDD0),
      Color(0xFFFFD700),
    ],
    // 11. Rogue Marine Olive
    [
      Color(0xFF0E120D),
      Color(0xFF1B2217),
      Color(0xFF4CAF50),
      Color(0xFFFF7043),
      Color(0xFFA5D6A7),
      Color(0xFF4CAF50),
    ],
    // 12. Convict Yellow
    [
      Color(0xFF14120D),
      Color(0xFF231E15),
      Color(0xFFFFB300),
      Color(0xFF78909C),
      Color(0xFFFFE082),
      Color(0xFFFFB300),
    ],
    // 13. Hunter Crossbow
    [
      Color(0xFF0A0F0D),
      Color(0xFF152219),
      Color(0xFF66BB6A),
      Color(0xFF29B6F6),
      Color(0xFFC8E6C9),
      Color(0xFF66BB6A),
    ],
    // 14. Pilot Blue
    [
      Color(0xFF0D121F),
      Color(0xFF182236),
      Color(0xFF29B6F6),
      Color(0xFFFFCA28),
      Color(0xFFE1F5FE),
      Color(0xFF29B6F6),
    ],
    // 15. Synergy Chest Pink
    [
      Color(0xFF0D0B1C),
      Color(0xFF171333),
      Color(0xFFEC407A),
      Color(0xFF5C6BC0),
      Color(0xFFF8BBD0),
      Color(0xFFEC407A),
    ],
    // 16. Duct Tape Steel
    [
      Color(0xFF111314),
      Color(0xFF212529),
      Color(0xFFB0BEC5),
      Color(0xFFFF7043),
      Color(0xFFECEFF1),
      Color(0xFFB0BEC5),
    ],
    // 17. Casey Bat Brown
    [
      Color(0xFF120E0D),
      Color(0xFF241A17),
      Color(0xFF8D6E63),
      Color(0xFFFF8A80),
      Color(0xFFD7CCC8),
      Color(0xFF8D6E63),
    ],
    // 18. Chamber 1.5 Sewer
    [
      Color(0xFF0F0E0D),
      Color(0xFF221F1C),
      Color(0xFF81C784),
      Color(0xFF795548),
      Color(0xFFC8E6C9),
      Color(0xFF81C784),
    ],
    // 19. Sir Manuel Armor
    [
      Color(0xFF111417),
      Color(0xFF20262C),
      Color(0xFF90A4AE),
      Color(0xFFFFD54F),
      Color(0xFFECEFF1),
      Color(0xFF90A4AE),
    ],
    // 20. Master Round Crimson
    [
      Color(0xFF14080D),
      Color(0xFF261019),
      Color(0xFFFF1133),
      Color(0xFFFFD700),
      Color(0xFFFF8A80),
      Color(0xFFFF1133),
    ],
  ];

  _RandomColorGenerator(this._rng);

  List<Color> getColors() {
    // Return a curated pre-balanced Gungeon color scheme, completely oiled up!
    return _schemas[_rng.nextInt(_schemas.length)];
  }
}

/// Per-theme ambient glow animation style. Controls how the
/// [_AmbientGlow] layer behind every theme moves and pulses.
