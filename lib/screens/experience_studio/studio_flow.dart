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

/// Fullscreen preview — 4 swipeable pages using real app widgets with
/// a mock RunProvider. Pages: active run, browse, item detail, quick-add.
/// All rendered with the live draft theme via AppTheme/VisualPrefs.
class _MockPreviewScreen extends StatefulWidget {
  const _MockPreviewScreen();

  @override
  State<_MockPreviewScreen> createState() => _MockPreviewScreenState();
}

class _MockPreviewScreenState extends State<_MockPreviewScreen> {
  late final RunProvider _previewProvider;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _previewProvider = RunProvider();
    _loadPreviewData();
  }

  Future<void> _loadPreviewData() async {
    await _previewProvider.loadData();
    if (!mounted) return;
    // Start a fake run with sample data for realistic previews
    final chars = _previewProvider.allGungeoneers;
    if (chars.isNotEmpty) {
      _previewProvider.startNewRun(chars.first);
      // Add some sample guns and items for a populated look
      final guns = _previewProvider.allGuns;
      final items = _previewProvider.allItems;
      // Add a few iconic guns
      for (final name in ['Gunderfury', 'Evolver', 'AKEY-47']) {
        final gun = guns.where((g) => g.name == name).firstOrNull;
        if (gun != null) _previewProvider.addGun(gun);
      }
      // Add a few items
      for (final name in ['Platinum Bullets', 'Iron Coin', 'Spice']) {
        final item = items.where((i) => i.name == name).firstOrNull;
        if (item != null) _previewProvider.addItem(item);
      }
    }
    setState(() => _loaded = true);
  }

  @override
  void dispose() {
    _previewProvider.dispose();
    super.dispose();
  }

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
                            child: PageView(
                              children: [
                                _PreviewActiveRunPage(),
                                _PreviewBrowsePage(),
                                _PreviewItemDetailPage(),
                                _PreviewQuickAddPage(),
                              ],
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: GoopText(
                    'swipe — run · browse · detail · quick-add',
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

/// Page 1 — Active run simulation using real PlayerPage widget.
class _PreviewActiveRunPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const PlayerPage(slot: PlayerSlot.main);
  }
}

/// Page 2 — Browse view using real BrowseScreen widget.
class _PreviewBrowsePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const BrowseScreen(
      targetSlot: PlayerSlot.main,
      isVisible: true,
      showBackButton: false,
    );
  }
}

/// Page 3 — Item detail view using real ItemDetailScreen widget.
class _PreviewItemDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RunProvider>();
    // Pick a random gun or item for the detail preview
    final guns = provider.allGuns;
    final items = provider.allItems;
    Gun? gun;
    Item? item;
    if (guns.isNotEmpty) {
      // Prefer a gun with synergies for a richer preview
      gun = guns.firstWhere(
        (g) => g.name == 'Gunderfury',
        orElse: () => guns.first,
      );
    } else if (items.isNotEmpty) {
      item = items.first;
    }
    if (gun == null && item == null) {
      return const Center(child: GoopText('No data loaded'));
    }
    return ItemDetailScreen(
      gun: gun,
      item: item,
      ownerSlot: PlayerSlot.main,
      lebView: false,
    );
  }
}

/// Page 4 — Quick-add menu preview. Shows a simplified version of the
/// quick-add bottom sheet UI for theme preview purposes.
class _PreviewQuickAddPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RunProvider>();
    final flair = AppTheme.displayedFlair;
    final guns = provider.allGuns.take(8).toList();
    final items = provider.allItems.take(8).toList();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: flair.card.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: flair.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GoopText(
                  'QUICK ADD',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: flair.primary,
                  ),
                ),
              ),
              Icon(
                Icons.close_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
        // Search bar mock
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              GoopText(
                'Search guns & items...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        // Sample list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              for (final gun in guns)
                _PreviewQuickAddRow(
                  name: gun.name,
                  quality: gun.quality,
                  isGun: true,
                  iconPath: gun.icon,
                ),
              for (final item in items)
                _PreviewQuickAddRow(
                  name: item.name,
                  quality: item.quality,
                  isGun: false,
                  iconPath: item.icon,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewQuickAddRow extends StatelessWidget {
  final String name;
  final String quality;
  final bool isGun;
  final String iconPath;

  const _PreviewQuickAddRow({
    required this.name,
    required this.quality,
    required this.isGun,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.displayedFlair;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: flair.card.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: iconPath.isNotEmpty
                ? Image.asset(
                    iconPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      isGun ? Icons.gps_fixed : Icons.inventory_2,
                      size: 20,
                      color: flair.primary,
                    ),
                  )
                : Icon(
                    isGun ? Icons.gps_fixed : Icons.inventory_2,
                    size: 20,
                    color: flair.primary,
                  ),
          ),
          const SizedBox(width: 12),
          // Name + type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                GoopText(
                  isGun ? 'GUN' : 'ITEM',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Quality badge
          if (quality.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _qualityColor(quality).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _qualityColor(quality).withValues(alpha: 0.4),
                ),
              ),
              child: GoopText(
                quality,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: _qualityColor(quality),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _qualityColor(String q) {
    switch (q.toUpperCase()) {
      case 'S':
        return const Color(0xFFFFD700);
      case 'A':
        return Colors.redAccent;
      case 'B':
        return Colors.greenAccent;
      case 'C':
        return Colors.blueAccent;
      case 'D':
        return Colors.brown;
      default:
        return Colors.white38;
    }
  }
}
