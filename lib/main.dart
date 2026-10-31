import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'providers/run_provider.dart';
import 'screens/home_screen.dart';
import 'services/app_theme.dart';
import 'services/home_customization.dart';
import 'services/mp/mp_store.dart' as mp_store;
import 'services/mp/mp_foreground_service.dart';
import 'services/mp_session.dart';
import 'utils/asset_paths.dart' show kAppVersion;
import 'widgets/theme_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Enable video_player on Windows/Linux via media_kit (libmpv) backend.
  // Drop-in — no API change to existing VideoPlayerController usage.
  VideoPlayerMediaKit.ensureInitialized(windows: true);
  // Keep the screen awake while the app is open — runs are long and
  // a sleeping screen mid-run drops MP sessions and loses context.
  // .ignore() swallows MissingPluginException on platforms without a
  // wakelock backend (Windows/Linux) instead of crashing startup.
  WakelockPlus.enable().ignore();
  // Hydrate the user's persisted choices before any UI mounts so the
  // very first frame honours their prefs. Each init() swallows platform
  // failures internally — a broken plugin can't block app startup.
  await AppTheme.init();
  await VisualPrefs.init();
  await CustomThemeStore.load();
  await HomeCustomization.load();
  await mp_store.MpStore.cleanupOldKeys();
  // Foreground-service config for persistent MP sessions (Paradox).
  // Registration only — the service starts when a session connects.
  MpForegroundService.init();
  // Expose the current app version for MP hello diagnostics.
  MpSession.appVersionString = kAppVersion;
  runApp(const GungeonMateApp());
}

class GungeonMateApp extends StatefulWidget {
  const GungeonMateApp({super.key});

  @override
  State<GungeonMateApp> createState() => _GungeonMateAppState();
}

class _GungeonMateAppState extends State<GungeonMateApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Some Android devices return to the app with stale GPU texture
    // memory after a long background pause, producing a one-frame
    // jumble of fonts/sprites until the next paint. Forcing a frame
    // here clears that — see docs/RENDER_GLITCH_NOTES.md.
    if (state == AppLifecycleState.resumed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RunProvider()..loadData()),
        // MpSession depends on the live RunProvider so it can
        // read snapshots to broadcast and apply remote snapshots back.
        // ProxyProvider handles the "build after RunProvider exists"
        // ordering; the session is constructed once and lives for the
        // app lifetime (idle until the user opens the multiplayer
        // screen and picks a role).
        ChangeNotifierProxyProvider<RunProvider, MpSession>(
          // Create with a placeholder — the real RunProvider is injected
          // via updateRunProvider on the first build. This avoids creating
          // a throwaway RunProvider that would desync from the real one.
          create: (context) => MpSession.placeholder(),
          update: (_, runProvider, previous) {
            previous?.updateRunProvider(runProvider);
            return previous ?? MpSession(runProvider);
          },
        ),
      ],
      // Root-level theme subscription: every AppTheme.setMode() AND every
      // previewNotifier pulse rebuilds MaterialApp with a fresh ThemeData
      // so the palette swap is instant AND live-previews app-wide.
      child: ListenableBuilder(
        listenable: Listenable.merge([
          AppTheme.notifier,
          AppTheme.previewNotifier,
        ]),
        builder:
            (_, _) => ValueListenableBuilder<UnicornPalette>(
              valueListenable: AppTheme.unicornPaletteNotifier,
              builder:
                  (_, pal, _) => ValueListenableBuilder<int>(
                    valueListenable: AppTheme.remixNotifier,
                    builder:
                        (_, remix, _) => ValueListenableBuilder<VisualPrefs>(
                          valueListenable: VisualPrefs.notifier,
                          builder:
                              (context, prefs, _) => MaterialApp(
                                title: 'Gungeon Mate',
                                debugShowCheckedModeBanner: false,
                                navigatorObservers: [menuRouteObserver],
                                theme: AppTheme.themeFor(
                                  AppTheme.displayedMode,
                                ),
                                scrollBehavior: const MaterialScrollBehavior()
                                    .copyWith(
                                      dragDevices: {
                                        PointerDeviceKind.touch,
                                        PointerDeviceKind.mouse,
                                        PointerDeviceKind.trackpad,
                                        PointerDeviceKind.stylus,
                                      },
                                    ),
                                // Wraps every route's content in a theme-aware overlay so per-
                                // theme signature flair (Curseblaster red breath, future others)
                                // paints above the scene without each screen needing to opt in.
                                builder: (context, child) {
                                  // In release mode, build exceptions render as a blank widget
                                  // by default — the user sees particles but no UI ("blank view").
                                  // This surfaces a visible error message instead, so crashes are
                                  // diagnosable without a debugger attached.
                                  ErrorWidget.builder = (
                                    FlutterErrorDetails details,
                                  ) {
                                    return Material(
                                      color: const Color(0xFF1E1E22),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.error_outline,
                                                size: 48,
                                                color: Colors.redAccent,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'UI Error: ${details.exception}',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  };
                                  final mediaQuery = MediaQuery.of(context);
                                  return MediaQuery(
                                    data: mediaQuery.copyWith(
                                      // Hard cap: 1.4x is the largest scale our fixed-height
                                      // layouts (heister slots, ADD strips, tier chips) can
                                      // absorb without clipping. The studio slider is
                                      // clamped to match — this guards stale prefs too.
                                      textScaler: TextScaler.linear(
                                        prefs.textScaleFactor.clamp(0.8, 1.4),
                                      ),
                                    ),
                                    child: ThemeOverlay(
                                      child: child ?? const SizedBox.shrink(),
                                    ),
                                  );
                                },
                                home: const HomeScreen(),
                              ),
                        ),
                  ),
            ),
      ),
    );
  }
}
