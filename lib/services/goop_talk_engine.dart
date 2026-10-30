import 'package:flutter/material.dart';
import 'app_theme.dart';

/// The goop text-scramble mechanic was removed (v3.1.1 cleanup) — it
/// randomized real letters into ⏃⎎⎓-style glyphs mid-read, hurting
/// readability and breaking text finders in widget tests.
///
/// GoopText is kept as a plain [Text] passthrough so the ~700 call
/// sites across the app keep working unchanged. The animation manager
/// is a no-op for API compatibility with the pulse() call sites.
class GoopAnimationManager {
  static final GoopAnimationManager instance = GoopAnimationManager._();
  GoopAnimationManager._();

  /// Always 1.0 ("fully revealed") — kept for any stale listener.
  final ValueNotifier<double> progress = ValueNotifier(1.0);

  /// No-op — the scramble ticker is gone.
  void pulse() {}
}

/// Plain text widget — identical API to the old scrambling widget.
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
    // a single variant (Gungeon, Megrim, Russo One) render unchanged.
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
