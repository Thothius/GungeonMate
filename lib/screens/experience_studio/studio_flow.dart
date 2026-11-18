part of '../experience_studio_screen.dart';

// =============================================================================
// PRESET FLOW — pick-or-create entry stages (choose / gallery / source)
// plus the DETAILS summary step and the fullscreen mock preview.
// Stage state lives on _ExperienceStudioScreenState; these are the
// presentational pieces.
// =============================================================================

/// Top-level flow stages. [wizard] is the tabbed editor (the old hub).
enum _StudioStage { choose, gallery, source, wizard }

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

/// Fullscreen mock preview — two swipeable pages: a fake active-run
/// view and a fake gun-detail view, both rendered with the live draft
/// theme (colors, wallpaper, particles, font) via AppTheme/VisualPrefs.
class _MockPreviewScreen extends StatelessWidget {
  const _MockPreviewScreen();

  @override
  Widget build(BuildContext context) {
    final mode = AppTheme.displayedMode;
    final flair = AppTheme.displayedFlair;
    return Scaffold(
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
          if (mode == AppThemeMode.custom &&
              AppTheme.cachedCustomTheme?.wallpaper != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomWallpaper(
                  assetFileName: AppTheme.cachedCustomTheme!.wallpaper!,
                  scrimColor: flair.scaffold,
                  scrimStrength: 0.72,
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
                  child: PageView(
                    children: const [_MockRunPage(), _MockDetailPage()],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: GoopText(
                    'swipe — run view ⇄ gun detail',
                    style: TextStyle(
                      fontSize: 9.5,
                      letterSpacing: 0.8,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mock page 1 — a fake active-run dashboard: player header, gun row,
/// item row, stat chips. Pure mock data, real theme.
class _MockRunPage extends StatelessWidget {
  const _MockRunPage();

  static const _guns = ['Gunderfury', 'Evolver', 'AKEY-47'];
  static const _items = ['Platinum Bullets', 'Iron Coin', 'Spice'];

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.displayedFlair;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _mockCard(
          flair,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: flair.primary.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: flair.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: flair.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoopText(
                          'WANDERER',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: flair.primary,
                          ),
                        ),
                        GoopText(
                          'HP  6.0 / 6.5     ARMOR  2',
                          style: TextStyle(
                            fontSize: 10,
                            color: flair.secondary.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _mockPill('COOP', flair),
                ],
              ),
              const SizedBox(height: 14),
              GoopText(
                'GUNS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final g in _guns)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _mockIconTile(flair, localGunIcon(g), g),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              GoopText(
                'ITEMS',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final i in _items)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _mockIconTile(flair, localItemIcon(i), i),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _mockPill('SYN 3/7', flair),
                  _mockPill('DPS 42.6', flair),
                  _mockPill('FLOOR 2', flair),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mockIconTile(ThemeFlair flair, String path, String name) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: flair.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 34,
            child: Image.asset(
              path,
              fit: BoxFit.contain,
              errorBuilder:
                  (_, _, _) => Icon(
                    Icons.image_outlined,
                    size: 22,
                    color: flair.primary.withValues(alpha: 0.6),
                  ),
            ),
          ),
          const SizedBox(height: 3),
          GoopText(
            name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockPill(String label, ThemeFlair flair) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: flair.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: flair.primary.withValues(alpha: 0.4)),
      ),
      child: GoopText(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          color: flair.primary,
        ),
      ),
    );
  }
}

/// Mock page 2 — a fake gun-detail view: name, stat block, synergy rows.
class _MockDetailPage extends StatelessWidget {
  const _MockDetailPage();

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.displayedFlair;
    Widget stat(String k, String v) => Expanded(
      child: Column(
        children: [
          GoopText(
            v,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: flair.headlineStat,
            ),
          ),
          GoopText(
            k,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _mockCard(
          flair,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 64,
                    width: 64,
                    child: Image.asset(
                      localGunIcon('Gunderfury'),
                      fit: BoxFit.contain,
                      errorBuilder:
                          (_, _, _) => Icon(
                            Icons.gps_fixed_rounded,
                            size: 40,
                            color: flair.primary,
                          ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoopText(
                          'GUNDERFURY',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: flair.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GoopText(
                          'S rank · Evolve gun · Synergy core',
                          style: TextStyle(
                            fontSize: 10,
                            color: flair.secondary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  stat('DMG', '45'),
                  stat('ROF', '4.0'),
                  stat('ACC', '92%'),
                  stat('BLT', '20'),
                ],
              ),
              const SizedBox(height: 14),
              GoopText(
                'SYN',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 8),
              for (final s in const [
                ('BULLET BOY', 'COMPLETE', true),
                ('PINCUSHION', 'PARTIAL', false),
                ('GUNGEON COAT', 'LOCKED', false),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: GoopText(
                          s.$1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              s.$3
                                  ? flair.primary.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                s.$3
                                    ? flair.primary.withValues(alpha: 0.5)
                                    : Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: GoopText(
                          s.$2,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color:
                                s.$3
                                    ? flair.primary
                                    : Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _mockCard(ThemeFlair flair, {required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: flair.card.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: child,
  );
}
