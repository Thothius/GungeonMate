import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/tokens.dart';
import '../utils/contrast.dart';
import '../widgets/particle_engine.dart'
    show
        ParticlePreset,
        GlowEffect,
        ParticleColorSchema,
        ParticleSpeed,
        ParticleType;

/// Eight lore-named palettes. Each is a hand-tuned palette + a
/// [ThemeFlair] record carrying extra styling knobs (numeric typography,
/// divider/chip treatment, quirk flags) so themes differ in more than
/// just hue.
///
/// - [coolmaxing]   : Gold Rush. Black + chrome-gold + magenta. Headline
///                    numbers shimmer occasionally, heavier weight.
/// - [unicorn]      : Cotton Candy. Lavender + bubblegum + mint. Rounded
///                    display numbers; ✦ bullet glyphs twinkle.
/// - [curseblaster] : Blood Moon. Maroon-black + oxblood + bone. Curse
///                    stat glows red proportional to its value.
/// - [winchester]   : Saloon. Walnut + brass + bone. Embossed tabular
///                    numerals, brass hairline borders, tick dividers.
/// - [minimalist]   : Paper. Off-black + warm off-white. Chips replaced
///                    with plain underlined labels. No animation — the
///                    stillness is the quirk.
/// - [iceTyrant]    : Frozen Throne. Ice-black + slate-blue + cyan.
///                    Falling ice crystals, frost-ring aura.
/// - [pitchBlack]   : Void. Absolute dark + white motes. Barely visible
///                    pulse — silence is the signature.
/// - [oubliette]    : Toxic Depths. Poison green + swamp black. Rising
///                    toxic bubbles, bubbling ooze aura.
part 'theme/app_theme_modes.dart';
part 'theme/theme_misc_enums.dart';
part 'theme/theme_data_tables.dart';
part 'theme/theme_custom_data.dart';
part 'theme/theme_flair_prefs.dart';
part 'theme/theme_store.dart';

class AppTheme {
  const AppTheme._();

  static const String _prefsKey = 'theme.mode.v2';
  static const String _unicornPaletteKey = 'theme.unicorn.palette.v1';
  // Neo-Skeuo toggle: remembers what to restore on exit.
  static const String _skeuoPrevModeKey = 'theme.skeuo.prev_mode.v1';
  static const String _skeuoPrevFontKey = 'theme.skeuo.prev_font.v1';
  // Old key from the 4-mode era. Migrated on first run then cleared so
  // returning users don't get parked on an invalid index.
  static const String _legacyKey = 'theme.mode';

  static final RefreshableValueNotifier<AppThemeMode> notifier =
      RefreshableValueNotifier<AppThemeMode>(AppThemeMode.paperInk);

  static final ValueNotifier<AppThemeMode?> previewNotifier =
      ValueNotifier<AppThemeMode?>(null);

  static AppThemeMode get mode => notifier.value;
  static ThemeFlair get flair => flairFor(notifier.value);

  static AppThemeMode get displayedMode =>
      previewNotifier.value ?? notifier.value;
  static ThemeFlair get displayedFlair => flairFor(displayedMode);

  /// Active palette for the Unicorn megapack. Persisted across sessions.
  static UnicornPalette _unicornPalette = UnicornPalette.cottonCandy;
  static UnicornPalette get unicornPalette => _unicornPalette;
  static final ValueNotifier<UnicornPalette> unicornPaletteNotifier =
      ValueNotifier<UnicornPalette>(UnicornPalette.cottonCandy);

