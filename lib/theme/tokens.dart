import 'package:flutter/material.dart';

/// Design tokens for GungeonMate.
///
/// The single source of truth for spacing, radii, and motion durations.
/// Widgets should reference these constants instead of inline magic
/// numbers. Theme-specific values (card radius, chip radius) remain on
/// `ThemeFlair` — these tokens are the app-wide baseline that doesn't
/// change per theme.
///
/// See: docs/REASSESSMENT_2026.md Phase 2 — Design tokens.

/// 4pt spacing scale. The only paddings/gaps that exist in this app.
///
/// Usage: `padding: const EdgeInsets.all(Insets.md)`,
///        `SizedBox(width: Insets.lg)`, etc.
abstract final class Insets {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;
}

/// One radius family. Theme-specific card/chip radii stay on `ThemeFlair`;
/// these are the app-wide defaults for non-themed surfaces (sheets,
/// dialogs, inputs, badges).
abstract final class Radii {
  static const Radius sm = Radius.circular(8);
  static const Radius md = Radius.circular(12);
  static const Radius lg = Radius.circular(16);

  static const BorderRadius card = BorderRadius.all(md);
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(24),
  );
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// Motion tokens. Canonical duration rules — see motion-design skill.
///
/// - Press feedback / small state:    `fast`  (150ms)
/// - In-place UI transitions:          `base`  (250ms)
/// - Container/sheet/dialog enters:    `enter` (400ms, decelerate)
/// - Exits (50-75% of matching enter): `exit`  (250ms, accelerate)
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration enter = Duration(milliseconds: 400);
  static const Duration exit = Duration(milliseconds: 250);
}

/// Raw font size constants — the numeric values from [TypeScale],
/// extracted as standalone `double` constants so they can be used
/// in `const` expressions and arithmetic (e.g. `fontSize * sf`).
///
/// Use these when you need just the size value, not the full TextStyle.
/// Use [TypeScale] when you want the complete style template.
abstract final class FontSizes {
  static const double labelSmall = 10;
  static const double labelMedium = 12;
  static const double bodyMedium = 14;
  static const double titleSmall = 16;
  static const double titleMedium = 18;
  static const double titleLarge = 22;
  static const double headlineSmall = 24;
  static const double headlineMedium = 28;
  static const double displaySmall = 32;
}

/// Type scale — deliberate sizes, heights, and letter-spacings.
///
/// These are **colorless** TextStyle templates. Color is applied at use
/// time via `Theme.of(context).textTheme` (which `.apply()`s the scheme
/// colors). This prevents the light-text-on-light-background bug when
/// the theme switches.
///
/// Hierarchy = size + weight, not color. Body text ≥ 14lp.
abstract final class TypeScale {
  // Display — big stat readouts (DPS, Coolness, Curse)
  static const TextStyle displaySmall = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
  );

  // Headline — section headers, screen titles
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  // Title — card titles, tab labels, dialog titles
  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0.2,
  );

  // Body — descriptions, item notes, list content
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Label — buttons, chips, badges, captions
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.3,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0.2,
  );
}

/// Build a complete [TextTheme] from the [TypeScale] templates, with
/// colors applied from the given [ColorScheme]. This ensures every
/// text role has a deliberate size, weight, height, and letterSpacing
/// — never the raw Material defaults.
///
/// Pass this to `ThemeData.textTheme`. The per-theme font family is
/// applied separately via `ThemeData.fontFamily`.
TextTheme buildAppTextTheme(ColorScheme scheme) {
  return TextTheme(
    displaySmall: TypeScale.displaySmall.copyWith(color: scheme.onSurface),
    displayMedium: TypeScale.displaySmall.copyWith(
      color: scheme.onSurface,
      fontSize: 36,
    ),
    displayLarge: TypeScale.displaySmall.copyWith(
      color: scheme.onSurface,
      fontSize: 40,
    ),
    headlineSmall: TypeScale.headlineSmall.copyWith(color: scheme.onSurface),
    headlineMedium: TypeScale.headlineMedium.copyWith(color: scheme.onSurface),
    headlineLarge: TypeScale.headlineMedium.copyWith(
      color: scheme.onSurface,
      fontSize: 32,
    ),
    titleSmall: TypeScale.titleSmall.copyWith(color: scheme.onSurface),
    titleMedium: TypeScale.titleMedium.copyWith(color: scheme.onSurface),
    titleLarge: TypeScale.titleLarge.copyWith(color: scheme.onSurface),
    bodySmall: TypeScale.bodySmall.copyWith(color: scheme.onSurfaceVariant),
    bodyMedium: TypeScale.bodyMedium.copyWith(color: scheme.onSurface),
    bodyLarge: TypeScale.bodyLarge.copyWith(color: scheme.onSurface),
    labelSmall: TypeScale.labelSmall.copyWith(color: scheme.onSurfaceVariant),
    labelMedium: TypeScale.labelMedium.copyWith(color: scheme.onSurface),
    labelLarge: TypeScale.labelLarge.copyWith(color: scheme.onSurface),
  );
}

/// Semantic identity colors for Codex/Ammonomicon categories.
///
/// These are **fixed identity colors** — each category has a distinct
/// color that users learn to recognize (Gungeoneers=blue, NPCs=red,
/// Enemies=orange, etc.). They do NOT change with the active theme;
/// they're game-data identity, not theme chrome. Extracted as named
/// constants so the intent is documented and the values aren't
/// sprinkled as magic hex across screen files.
abstract final class CodexColors {
  static const Color gungeoneers = Color(0xFF42A5F5);
  static const Color npcs = Color(0xFFEF5350);
  static const Color enemies = Color(0xFFFF7043);
  static const Color bosses = Color(0xFFAB47BC);
  static const Color pickups = Color(0xFF42A5F5);
  static const Color objects = Color(0xFF66BB6A);
  static const Color rat = Color(0xFFFFB300);
  static const Color dragun = Color(0xFF00E676);
  static const Color bulletHell = Color(0xFFFF5252);
  static const Color challenge = Color(0xFFAB47BC);

  // Codex detail badge accents — also fixed identity.
  static const Color game = Color(0xFF42A5F5);
  static const Color health = Color(0xFFEF5350);
  static const Color location = Color(0xFF66BB6A);
}
