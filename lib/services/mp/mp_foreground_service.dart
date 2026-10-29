import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the app process (and with it the Nearby Connections radio)
/// alive while the app is minimized or the screen is off — the core
/// of Paradox Mode's "connected until End Run" promise.
///
/// Honest limits: a swipe-kill still terminates the link (any app
/// would die); session auto-restore + pause mode covers that path.
class MpForegroundService {
  MpForegroundService._();

  static bool _running = false;
  static bool get isRunning => _running;

  /// Call once at app startup (main.dart).
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'gm_paradox_session',
        channelName: 'Paradox Session',
        channelDescription:
            'Keeps your multiplayer session alive in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        showWhen: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start the keep-alive notification when an MP session connects.
  static Future<void> start(String runTitle) async {
    if (_running) return;
    try {
      if (await FlutterForegroundTask.isRunningService) {
        _running = true;
        return;
      }
      await FlutterForegroundTask.startService(
        notificationTitle: 'Paradox session active',
        notificationText:
            runTitle.isEmpty ? 'Staying connected to your partner' : runTitle,
      );
      _running = true;
    } catch (_) {
      // Service failure is non-fatal — session works without it.
    }
  }

  /// Stop the service on teardown (end run / leave MP).
  static Future<void> stop() async {
    if (!_running) return;
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}
    _running = false;
  }
}
