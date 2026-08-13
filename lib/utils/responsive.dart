import 'package:flutter/widgets.dart';

/// Responsive scaling helper.
///
/// Baseline is 400dp (typical phone width like OnePlus 8).
/// On wider screens, values scale up proportionally (clamped to 1.0–1.25x)
/// so UI elements don't look tiny on bigger phones.
/// On narrower screens, values scale down (clamped to 0.85x).
///
/// Usage: `Responsive.scale(context, 16)` → 16 on 400dp, ~20 on 500dp.
class Responsive {
  Responsive._();

  /// Linear scale factor based on screen width relative to 400dp baseline.
  static double factor(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return ((w / 400.0) - 1.0).clamp(-0.15, 0.25) + 1.0;
  }

  /// Scale a pixel value proportionally to screen width.
  static double scale(BuildContext context, double v) {
    return v * factor(context);
  }

  /// Scale a font size — same as [scale] but rounded for crisp rendering.
  static double font(BuildContext context, double v) {
    return (v * factor(context)).roundToDouble();
  }
}
