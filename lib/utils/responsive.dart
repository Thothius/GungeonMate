import 'package:flutter/widgets.dart';

/// Responsive scaling + screen-profile helper.
///
/// The app targets phones first but must adapt gracefully to tablets, foldables,
/// and desktop windows. Two layers are provided:
///
/// 1. [Responsive] — the legacy scalar helpers (`scale`, `font`, `factor`).
///    Width-only, baseline 400dp. Used across ~14 files; kept for compatibility.
/// 2. [ScreenProfile] — a richer snapshot of the available window, classifying
///    both width and height into Material 3 breakpoints and exposing
///    height-aware convenience flags. Prefer this for new code.
///
/// Material 3 canonical breakpoints (dp):
///   compact  < 600   (phones portrait)
///   medium   600–839 (small tablets, foldables, phone landscape)
///   expanded 840–1199 (large tablets, desktop)
///   large    ≥ 1200  (desktop wide)
///
/// Per Flutter 2026 guidance: base layout on the *window* size, not the device
/// type. Use [LayoutBuilder] when reacting to parent constraints; use
/// [ScreenProfile.of] (which reads `MediaQuery.sizeOf`) for screen-level
/// decisions.
class Responsive {
  Responsive._();

  /// Linear scale factor based on screen width relative to 400dp baseline.
  static double factor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
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

  /// Height-aware scale factor relative to a 800dp baseline (typical phone
  /// height in portrait). Clamped to 0.85–1.20x so short screens shrink
  /// vertical metrics without crushing them, and tall screens grow slightly.
  static double heightFactor(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return ((h / 800.0) - 1.0).clamp(-0.15, 0.20) + 1.0;
  }

  /// Scale a vertical pixel value proportionally to screen height.
  static double scaleHeight(BuildContext context, double v) {
    return v * heightFactor(context);
  }

  /// Combined scale: the smaller of width and height factors, so a value
  /// never overflows either axis. Ideal for elements that must fit in both
  /// dimensions (e.g. grid cells, square badges).
  static double minScale(BuildContext context) {
    final wf = factor(context);
    final hf = heightFactor(context);
    return wf < hf ? wf : hf;
  }
}

/// Material 3 window-size class.
enum WindowClass { compact, medium, expanded, large }

/// A snapshot of the available window, classified by width and height.
///
/// Obtain via [ScreenProfile.of(context)]. The profile rebuilds only when the
/// window [Size] changes (it reads `MediaQuery.sizeOf`, not the full
/// `MediaQuery`), so it is safe to call in `build`.
class ScreenProfile {
  const ScreenProfile({
    required this.width,
    required this.height,
    required this.widthClass,
    required this.heightClass,
    required this.padding,
    required this.viewInsets,
  });

  /// Width of the app window in dp.
  final double width;

  /// Height of the app window in dp.
  final double height;

  /// Material 3 breakpoint for the window width.
  final WindowClass widthClass;

  /// Material 3 breakpoint for the window height.
  final WindowClass heightClass;

  /// Safe-area insets (notches, status bar, gesture nav).
  final EdgeInsets padding;

  /// Keyboard / system UI insets currently covering the view.
  final EdgeInsets viewInsets;

  /// Usable height excluding safe-area padding and keyboard.
  double get usableHeight => height - padding.vertical - viewInsets.vertical;

  /// Usable width excluding safe-area padding.
  double get usableWidth => width - padding.horizontal;

  // ── Width-class convenience ──────────────────────────────────────────
  bool get isCompactWidth => widthClass == WindowClass.compact;
  bool get isMediumWidth => widthClass == WindowClass.medium;
  bool get isExpandedWidth =>
      widthClass == WindowClass.expanded || widthClass == WindowClass.large;

  // ── Height-class convenience ─────────────────────────────────────────
  bool get isCompactHeight => heightClass == WindowClass.compact;
  bool get isMediumHeight => heightClass == WindowClass.medium;
  bool get isExpandedHeight =>
      heightClass == WindowClass.expanded || heightClass == WindowClass.large;

  /// True when vertical space is tight enough that screens risk scrolling.
  /// Below ~700dp usable height, fixed-aspect grids and large headers overflow.
  bool get isShort => usableHeight < 700;

  /// True when the window is genuinely small in both axes — a small phone in
  /// portrait. Use this to switch to the most compact layout variant.
  bool get isSmallPhone => isCompactWidth && isShort;

  /// The smaller of the width and height scale factors — use for elements
  /// that must fit in both dimensions.
  double get minScale {
    final wf = ((width / 400.0) - 1.0).clamp(-0.15, 0.25) + 1.0;
    final hf = ((height / 800.0) - 1.0).clamp(-0.15, 0.20) + 1.0;
    return wf < hf ? wf : hf;
  }

  /// Pick a grid column count for a given item count, so the grid fills the
  /// width without leaving an awkward single orphan in the last row.
  ///
  /// Uses Material 3 width classes:
  ///   compact  → 3 columns (phone portrait)
  ///   medium   → 4 columns (tablet / foldable)
  ///   expanded → 5–6 columns (desktop)
  /// The result is clamped so the last row is at least half full.
  int columnsFor(int itemCount) {
    final base = switch (widthClass) {
      WindowClass.compact => 3,
      WindowClass.medium => 4,
      WindowClass.expanded => 5,
      WindowClass.large => 6,
    };
    // Avoid a lonely orphan in the last row: if the remainder is 1 and we
    // have room to drop a column, do so (e.g. 9 items → 3 cols not 4).
    if (itemCount % base == 1 && base > 2) {
      final alt = base - 1;
      if (itemCount % alt == 0) return alt;
    }
    return base;
  }

  /// Build a [ScreenProfile] from the current [MediaQuery] snapshot.
  static ScreenProfile of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final mq = MediaQuery.of(context);
    return ScreenProfile(
      width: size.width,
      height: size.height,
      widthClass: _classFor(size.width),
      heightClass: _classFor(size.height),
      padding: mq.padding,
      viewInsets: mq.viewInsets,
    );
  }

  /// Build a [ScreenProfile] from an explicit [Size] (for tests / LayoutBuilder
  /// constraints where you want to classify the parent-given box, not the
  /// whole window).
  factory ScreenProfile.fromSize(Size size, {EdgeInsets? padding}) {
    return ScreenProfile(
      width: size.width,
      height: size.height,
      widthClass: _classFor(size.width),
      heightClass: _classFor(size.height),
      padding: padding ?? EdgeInsets.zero,
      viewInsets: EdgeInsets.zero,
    );
  }

  static WindowClass _classFor(double dp) {
    if (dp < 600) return WindowClass.compact;
    if (dp < 840) return WindowClass.medium;
    if (dp < 1200) return WindowClass.expanded;
    return WindowClass.large;
  }

  @override
  String toString() =>
      'ScreenProfile(${width.round()}×${height.round()} $widthClass/$heightClass'
      '${isShort ? ' short' : ''})';
}
