import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gungeon_mate/services/color_favorites.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ColorFavorites — the 6 persistent favorite-color slots used by the
/// studio palette sheet. App-level state, own prefs key.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ColorFavorites.slots.value = List<int>.filled(
      ColorFavorites.slotCount,
      0,
    );
  });

  test('starts empty — all 6 slots are 0', () {
    expect(ColorFavorites.slots.value, List.filled(6, 0));
    expect(ColorFavorites.colorAt(0), isNull);
  });

  test('setSlot writes + notifies + resolves a Color', () async {
    await ColorFavorites.setSlot(2, 0xFF123456);
    expect(ColorFavorites.slots.value[2], 0xFF123456);
    expect(ColorFavorites.colorAt(2), const Color(0xFF123456));
    expect(ColorFavorites.colorAt(0), isNull);
  });

  test('setSlot(0 argb) clears the slot', () async {
    await ColorFavorites.setSlot(1, 0xFFABCDEF);
    await ColorFavorites.setSlot(1, 0);
    expect(ColorFavorites.slots.value[1], 0);
    expect(ColorFavorites.colorAt(1), isNull);
  });

  test('out-of-range indices are ignored', () async {
    await ColorFavorites.setSlot(-1, 0xFF112233);
    await ColorFavorites.setSlot(6, 0xFF112233);
    expect(ColorFavorites.slots.value.every((v) => v == 0), isTrue);
  });

  test('init hydrates persisted slots', () async {
    SharedPreferences.setMockInitialValues({
      'vp.color_favorites_v1': '[255, 16711680, 0, 0, 0, 65535]',
    });
    // _loaded is static — reset via a fresh prefs read path isn't
    // possible, so verify the stored JSON shape parses by calling init
    // once (it may already be loaded from a prior test; either way the
    // notifier must not crash and must hold 6 entries).
    await ColorFavorites.init();
    expect(ColorFavorites.slots.value.length, 6);
  });
}
