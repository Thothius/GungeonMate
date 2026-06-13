import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/run_provider.dart';
import 'screens/home_screen.dart';
import 'services/app_theme.dart';
import 'services/multiplayer_service.dart';
import 'services/multiplayer_session.dart';
import 'widgets/theme_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hydrate the user's persisted choices before any UI mounts so the
  // very first frame honours their prefs. Each init() swallows platform
  // failures internally — a broken plugin can't block app startup.
  await AppTheme.init();
  await VisualPrefs.init();
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
        // MultiplayerSession depends on the live RunProvider so it can
        // read snapshots to broadcast and apply remote snapshots back.
        // ProxyProvider handles the "build after RunProvider exists"
        // ordering; the session is constructed once and lives for the
        // app lifetime (idle until the user opens the multiplayer
        // screen and picks a role).
        ChangeNotifierProxyProvider<RunProvider, MultiplayerSession>(
          create: (_) => MultiplayerSession(
            MultiplayerService(),
            // Placeholder - will be replaced immediately via update()
            RunProvider(),
          ),
          update: (_, runProvider, previous) {
            // Update the existing session's RunProvider reference rather
            // than creating a new session (which would lose connection state).
            previous?.updateRunProvider(runProvider);
            return previous ?? MultiplayerSession(MultiplayerService(), runProvider);
          },
        ),
      ],
      // Root-level theme subscription: every AppTheme.setMode() pulses a
      // new value, which rebuilds MaterialApp with a fresh ThemeData so
      // the palette swap is instant and covers every descendant.
      child: ValueListenableBuilder<AppThemeMode>(
        valueListenable: AppTheme.notifier,
        builder: (_, mode, __) => ValueListenableBuilder<VisualPrefs>(
          valueListenable: VisualPrefs.notifier,
          builder: (context, prefs, ___) => MaterialApp(
            title: 'Gungeon Mate',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeFor(mode),
            // Wraps every route's content in a theme-aware overlay so per-
            // theme signature flair (Curseblaster red breath, future others)
            // paints above the scene without each screen needing to opt in.
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(prefs.textScaleFactor),
                ),
                child: ThemeOverlay(child: child ?? const SizedBox.shrink()),
              );
            },
            home: const HomeScreen(),
          ),
        ),
      ),
    );
  }
}
