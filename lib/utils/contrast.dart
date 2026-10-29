import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// WCAG 2.1 contrast ratio utilities.
///
/// Used by the debug-only theme contrast check to flag text/background
/// pairs that fall below the accessibility threshold:
///   - Body text: ≥ 4.5:1
///   - Large text (≥ 18pt or ≥ 14pt bold) and UI components: ≥ 3:1
class Contrast {
  const Contrast._();

  /// Minimum contrast for body text.
  static const double bodyMin = 4.5;

  /// Minimum contrast for large text and UI components.
  static const double largeMin = 3.0;

  /// Compute the WCAG relative luminance of a colour.
  static double luminance(Color c) {
    double channel(double v) {
      v /= 255.0;
      return v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  /// Contrast ratio between two colours (always ≥ 1.0).
  static double ratio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// True if [foreground] on [background] meets the body-text threshold.
  static bool passesBody(Color foreground, Color background) =>
      ratio(foreground, background) >= bodyMin;

  /// True if [foreground] on [background] meets the large-text threshold.
  static bool passesLarge(Color foreground, Color background) =>
      ratio(foreground, background) >= largeMin;
}

/// A single contrast check result.
class ContrastResult {
  final String label;
  final Color foreground;
  final Color background;
  final double ratio;
  final bool passesBody;
  final bool passesLarge;

  const ContrastResult({
    required this.label,
    required this.foreground,
    required this.background,
    required this.ratio,
    required this.passesBody,
    required this.passesLarge,
  });

  bool get fails => !passesLarge;

  @override
  String toString() {
    final status =
        passesBody
            ? 'OK'
            : passesLarge
            ? 'WARN (large only)'
            : 'FAIL';
    return '$label: ${ratio.toStringAsFixed(2)}:1 [$status]';
  }
}

/// Run contrast checks for a [ThemeFlair]'s key text/background pairs.
/// Returns a list of results; any with `fails == true` are below the
/// large-text threshold and should be flagged.
///
/// Call this only in debug mode — it's a development-time guardrail,
/// not a runtime cost we want in release builds.
List<ContrastResult> auditThemeContrast({
  required Color scaffold,
  required Color card,
  required Color primary,
  required Color secondary,
  required Color headlineStat,
  required String themeLabel,
}) {
  // Heuristic text colours: most text in the app is white or near-white
  // on dark surfaces, with accent colours for headlines and labels.
  const bodyText = Color(0xFFFFFFFF);
  const subtleText = Color(0xB3FFFFFF); // 70% white — common secondary text

  final pairs = <(String, Color, Color)>[
    ('Body text on scaffold', bodyText, scaffold),
    ('Body text on card', bodyText, card),
    ('Subtle text on scaffold', subtleText, scaffold),
    ('Subtle text on card', subtleText, card),
    ('Primary on scaffold', primary, scaffold),
    ('Primary on card', primary, card),
    ('Secondary on scaffold', secondary, scaffold),
    ('Secondary on card', secondary, card),
    ('Headline stat on scaffold', headlineStat, scaffold),
    ('Headline stat on card', headlineStat, card),
  ];

  return pairs.map((p) {
    final r = Contrast.ratio(p.$2, p.$3);
    return ContrastResult(
      label: '$themeLabel: ${p.$1}',
      foreground: p.$2,
      background: p.$3,
      ratio: r,
      passesBody: r >= Contrast.bodyMin,
      passesLarge: r >= Contrast.largeMin,
    );
  }).toList();
}

/// Debug-only: print contrast warnings for all visible themes.
/// Call this once at startup (guarded by `kDebugMode`) to surface
/// any themes that fail WCAG contrast thresholds.
void debugPrintContrastWarnings() {
  if (!kDebugMode) return;
  // Lazy import avoided — callers pass results in.
  // This is a no-op stub; the actual iteration lives in the caller
  // which has access to the theme enum.
}
