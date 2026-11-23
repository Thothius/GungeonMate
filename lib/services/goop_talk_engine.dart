import 'package:flutter/material.dart';
import 'app_theme.dart';

/// GoopText — the app's standard text widget.
///
/// History: this file used to scramble real letters into ⏃⎎⎓-style
/// "Goopian" glyphs (removed v3.1.1 for readability) and later drove a
/// route-change re-scramble via [GoopAnimationManager.pulse] (removed
/// 2026-11-25 — the manager was a no-op). What remains is a plain
/// [Text] passthrough that applies the user's font weight bias and
/// letter-spacing prefs, so the ~950 call sites keep working unchanged.
class GoopText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const GoopText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    // Global weight bias — shifts every text's weight ±2 steps so
    // 200/400/600/800/1000 picks actually change the app. Fonts with
    // a single variant (Gungeon, Megrim, Bungee…) render unchanged.
    final bias = VisualPrefs.notifier.value.fontWeightBias;
    var effective = style;
    if (bias != 0 && style?.fontWeight != null) {
      final idx = (style!.fontWeight!.value ~/ 100 - 1 + bias).clamp(0, 8);
      effective = style!.copyWith(fontWeight: FontWeight.values[idx]);
    }
    final spacing = VisualPrefs.notifier.value.fontLetterSpacing;
    if (spacing != 0) {
      effective = (effective ?? const TextStyle()).copyWith(
        letterSpacing: ((effective?.letterSpacing ?? 0) + spacing * 0.5),
      );
    }
    return Text(
      text,
      style: effective,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
