import 'package:flutter/material.dart';

/// Design tokens for the Neo-Skeuo "hand-drawn kit" skin.
///
/// Mirrors the reference kit's rules: cream paper, black ink strokes,
/// hatched offset shadows, 1/2/4px border weights, 0/4/8/12 radius
/// scale, 2px icon stroke. Everything skeuo reads from here — never
/// inline a cream/ink literal outside this file and the mode's flair.
abstract final class Skeuo {
  // ── Palette ──────────────────────────────────────────────────
  /// Warm paper page — scaffold.
  static const Color paper = Color(0xFFF2E9D3);

  /// Slightly lighter raised paper — cards, buttons, fills.
  static const Color card = Color(0xFFFAF5E8);

  /// Deeper pressed/inset paper — inset wells, pressed fills.
  static const Color insetPaper = Color(0xFFE6DCC4);

  /// The one true ink — borders, strokes, primary fills, text.
  static const Color ink = Color(0xFF1F1B16);

  /// Pencil-gray secondary ink — hints, captions, disabled.
  static const Color pencil = Color(0xFF5C5548);

  /// Red pencil — the kit's single annotation accent (errors, badges).
  static const Color accent = Color(0xFF8C3B2E);

  /// Ochre pencil — secondary annotation accent (highlights, active).
  static const Color ochre = Color(0xFF8A6D2F);

  /// Blue pencil — info annotation.
  static const Color bluePencil = Color(0xFF3E5C6E);

  // ── Border weights (kit rule: 1px / 2px / 4px) ───────────────
  static const double borderThin = 1.0;
  static const double borderMed = 2.0;
  static const double borderThick = 4.0;

  // ── Radius scale (kit rule: 0 / 4 / 8 / 12) ──────────────────
  static const double rSharp = 0;
  static const double rSm = 4;
  static const double rMd = 8;
  static const double rLg = 12;

  // ── Elevation → offset-shadow distance (kit levels 1/2/3) ────
  static const double shadowLow = 5;
  static const double shadowMed = 5;
  static const double shadowHigh = 8;

  /// Diagonal hatch-line spacing inside the offset shadow.
  static const double hatchGap = 4.5;
}
