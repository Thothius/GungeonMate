import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/run_provider.dart';
import 'app_theme.dart';
import 'codex_prefs.dart';
import 'color_favorites.dart';
import 'haptics.dart';
import 'home_customization.dart';
import 'mp_session.dart';

/// Coordinates the Settings "RESET ALL DATA" flow.
///
/// Order matters:
/// 1. Tear down MP first — [MpSession.cancel] notifies the peer, restores
///    or clears MP backups, and wipes session activity.
/// 2. Reset every in-memory store to factory defaults BEFORE clearing
///    disk, so any late fire-and-forget `SharedPreferences` write that
///    was already in flight persists defaults instead of old values.
/// 3. `prefs.clear()` wipes every persisted key.
/// 4. Rehydrate from the cleared prefs so notifiers/UI match disk.
///
/// The caller owns navigation afterwards — this service never pops
/// routes so it stays testable without a widget tree.
Future<void> resetAllAppData({
  required RunProvider runProvider,
  required MpSession session,
}) async {
  try {
    if (session.isActive) {
      await session.cancel();
    }
    session.wipeSessionActivity();
  } catch (e) {
    debugPrint('[AppDataReset] MP teardown error: $e');
  }

  // In-memory defaults first (no disk writes from these resets).
  runProvider.resetAllAppData();
  VisualPrefs.notifier.value = const VisualPrefs();
  AppTheme.resetCachesToDefaults();
  CustomThemeStore.reset();
  ColorFavorites.reset();
  CodexPrefs.reset();
  Haptics.reset();
  HomeCustomization.notifier.value = const HomeCustomization();

  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  } catch (e) {
    debugPrint('[AppDataReset] prefs clear error: $e');
  }

  // Rehydrate from cleared prefs.
  await VisualPrefs.init();
  await AppTheme.resetToDefaults();
  await HomeCustomization.load();
}