  static Future<void> setUnicornPalette(UnicornPalette p) async {
    _unicornPalette = p;
    unicornPaletteNotifier.value = p;
    notifier.refresh();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_unicornPaletteKey, p.index);
    } catch (e) {
      debugPrint('[AppTheme] prefs error: $e');
    }
  }

  /// Per-theme remix index (0 = original). Persisted.
  static final Map<AppThemeMode, int> _remixIndex = {};
  static final ValueNotifier<int> remixNotifier = ValueNotifier(0);

  static int remixFor(AppThemeMode m) => _remixIndex[m] ?? 0;

  static Future<void> setRemix(AppThemeMode m, int idx) async {
    _remixIndex[m] = idx;
    remixNotifier.value = idx;
    notifier.refresh();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme.remix.${m.index}', idx);
    } catch (e) {
      debugPrint('[AppTheme] prefs error: $e');
    }
  }

  /// Cached custom theme name for synchronous label access.
  static String _customThemeName = 'Custom';

  /// Cached custom theme data for synchronous flair access.
  static CustomThemeData? _cachedCustomTheme;

  /// Public read-only access to the cached custom theme data.
  static CustomThemeData? get cachedCustomTheme => _cachedCustomTheme;

  /// Update the cached custom theme name (call when saving custom theme).
  static void setCustomThemeName(String name) {
    _customThemeName = name;
  }

  /// Update the cached custom theme data (call when saving custom theme).
  static void setCustomThemeData(CustomThemeData data) {
    _cachedCustomTheme = data;
    _customThemeName = data.name;
  }

  /// Persist custom theme palette to disk + update cache + refresh listeners.
  static Future<void> saveCustomThemeData(CustomThemeData data) async {
    _cachedCustomTheme = data;
    _customThemeName = data.name;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        CustomThemeData._prefsKey,
        jsonEncode(data.toJson()),
      );
    } catch (_) {}
    refresh();
  }

  /// Hydrate [mode] from disk. Call once from `main()` before `runApp`.
  /// If the persisted theme is no longer in [kVisibleThemes] (e.g. one
  /// of the removed lore themes from older releases) we silently
  /// migrate the user onto the first visible theme so they don't get
  /// stranded on a now-hidden palette.
  static Future<void> init() async {
    notifier.value = kVisibleThemes.first;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load unicorn palette preference.
      final palIdx = prefs.getInt(_unicornPaletteKey);
      if (palIdx != null &&
          palIdx >= 0 &&
          palIdx < UnicornPalette.values.length) {
        _unicornPalette = UnicornPalette.values[palIdx];
        unicornPaletteNotifier.value = _unicornPalette;
      }

      // Load per-theme remix indices.
      for (final m in kThemeRemixes.keys) {
        final rIdx = prefs.getInt('theme.remix.${m.index}');
        if (rIdx != null && rIdx >= 0 && rIdx < kThemeRemixes[m]!.length) {
          _remixIndex[m] = rIdx;
        }
      }

      // Load custom theme palette data (if previously saved).
      final customJson = prefs.getString(CustomThemeData._prefsKey);
      if (customJson != null) {
        try {
          final j = jsonDecode(customJson) as Map<String, dynamic>;
          _cachedCustomTheme = CustomThemeData.fromJson(j);
          _customThemeName = _cachedCustomTheme!.name;
        } catch (_) {}
      }

      final idx = prefs.getInt(_prefsKey);
      if (idx != null && idx >= 0 && idx < AppThemeMode.values.length) {
        var m = AppThemeMode.values[idx];
        // Customization rework — anything outside the visible set
        // (unicorn/moltenSteel/paperInk/custom) migrates to the
        // visible-list default (paperInk).
        if (!kVisibleThemes.contains(m)) {
          m = kVisibleThemes.first;
          await prefs.setInt(_prefsKey, m.index);
        }
        if (kVisibleThemes.contains(m)) {
          notifier.value = m;
        } else {
          // Migrate Unicorn II-IV to Unicorn + corresponding palette.
          if (m == AppThemeMode.unicornII) {
            _unicornPalette = UnicornPalette.neon;
            unicornPaletteNotifier.value = _unicornPalette;
            await prefs.setInt(_unicornPaletteKey, UnicornPalette.neon.index);
          } else if (m == AppThemeMode.unicornIII) {
            _unicornPalette = UnicornPalette.dreamy;
            unicornPaletteNotifier.value = _unicornPalette;
            await prefs.setInt(_unicornPaletteKey, UnicornPalette.dreamy.index);
          } else if (m == AppThemeMode.unicornIV) {
            _unicornPalette = UnicornPalette.sunset;
            unicornPaletteNotifier.value = _unicornPalette;
            await prefs.setInt(_unicornPaletteKey, UnicornPalette.sunset.index);
          }
          // Persisted theme was removed — migrate to Unicorn (first visible).
          notifier.value = kVisibleThemes.first;
          await prefs.setInt(_prefsKey, kVisibleThemes.first.index);
        }
        return;
      }
      // Old legacy 4-mode index.
      final legacyIdx = prefs.getInt(_legacyKey);
      if (legacyIdx != null) {
        notifier.value = kVisibleThemes.first;
        await prefs.setInt(_prefsKey, kVisibleThemes.first.index);
        await prefs.remove(_legacyKey);
      }
    } catch (_) {
      // Keep default on any persistence failure.
    }
    // Debug-only: audit contrast ratios for all visible themes so
    // accessibility regressions surface during development.
    if (kDebugMode) {
      _auditAllThemeContrast();
    }
  }

  /// Debug-only: print WCAG contrast warnings for every visible theme.
  /// Runs once at startup. Themes that fail the large-text threshold
  /// (3:1) are flagged as FAIL; those that pass large but fail body
  /// (4.5:1) are flagged as WARN. The simulated body-text color follows
  /// the surface luminance — light themes (Neo-Skeuo) are judged with
  /// dark text, matching what [themeFor] actually renders.
  static void _auditAllThemeContrast() {
    for (final mode in kVisibleThemes) {
      if (mode == AppThemeMode.custom) continue;
      final f = mode.flair;
      final results = auditThemeContrast(
        lightSurface: Contrast.luminance(f.card) > 0.5,
        scaffold: f.scaffold,
        card: f.card,
        primary: f.primary,
        secondary: f.secondary,
        headlineStat: f.headlineStat,
        themeLabel: mode.label,
      );
      final failures = results.where((r) => r.fails).toList();
      final warnings = results.where((r) => !r.fails && !r.passesBody).toList();
      if (failures.isNotEmpty || warnings.isNotEmpty) {
        debugPrint('┌─ Contrast: ${mode.label}');
        for (final r in failures) {
          debugPrint('│ FAIL $r');
        }
        for (final r in warnings) {
          debugPrint('│ WARN $r');
        }
        debugPrint('└─');
      }
    }
  }

  /// Persist + apply the picked theme.
  /// For premade themes, curated particle/typo/ambiance settings are
  /// applied to give the theme a complete identity. For custom themes,
  /// only the font is applied (user keeps their visual prefs).
  static Future<void> setMode(AppThemeMode m) async {
    notifier.value = m;
    // Apply the theme's curated font as the new default.
    final themeFont = m.flair.font;
    if (themeFont != null) {
      await VisualPrefs.setFont(themeFont);
    }
    // Apply curated visual settings for premade themes.
    final curation = kThemeCuration[m];
    if (curation != null) {
      await VisualPrefs.applyCuration(curation);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, m.index);
    } catch (_) {
      // Persistence failure is non-fatal.
    }
  }

  /// Force a rebuild of all widgets listening to [notifier] without
  /// changing the mode. Used after custom theme data is edited.
  static void refresh() => notifier.refresh();

  /// True while the Neo-Skeuo alternate skin is the active mode.
  /// Widgets use this to gate skeuo chrome + lock customization.
  static bool get isSkeuo => notifier.value == AppThemeMode.neoSkeuo;

  /// Enter the Neo-Skeuo skin. Remembers the current mode AND the
  /// user's current font so [exitSkeuo] restores the exact prior look.
  /// skeuo's `flair.font` is null and it has no `kThemeCuration` entry,
  /// so entering never mutates VisualPrefs — everything returns intact.
  static Future<void> enterSkeuo() async {
    if (isSkeuo) return;
    final prevMode = notifier.value;
    final prevFont = VisualPrefs.notifier.value.font;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_skeuoPrevModeKey, prevMode.index);
      await prefs.setInt(_skeuoPrevFontKey, prevFont.index);
    } catch (_) {}
    await setMode(AppThemeMode.neoSkeuo);
  }

  /// Exit the Neo-Skeuo skin back to the remembered mode (+ font).
  /// Falls back to the visible default (paperInk / Gungeon font) when
  /// no memory exists or the remembered mode is no longer valid.
  static Future<void> exitSkeuo() async {
    if (!isSkeuo) return;
    var prev = kVisibleThemes.first;
    var prevFont = AppFont.gungeon;
    try {
      final prefs = await SharedPreferences.getInstance();
      final mIdx = prefs.getInt(_skeuoPrevModeKey);
      if (mIdx != null && mIdx >= 0 && mIdx < AppThemeMode.values.length) {
        final m = AppThemeMode.values[mIdx];
        if (m != AppThemeMode.neoSkeuo && kVisibleThemes.contains(m)) {
          prev = m;
        }
      }
      final fIdx = prefs.getInt(_skeuoPrevFontKey);
      if (fIdx != null && fIdx >= 0 && fIdx < AppFont.values.length) {
        prevFont = AppFont.values[fIdx];
      }
    } catch (_) {}
    // setMode applies the restored theme's curated font first, then we
    // put back the user's own pick (covers manual overrides).
    await setMode(prev);
    await VisualPrefs.setFont(prevFont);
  }

  /// Shift every FontWeight in [base] by [bias] × 3 index steps.
  static TextTheme _applyWeightBias(TextTheme base, int bias) {
    if (bias == 0) return base;
    TextStyle? shift(TextStyle? s) {
      if (s == null) return null;
      final w = s.fontWeight ?? FontWeight.w400;
      final idx = (w.value ~/ 100 - 1 + bias * 3).clamp(0, 8);
      return s.copyWith(fontWeight: FontWeight.values[idx]);
    }

    return base.copyWith(
      displayLarge: shift(base.displayLarge),
      displayMedium: shift(base.displayMedium),
      displaySmall: shift(base.displaySmall),
      headlineLarge: shift(base.headlineLarge),
      headlineMedium: shift(base.headlineMedium),
      headlineSmall: shift(base.headlineSmall),
      titleLarge: shift(base.titleLarge),
      titleMedium: shift(base.titleMedium),
      titleSmall: shift(base.titleSmall),
      bodyLarge: shift(base.bodyLarge),
      bodyMedium: shift(base.bodyMedium),
      bodySmall: shift(base.bodySmall),
      labelLarge: shift(base.labelLarge),
      labelMedium: shift(base.labelMedium),
      labelSmall: shift(base.labelSmall),
    );
  }

  /// Build the concrete [ThemeData] for the given [mode]. Surfaces,
  /// card radius and primary/secondary are pulled from [flairFor] so
  /// the MaterialApp palette and the custom widgets stay in lock-step.
  static ThemeData themeFor(AppThemeMode m) {
    final f = flairFor(m);
    final prefs = VisualPrefs.notifier.value;
    final bias = prefs.fontWeightBias;
    final selectedFont =
        m == AppThemeMode.neoSkeuo
            ? AppFont.shantellSans
            : m == AppThemeMode.custom && _cachedCustomTheme != null
            ? _cachedCustomTheme!.font
            : prefs.font;

    // Build a deliberate type scale with tuned sizes, heights, and
    // letter-spacings — never the raw Material/Google Fonts defaults.
    // The font family is applied via ThemeData.fontFamily below, so the
    // type scale values are preserved when the font changes.
    //
    // onSurface is derived from the surface luminance so that text
    // stays readable on any flair — dark surfaces get off-white text,
    // light surfaces get near-black text. This prevents the white-text-
    // on-light-fill contrast bug (U-002).
    final surfaceLum = Contrast.luminance(f.card);
    final onSurface =
        surfaceLum > 0.5
            ? const Color(0xFF1E1E22) // dark text on light surface
            : const Color(0xFFF0F0F0); // off-white text on dark surface
    final onSurfaceVariant = onSurface.withValues(alpha: 0.7);
    // Light surfaces (Neo-Skeuo's cream paper) need a light scheme so
    // M3 chrome roles (nav bar, dialogs, sheets, switches) stay
    // coherent — a dark scheme would paint dark containers on paper.
    final scheme =
        surfaceLum > 0.5
            ? ColorScheme.light(
              primary: f.primary,
              secondary: f.secondary,
              surface: f.card,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
            )
            : ColorScheme.dark(
              primary: f.primary,
              secondary: f.secondary,
              surface: f.card,
              onSurface: onSurface,
              onSurfaceVariant: onSurfaceVariant,
            );
    var textTheme = buildAppTextTheme(scheme);
    textTheme = _applyWeightBias(textTheme, bias);

    String? fontFamilyName;
    if (selectedFont == AppFont.gungeon) {
      fontFamilyName = 'EnterTheGungeonBig';
    } else if (selectedFont == AppFont.shantellSans) {
      // Bundled asset family (offline-first like EnterTheGungeonBig).
      fontFamilyName = 'ShantellSans';
    } else {
      try {
        fontFamilyName = GoogleFonts.getFont(selectedFont.label).fontFamily;
      } catch (_) {
        fontFamilyName = 'EnterTheGungeonBig';
      }
    }

    // CRITICAL: Apply the font family to the textTheme itself, not just
    // ThemeData.fontFamily. ThemeData.fontFamily is a fallback that only
    // applies to Text widgets with no TextStyle at all. Text widgets that
    // use Theme.of(context).textTheme.* or inherit via DefaultTextStyle
    // get the style from textTheme — if those styles have fontFamily: null,
    // Flutter uses the platform default (Roboto), NOT ThemeData.fontFamily.
    // Applying here ensures every text style carries the picked font.
    if (fontFamilyName != null) {
      textTheme = textTheme.apply(fontFamily: fontFamilyName);
    }

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFamilyName,
      scaffoldBackgroundColor: Colors.transparent,
      cardColor: f.card,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: (textTheme.titleMedium ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelStyle: (textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: (textTheme.titleSmall ?? const TextStyle())
            .copyWith(fontWeight: FontWeight.w600),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      cardTheme: CardThemeData(
        color: f.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(f.cardRadius),
          side: BorderSide(
            color: f.cardBorderColor ?? f.primary.withValues(alpha: 0.16),
            width: f.cardBorderColor != null ? f.cardBorderWidth : 1.2,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 24),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.white.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.pressed)) {
              return f.primary.withValues(alpha: 0.88);
            }
            return f.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return onSurface.withValues(alpha: 0.38);
            }
            // Contrast-correct foreground for the primary fill: dark
            // text on light primaries, light text on dark primaries.
            return Contrast.luminance(f.primary) > 0.5
                ? const Color(0xFF1E1E22)
                : const Color(0xFFF0F0F0);
          }),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: f.dividerColor,
        thickness: f.dividerThickness,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Concrete flair for each theme. Kept in one place so the picker
  /// preview and the live app read the exact same values.
  static ThemeFlair flairFor(AppThemeMode m) => m.flair;
}

/// A [ValueNotifier] that exposes [refresh] so external callers can
/// force a rebuild without changing the value.
class RefreshableValueNotifier<T> extends ValueNotifier<T> {
  RefreshableValueNotifier(super.value);
  void refresh() => notifyListeners();
}

// =============================================================================
// Typed particle color schemas — 3 flavored palettes per picker theme.
// Each theme gets names that feel like its own fantasy.
// =============================================================================

/// (name, colors) per theme — index 0 is the theme's signature look.
