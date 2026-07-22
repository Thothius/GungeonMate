import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/goop_talk_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';

/// Full-screen swipe-to-preview theme picker. Each [PageView] page
/// renders a miniature dashboard styled with that theme's [ThemeFlair]
/// — scaffold + AppBar + card + three stat numbers + a chip row + a
/// bullet list — so the player can taste the colours and quirks
/// before committing. The currently active theme is outlined in the
/// preview's corner; tapping "Use this theme" persists via
/// [AppTheme.setMode] and pops the screen.
class ThemePickerScreen extends StatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  late final PageController _pc;
  late int _index;
  late AppThemeMode _activeMode;

  void controllerRepeatHelper(AnimationController c) => c.repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _activeMode = AppTheme.mode;
    final visibleIdx = kVisibleThemes.indexOf(_activeMode);
    _index = visibleIdx >= 0 ? visibleIdx : 0;
    _pc = PageController(initialPage: _index, viewportFraction: 0.88);

    // Seed the preview notifier with the initial selection
    AppTheme.previewNotifier.value = _activeMode;
  }

  @override
  void dispose() {
    _pc.dispose();
    // Clear the preview notifier so we restore the active app theme
    AppTheme.previewNotifier.value = null;
    super.dispose();
  }

  void _select(AppThemeMode m) {
    AppTheme.previewNotifier.value = null; // Clear preview before applying
    AppTheme.setMode(m);
    setState(() => _activeMode = m);
    Haptics.success(); // Satisfying double-pulse success haptic on apply!
    // If embedded inside a root tab (HomeScreen IndexedStack), canPop is false.
    // In that case, we don't pop, we let the user stay on the selection page.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modes = kVisibleThemes;
    final cleanTextTheme = GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme);
    final cleanTheme = Theme.of(context).copyWith(
      textTheme: cleanTextTheme,
    );

    return Theme(
      data: cleanTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          title: const GoopText('CHOOSE PALETTE'),
          centerTitle: true,
          automaticallyImplyLeading: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Arcade instruction badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                ),
                child: const GoopText(
                  'SELECT YOUR THEME',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                    letterSpacing: 2,
                  ),
                ),
              )
              .animate(onPlay: (c) => controllerRepeatHelper(c))
              .fadeIn(duration: 750.ms)
              .then()
              .fadeOut(duration: 750.ms),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GoopText(
                  'Swipe to preview each palette live. Tap a card to apply.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 520,
                child: PageView.builder(
                  controller: _pc,
                  itemCount: modes.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    AppTheme.previewNotifier.value = modes[i]; // Live dynamic preview fix!
                    Haptics.selection();
                  },
                  itemBuilder: (context, i) {
                    final m = modes[i];
                    final selected = m == _activeMode;
                    final focused = i == _index;
                    return AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: focused ? 1.0 : 0.94,
                      curve: Curves.easeOut,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: _ThemePreviewCard(
                          mode: m,
                          isActive: selected,
                          onApply: () => _select(m),
                          isNew: false,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Page-dot strip
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(modes.length, (i) {
                    final on = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: on ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: on
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders a single theme as a self-contained mini dashboard. Uses the
/// theme's [ThemeFlair] palette directly so it's identical to what the
/// live app will look like — no approximations.
class _ThemePreviewCard extends StatelessWidget {
  final AppThemeMode mode;
  final bool isActive;
  final VoidCallback onApply;
  final bool isNew;
  const _ThemePreviewCard({
    required this.mode,
    required this.isActive,
    required this.onApply,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUnicorn = mode == AppThemeMode.unicorn;
    final hasRemix = kThemeRemixes.containsKey(mode);
    final listenable = isUnicorn
        ? AppTheme.unicornPaletteNotifier
        : hasRemix
            ? AppTheme.remixNotifier
            : null;
    if (listenable != null) {
      return ListenableBuilder(
        listenable: listenable,
        builder: (context, _) => _buildCard(context),
      );
    }
    return _buildCard(context);
  }

  Widget _buildCard(BuildContext context) {
    final f = AppTheme.flairFor(mode);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onApply,
        child: Container(
          decoration: BoxDecoration(
            color: f.scaffold,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? f.primary
                  : Colors.white.withValues(alpha: 0.08),
              width: isActive ? 2.0 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: f.primary.withValues(alpha: 0.25),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mini AppBar — coloured underline establishes the theme's
                      // primary accent immediately.
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      mode.label,
                                      style: TextStyle(
                                        color: f.headlineStat,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    if (isNew) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'NEW',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  mode.tagline,
                                  style: TextStyle(
                                    color: f.secondary.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: f.primary.withValues(alpha: 0.15),
                                border: Border.all(color: f.primary, width: 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: f.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [f.primary, f.secondary],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Arcade Style Theme Attributes Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ArcadeAttribute(label: 'VIBE', value: mode.vibe, color: f.primary),
                          _ArcadeAttribute(label: 'DIFFICULTY', value: mode.diff, color: Colors.amberAccent),
                          _ArcadeAttribute(label: 'ELEMENT', value: mode.elem, color: f.secondary),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Whimsical Description Panel (Adds extreme Gungeon flavor!)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: f.primary.withValues(alpha: 0.1), width: 0.8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.format_quote_rounded, size: 14, color: f.primary.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: GoopText(
                                mode.whimsicalDescription,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Continuous weighted palette swatch bar
                      const Text(
                        'PALETTE CORES',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white54,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _WeightedPaletteBar(flair: f),
                      const SizedBox(height: 10),
                      // Thematic preview stats — custom per theme
                      _PreviewWrapper(mode: mode, child: _PreviewStatsRow(flair: f, mode: mode)),
                      const SizedBox(height: 8),
                      // Thematic bullet notes — custom per theme
                      _PreviewWrapper(mode: mode, child: _PreviewBullets(flair: f, mode: mode)),
                      const SizedBox(height: 8),
                      // Inventory preview row — shows a gun tile and an item tile
                      // with quality ring to give a feel of the actual game UI.
                      _PreviewWrapper(mode: mode, child: _PreviewInventoryRow(flair: f)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Palette / remix switcher chips.
              if (mode == AppThemeMode.unicorn)
                ListenableBuilder(
                  listenable: AppTheme.unicornPaletteNotifier,
                  builder: (context, _) {
                    final active = AppTheme.unicornPalette;
                    return _RemixChips(
                      flair: AppTheme.flairFor(mode),
                      labels: UnicornPalette.values.map((p) => p.label).toList(),
                      activeIndex: active.index,
                      onTap: (i) {
                        AppTheme.setUnicornPalette(UnicornPalette.values[i]);
                        Haptics.selection();
                      },
                    );
                  },
                )
              else if (kThemeRemixes.containsKey(mode))
                ListenableBuilder(
                  listenable: AppTheme.remixNotifier,
                  builder: (context, _) {
                    final remixes = kThemeRemixes[mode]!;
                    final active = AppTheme.remixFor(mode);
                    return _RemixChips(
                      flair: AppTheme.flairFor(mode),
                      labels: remixes.map((r) => r.label).toList(),
                      activeIndex: active,
                      onTap: (i) {
                        AppTheme.setRemix(mode, i);
                        Haptics.selection();
                      },
                    );
                  },
                ),
              if (mode == AppThemeMode.custom)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: const Color(0xFF1E1E22),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                          ),
                          builder: (sheetCtx) => const _CustomThemeEditorSheet(),
                        );
                        // Refresh the card after editing
                        if (context.mounted) {
                          AppTheme.notifier.value = AppTheme.notifier.value;
                        }
                      },
                      icon: Icon(Icons.palette, size: 16, color: f.primary),
                      label: GoopText(
                        'Customize Colors',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: f.primary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: f.primary.withValues(alpha: 0.5), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(f.chipRadius),
                        ),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: f.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(f.chipRadius),
                    ),
                  ),
                  child: GoopText(
                    isActive ? 'Selected' : 'Use this theme',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The picker is itself parented under MaterialApp's *current* theme,
/// not the theme being previewed — so widgets relying on
/// `AppTheme.flair` (e.g. [ThemedNumber]) would render with the active
/// flair, not the previewed one. To make previews accurate we paint a
/// scoped backdrop per theme for the inner widgets.
class _PreviewWrapper extends StatelessWidget {
  final AppThemeMode mode;
  final Widget child;
  const _PreviewWrapper({required this.mode, required this.child});

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flairFor(mode);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(f.cardRadius),
        border: Border.all(
          color: f.dividerColor ?? Colors.transparent,
          width: f.dividerThickness,
        ),
      ),
      child: child,
    );
  }
}

class _PreviewStatsRow extends StatelessWidget {
  final ThemeFlair flair;
  final AppThemeMode mode;
  const _PreviewStatsRow({required this.flair, required this.mode});

  @override
  Widget build(BuildContext context) {
    final data = kThemePreviewData[mode];
    final stats = data?.stats ?? ['142 DPS', '5.0 COOL', '3 CURSE'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        for (final s in stats)
          _PreviewStat(text: s, flair: flair),
      ],
    );
  }
}

class _PreviewStat extends StatelessWidget {
  final String text;
  final ThemeFlair flair;
  const _PreviewStat({
    required this.text,
    required this.flair,
  });

  @override
  Widget build(BuildContext context) {
    final colour = flair.headlineStat;
    final size = 13.0 * flair.numberSizeScale;
    final style = TextStyle(
      fontSize: size,
      fontWeight: flair.numberWeight,
      fontStyle: flair.numberStyle,
      color: colour,
      shadows: flair.embossNumbers
          ? const [
              Shadow(
                offset: Offset(0, 1),
                color: Color(0x99000000),
              ),
              Shadow(
                offset: Offset(0, -0.5),
                color: Color(0x33FFFFFF),
              ),
            ]
          : null,
    );
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  }
}


class _PreviewBullets extends StatelessWidget {
  final ThemeFlair flair;
  final AppThemeMode mode;
  const _PreviewBullets({required this.flair, required this.mode});

  @override
  Widget build(BuildContext context) {
    final data = kThemePreviewData[mode];
    final lines = data?.bulletNotes ?? ['Loadout note', 'Synergy hint', 'Stat tweak'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  flair.bulletGlyph,
                  style: TextStyle(
                    fontSize: 14,
                    color: flair.bulletColor,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lines[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: flair.secondary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Mini inventory row showing a gun tile + item tile with quality ring.
/// Mirrors how the actual inventory renders items so the preview is
/// representative of the in-game look.
class _PreviewInventoryRow extends StatelessWidget {
  final ThemeFlair flair;
  const _PreviewInventoryRow({required this.flair});

  // Quality colors A-D (standard S-A-B-C-D scale for preview).
  static const _ringColors = [
    Color(0xFFE0E0E0), // D
    Color(0xFF4CAF50), // C
    Color(0xFF2196F3), // B
    Color(0xFF9C27B0), // A
    Color(0xFFFFD700), // S (gold)
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Gun tile with gold S-ring
        Expanded(
          child: _previewTile(
            label: 'Marine Sidearm',
            qualityIndex: 4,
            icon: Icons.gps_fixed,
            flair: flair,
          ),
        ),
        const SizedBox(width: 10),
        // Item tile with purple A-ring
        Expanded(
          child: _previewTile(
            label: 'Armor of Thorns',
            qualityIndex: 3,
            icon: Icons.shield_outlined,
            flair: flair,
          ),
        ),
      ],
    );
  }

  Widget _previewTile({
    required String label,
    required int qualityIndex,
    required IconData icon,
    required ThemeFlair flair,
  }) {
    final ring = _ringColors[qualityIndex.clamp(0, 4)];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: flair.scaffold.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(flair.chipRadius - 2),
        border: Border.all(color: flair.dividerColor ?? Colors.transparent),
      ),
      child: Row(
        children: [
          // Quality ring with icon inside
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 2.5),
            ),
            child: Icon(icon, size: 18, color: flair.headlineStat),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: flair.headlineStat,
                  ),
                ),
                const SizedBox(height: 2),
                _qualityPills(flair),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qualityPills(ThemeFlair flair) {
    final pills = ['D', 'C', 'B', 'A', 'S'];
    return Row(
      children: [
        for (var i = 0; i < pills.length; i++)
          Container(
            margin: const EdgeInsets.only(right: 3),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _ringColors[i].withValues(alpha: 0.25),
              border: Border.all(color: _ringColors[i], width: 1),
            ),
            child: Center(
              child: Text(
                pills[i],
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: _ringColors[i],
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ArcadeAttribute extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ArcadeAttribute({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: Colors.white54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightedPaletteBar extends StatelessWidget {
  final ThemeFlair flair;
  const _WeightedPaletteBar({required this.flair});

  @override
  Widget build(BuildContext context) {
    final cores = <_PaletteCore>[
      _PaletteCore(color: flair.scaffold, label: 'BG', weight: 40),
      _PaletteCore(color: flair.card, label: 'CRD', weight: 20),
      _PaletteCore(color: flair.primary, label: 'PRI', weight: 15),
      _PaletteCore(color: flair.secondary, label: 'SEC', weight: 15),
      _PaletteCore(color: flair.headlineStat, label: 'ACC', weight: 10),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            for (final c in cores)
              Expanded(
                flex: c.weight,
                child: Container(
                  color: c.color,
                  alignment: Alignment.center,
                  child: Text(
                    c.label,
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w900,
                      color: c.color.computeLuminance() > 0.5
                          ? Colors.black87
                          : Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 2,
                          offset: const Offset(0.5, 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PaletteCore {
  final Color color;
  final String label;
  final int weight;
  const _PaletteCore({required this.color, required this.label, required this.weight});
}

/// Curated Gungeon color palette for the custom theme editor.
/// 24 deep, saturated colors that work well as scaffold/card/primary/secondary.
const _kCustomColorPalette = <Color>[
  Color(0xFF0D0C0B), Color(0xFF1A1A1A), Color(0xFF1A101F), Color(0xFF0F0A14),
  Color(0xFF0A030C), Color(0xFF080510), Color(0xFF050308), Color(0xFF0A0F0E),
  Color(0xFF0E1018), Color(0xFF120D0A), Color(0xFF0D110E), Color(0xFF0A1118),
  Color(0xFFFF69B4), Color(0xFFFF1493), Color(0xFFE91E63), Color(0xFFFF4500),
  Color(0xFFFFD700), Color(0xFF00E5FF), Color(0xFF00E676), Color(0xFF7C4DFF),
  Color(0xFFB71C1C), Color(0xFF1B5E20), Color(0xFF1A237E), Color(0xFF4A148C),
];

class _CustomThemeEditorSheet extends StatefulWidget {
  const _CustomThemeEditorSheet();

  @override
  State<_CustomThemeEditorSheet> createState() => _CustomThemeEditorSheetState();
}

class _CustomThemeEditorSheetState extends State<_CustomThemeEditorSheet> {
  late CustomThemeData _data;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _data = await CustomThemeData.loadAsync();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    await CustomThemeData.save(_data);
    AppTheme.setCustomThemeData(_data);
    if (mounted) {
      AppTheme.notifier.value = AppTheme.notifier.value;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'CUSTOMIZE THEME',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _data = CustomThemeData.random());
                    Haptics.selection();
                  },
                  icon: const Icon(Icons.casino, size: 16),
                  label: const Text('Randomize', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ColorSlotPicker(
              label: 'Background',
              current: _data.scaffold,
              onPicked: (c) => setState(() => _data = _data.copyWith(scaffold: c)),
            ),
            _ColorSlotPicker(
              label: 'Card',
              current: _data.card,
              onPicked: (c) => setState(() => _data = _data.copyWith(card: c)),
            ),
            _ColorSlotPicker(
              label: 'Primary',
              current: _data.primary,
              onPicked: (c) => setState(() => _data = _data.copyWith(primary: c)),
            ),
            _ColorSlotPicker(
              label: 'Secondary',
              current: _data.secondary,
              onPicked: (c) => setState(() => _data = _data.copyWith(secondary: c)),
            ),
            _ColorSlotPicker(
              label: 'Accent / Headline',
              current: _data.headlineStat,
              onPicked: (c) => setState(() => _data = _data.copyWith(headlineStat: c)),
            ),
            _ColorSlotPicker(
              label: 'Bullet',
              current: _data.bulletColor,
              onPicked: (c) => setState(() => _data = _data.copyWith(bulletColor: c)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton(
                onPressed: _save,
                child: const Text(
                  'Save Theme',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single color slot with a horizontal scrollable row of swatches.
class _ColorSlotPicker extends StatelessWidget {
  final String label;
  final Color current;
  final ValueChanged<Color> onPicked;
  const _ColorSlotPicker({required this.label, required this.current, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: current,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kCustomColorPalette.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = _kCustomColorPalette[i];
                final selected = c.value == current.value;
                return GestureDetector(
                  onTap: () {
                    onPicked(c);
                    Haptics.selection();
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? Colors.white : Colors.white12,
                        width: selected ? 2.0 : 1.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A horizontal wrap of selectable chips for palette switching / remixing.
class _RemixChips extends StatelessWidget {
  final ThemeFlair flair;
  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _RemixChips({
    required this.flair,
    required this.labels,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        children: [
          for (int i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: i == activeIndex
                      ? flair.primary.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: i == activeIndex
                        ? flair.primary
                        : Colors.white.withValues(alpha: 0.1),
                    width: i == activeIndex ? 1.5 : 1.0,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: i == activeIndex ? FontWeight.w800 : FontWeight.w600,
                    color: i == activeIndex
                        ? flair.primary
                        : Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
