import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Six persistent favorite colors for the studio palette sheet.
///
/// Slots are positional and stable across sessions; `0` = empty.
/// App-level state (own SharedPreferences key) — deliberately NOT part
/// of [VisualPrefs] so favorites survive preset switches and never
/// ride inside saved custom themes.
///
/// Used by `_PaletteColorSheet`: tap a filled slot to use the color,
/// long-press to replace or clear it.
class ColorFavorites {
  ColorFavorites._();

  static const slotCount = 6;
  static const _kKey = 'vp.color_favorites_v1';

  /// ARGB ints, index = slot. Listenable so the sheet rebuilds on edit.
  static final ValueNotifier<List<int>> slots = ValueNotifier(
    List<int>.filled(slotCount, 0),
  );

  static bool _loaded = false;

  /// Hydrate from disk. Call from `main()` before `runApp`.
  static Future<void> init() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kKey);
      if (raw == null || raw.isEmpty) return;
      final list =
          (jsonDecode(raw) as List)
              .map((e) => (e as num).toInt())
              .toList();
      if (list.length == slotCount) slots.value = list;
    } catch (_) {
      // Corrupt entry — start empty rather than crash the sheet.
    }
  }

  /// Write a slot (argb 0 clears it) and persist immediately.
  static Future<void> setSlot(int index, int argb) async {
    if (index < 0 || index >= slotCount) return;
    final next = List<int>.from(slots.value);
    next[index] = argb;
    slots.value = next;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kKey, jsonEncode(next));
    } catch (_) {}
  }

  /// Resolved color for a slot, or null when empty.
  static Color? colorAt(int index) {
    if (index < 0 || index >= slotCount) return null;
    final v = slots.value[index];
    return v == 0 ? null : Color(v);
  }
}
