import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-selectable haptics intensity.
///
/// - [off]   : every call is a no-op. For users who hate haptics or are
///             running on a buzzy low-end device.
/// - [light] : only routine taps & selections fire (light + selection).
///             Long-press, destructive, success and warning calls are
///             downgraded to silent — the visual confirmation carries.
/// - [full]  : default. Every call uses its system-mapped strength.
enum HapticsIntensity { off, light, full }

extension HapticsIntensityLabel on HapticsIntensity {
  String get label {
    switch (this) {
      case HapticsIntensity.off:
        return 'Off';
      case HapticsIntensity.light:
        return 'Light';
      case HapticsIntensity.full:
        return 'Full';
    }
  }

  String get description {
    switch (this) {
      case HapticsIntensity.off:
        return 'No vibration anywhere';
      case HapticsIntensity.light:
        return 'Only quiet taps and picker confirmations';
      case HapticsIntensity.full:
        return 'Default — every action vibrates';
    }
  }
}

/// Thin wrapper around [HapticFeedback] so the whole app can lean on a
/// consistent vocabulary:
///
/// - [Haptics.light]      — for every routine tap (tile tap, chip tap).
/// - [Haptics.selection]  — when the user commits a picker choice (shrine,
///                          character, sort option).
/// - [Haptics.medium]     — when a long-press fires (quick menu, transfer).
/// - [Haptics.heavy]      — destructive actions (destroy item, end run,
///                          remove player).
/// - [Haptics.success]    — positive state change (synergy activated,
///                          transfer complete).
/// - [Haptics.warning]    — confirm-first dialogs, reversible destructive
///                          actions surfacing an UNDO snackbar.
///
/// Each call is gated by the user's [intensity] preference (loaded once
/// at startup via [init]). On platforms that don't support haptics
/// (web, desktop), every call is a no-op anyway — the underlying
/// `HapticFeedback.*` methods swallow the unsupported-platform case.
class Haptics {
  const Haptics._();

  static const String _prefsKey = 'haptics.intensity';

  /// Active intensity. Mutated by [init] on app start and by
  /// [setIntensity] when the user changes it from settings. Defaults to
  /// [HapticsIntensity.full] so first-launch users get the full
  /// experience without prefs hydration completing first.
  static HapticsIntensity intensity = HapticsIntensity.full;

  /// Hydrate [intensity] from disk. Call once from `main()` before
  /// `runApp`. Safe to call multiple times. Any platform failure is
  /// swallowed so a broken `SharedPreferences` plugin can never block
  /// app startup — the in-memory default just stays in place.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idx = prefs.getInt(_prefsKey);
      if (idx != null && idx >= 0 && idx < HapticsIntensity.values.length) {
        intensity = HapticsIntensity.values[idx];
      }
    } catch (_) {
      // Keep [intensity] at its [HapticsIntensity.full] default.
    }
  }

  /// Persist the user's choice and apply it immediately. The in-memory
  /// [intensity] is updated synchronously so the very next haptics
  /// call honours it; the disk write is best-effort.
  static Future<void> setIntensity(HapticsIntensity v) async {
    intensity = v;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, v.index);
    } catch (_) {
      // Persistence failure is non-fatal: the in-memory choice still
      // applies for this session.
    }
  }

  static Future<void> light() {
    if (intensity == HapticsIntensity.off) return Future.value();
    return HapticFeedback.lightImpact();
  }

  static Future<void> medium() {
    if (intensity != HapticsIntensity.full) return Future.value();
    return HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() {
    if (intensity != HapticsIntensity.full) return Future.value();
    return HapticFeedback.heavyImpact();
  }

  static Future<void> selection() {
    if (intensity == HapticsIntensity.off) return Future.value();
    return HapticFeedback.selectionClick();
  }

  /// Two-pulse "ding" — light then medium — used when a positive state
  /// change happens (synergy fires, transfer succeeds). There's no
  /// dedicated system API for this, so we synthesise it.
  static Future<void> success() async {
    if (intensity == HapticsIntensity.off) return;
    if (intensity == HapticsIntensity.light) {
      await HapticFeedback.lightImpact();
      return;
    }
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    await HapticFeedback.mediumImpact();
  }

  /// Single medium pulse used before confirm dialogs so the user notices
  /// a reversible-but-serious action (remove item from run).
  static Future<void> warning() {
    if (intensity != HapticsIntensity.full) return Future.value();
    return HapticFeedback.mediumImpact();
  }
}
