part of '../experience_studio_screen.dart';

// =============================================================================
// PRESET FLOW — pick-or-create entry stages (choose / gallery / source)
// plus the DETAILS summary step and the fullscreen mock preview.
// Stage state lives on _ExperienceStudioScreenState; these are the
// presentational pieces.
// =============================================================================

/// Top-level flow stages. [wizard] is the preset dashboard landing;
/// [editor] is the tabbed option editor (the old hub) opened from it.
enum _StudioStage { choose, gallery, source, wizard, editor }

/// One card in the preset gallery — a premade [AppThemeMode] or a
/// user-saved [SavedCustomTheme].
class _PresetEntry {
  const _PresetEntry({
    required this.name,
    required this.subtitle,
    required this.colors,
    this.mode,
    this.saved,
    this.splash,
  });

  final String name;
  final String subtitle;
  final List<Color> colors;
  final AppThemeMode? mode;
  final SavedCustomTheme? saved;
  final String? splash;
}

/// Big tappable entry card used by the CHOOSE and SOURCE stages.
class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.4),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GoopText(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GoopText(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen preview — a living demo session, not static page mocks.
/// Hosts the REAL [ActiveRunScreen] on an isolated mock [RunProvider]
/// seeded with a random gungeoneer + loot every open (and on RE-ROLL).
/// Everything is tappable: inventory tiles push real detail screens,
/// the FAB opens the real quick-add sheet, the run-tools menu works,
/// dice roll animates — all against the mock run, never the real one.
/// BACK pops one level at a time (system back, in-app back buttons, or
/// the dock's RUN tab) before closing the preview. The BROWSE dock tab
/// pushes the real [BrowseScreen]. All rendered with the live draft
/// theme via AppTheme/VisualPrefs.
class _MockPreviewScreen extends StatefulWidget {
  const _MockPreviewScreen();

  @override
  State<_MockPreviewScreen> createState() => _MockPreviewScreenState();
}

class _MockPreviewScreenState extends State<_MockPreviewScreen> {
  late RunProvider _previewProvider;
  final math.Random _rng = math.Random();
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  bool _loaded = false;
  bool _hasProvider = false;
  int _sessionToken = 0;
  // Last provider disposed via the deferred reroll path — guards
  // against double-dispose when a reroll is interrupted mid-load.
  RunProvider? _disposedProvider;

  void _disposeProvider(RunProvider p) {
    if (identical(p, _disposedProvider)) return;
    _disposedProvider = p;
    p.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  List<T> _sample<T>(List<T> src, int n) {
    if (src.length <= n) return List.of(src);
    final copy = List.of(src)..shuffle(_rng);
    return copy.take(n).toList();
  }

  Future<void> _startSession() async {
    final token = ++_sessionToken;
    final provider = RunProvider()..persistenceEnabled = false;
    await provider.loadData();
    if (!mounted || token != _sessionToken) {
      provider.dispose();
      return;
    }
    final chars = provider.allGungeoneers;
    if (chars.isNotEmpty) {
      // Random gungeoneer each session — different starter loadout too.
      provider.startNewRun(chars[_rng.nextInt(chars.length)]);
      // Pad the run with a random spread of gear so the active-run
      // view reads as mid-run loot, not a bare starter inventory.
      for (final g in _sample(provider.allGuns, 6)) {
        provider.addGun(g);
      }
      for (final i in _sample(provider.allItems, 6)) {
        provider.addItem(i);
      }
    }
    _previewProvider = provider;
    _hasProvider = true;
    setState(() => _loaded = true);
  }

  /// Re-roll the demo run — new character + loot, nav back to RUN.
  void _reroll() {
    if (!_hasProvider) return;
    Haptics.selection();
    _navKey.currentState?.popUntil((r) => r.isFirst);
    final old = _previewProvider;
    setState(() => _loaded = false);
    // Old routes unmount this frame; dispose once they've let go.
    if (!identical(old, _disposedProvider)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _disposeProvider(old));
    }
    _startSession();
  }

  void _openBrowse() {
    _navKey.currentState?.push(
      fastRoute(const BrowseScreen(showBackButton: true)),
    );
  }

  @override
  void dispose() {
    if (_hasProvider) _disposeProvider(_previewProvider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = AppTheme.displayedMode;
    final flair = AppTheme.displayedFlair;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = _navKey.currentState;
        if (nav != null && await nav.maybePop()) return;
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    flair.scaffold,
                    flair.scaffold.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
          ..._customBgLayers(mode, 0.72),
          // Ambient shader — FOG/RAIN picks render here too
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<VisualPrefs>(
                valueListenable: VisualPrefs.notifier,
                builder: (_, prefs, _) {
                  if (!prefs.shaderEnabled) {
                    return const SizedBox.shrink();
                  }
                  return AmbientShaderLayer(
                    shader:
                        prefs.shaderPreset == ShaderPreset.darkNeonFog
                            ? AmbientShader.darkNeonFog
                            : AmbientShader.digitalRain,
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<VisualPrefs>(
                valueListenable: VisualPrefs.notifier,
                builder:
                    (_, prefs, _) =>
                        buildBackdropParticleField(mode, prefs) ??
                        const SizedBox.shrink(),
              ),
            ),
          ),
          // Ambient glow
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<VisualPrefs>(
                valueListenable: VisualPrefs.notifier,
                builder: (_, prefs, _) {
                  final f = AppTheme.flairFor(mode);
                  final auto = f.glowPrimary.a > 0.01 ? 0.15 : 0.0;
                  final user =
                      prefs.glowIntensity > 0.001
                          ? prefs.glowIntensity
                          : auto;
                  final eff = (user * 1.8).clamp(0.0, 1.8);
                  if (eff <= 0.001) return const SizedBox.shrink();
                  Color scaled(Color c) =>
                      c.withValues(alpha: (c.a * eff).clamp(0.0, 1.0));
                  return AmbientGlow(
                    primary: scaled(
                      Color.lerp(f.glowPrimary, prefs.glowColor, 0.5) ??
                          f.glowPrimary,
                    ),
                    secondary: scaled(
                      Color.lerp(f.glowSecondary, prefs.glowColor, 0.5) ??
                          f.glowSecondary,
                    ),
                    tertiary: f.headlineStat.withValues(alpha: 0.3),
                    style: prefs.glowStyleOverride ?? f.glowStyle,
                  );
                },
              ),
            ),
          ),
          // Vignette + film grain
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<VisualPrefs>(
                valueListenable: VisualPrefs.notifier,
                builder:
                    (_, prefs, _) => Stack(
                      children: [
                        if (prefs.vignetteIntensity > 0.01)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  radius: 1.25,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(
                                      alpha:
                                          0.05 * prefs.vignetteIntensity,
                                    ),
                                    Colors.black.withValues(
                                      alpha:
                                          0.25 * prefs.vignetteIntensity,
                                    ),
                                    Colors.black.withValues(
                                      alpha:
                                          0.48 * prefs.vignetteIntensity,
                                    ),
                                  ],
                                  stops: const [0.0, 0.45, 0.82, 1.0],
                                ),
                              ),
                            ),
                          ),
                        if (prefs.grainIntensity > 0.005)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GrainPainter(
                                opacity: prefs.grainIntensity * 0.35,
                              ),
                            ),
                          ),
                      ],
                    ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      GoopText(
                        'LIVE PREVIEW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.6,
                          color: flair.primary.withValues(alpha: 0.7),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _reroll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            Icons.casino_rounded,
                            size: 15,
                            color: flair.primary.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Haptics.selection();
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const GoopText(
                            'CLOSE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child:
                      _loaded
                          ? ChangeNotifierProvider<RunProvider>.value(
                            value: _previewProvider,
                            child: Navigator(
                              key: _navKey,
                              onGenerateRoute:
                                  (_) => fastRoute(
                                    ActiveRunScreen(
                                      onRequestBrowse: _openBrowse,
                                    ),
                                  ),
                            ),
                          )
                          : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: flair.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GoopText(
                                  'LOADING PREVIEW...',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
                _PreviewDock(navKey: _navKey, onBrowse: _openBrowse),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Slim bottom dock mirroring the app's tab bar — top-level
/// look-around for the demo session. RUN pops back to the active-run
/// home; BROWSE pushes the real browse screen (its own back button
/// returns to the run).
class _PreviewDock extends StatelessWidget {
  const _PreviewDock({required this.navKey, required this.onBrowse});
  final GlobalKey<NavigatorState> navKey;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.displayedFlair;
    Widget tab(String label, IconData icon, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Haptics.selection();
            onTap();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: flair.primary.withValues(alpha: 0.9)),
                const SizedBox(width: 6),
                GoopText(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          tab('RUN', Icons.directions_run_rounded, () {
            navKey.currentState?.popUntil((r) => r.isFirst);
          }),
          const SizedBox(width: 10),
          tab('BROWSE', Icons.inventory_2_outlined, onBrowse),
        ],
      ),
    );
  }
}
