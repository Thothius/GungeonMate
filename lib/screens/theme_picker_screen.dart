import 'package:flutter/material.dart';
import '../services/goop_talk_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';

/// Full-screen immersive theme picker. Each page fills the entire screen
/// with the theme's scaffold colour, showcasing a large palette and a
/// short flavour description. Swipe to preview, tap to apply.
class ThemePickerScreen extends StatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  late final PageController _pc;
  late int _index;
  late AppThemeMode _activeMode;

  @override
  void initState() {
    super.initState();
    _activeMode = AppTheme.mode;
    final visibleIdx = kVisibleThemes.indexOf(_activeMode);
    _index = visibleIdx >= 0 ? visibleIdx : 0;
    _pc = PageController(initialPage: _index, viewportFraction: 1.0);
    AppTheme.previewNotifier.value = _activeMode;
  }

  @override
  void dispose() {
    _pc.dispose();
    AppTheme.previewNotifier.value = null;
    super.dispose();
  }

  void _select(AppThemeMode m) {
    AppTheme.previewNotifier.value = null;
    AppTheme.setMode(m);
    setState(() => _activeMode = m);
    Haptics.success();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modes = kVisibleThemes;
    final cleanTextTheme =
        GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme);
    final cleanTheme = Theme.of(context).copyWith(textTheme: cleanTextTheme);

    return Theme(
      data: cleanTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Minimal top bar — back + title
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4, right: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20, color: Colors.white70),
                    ),
                    const Spacer(),
                    GoopText(
                      'PALETTE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              // Full-screen swipe area
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: modes.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    AppTheme.previewNotifier.value = modes[i];
                    Haptics.selection();
                  },
                  itemBuilder: (context, i) {
                    final m = modes[i];
                    return _ImmersiveThemePage(
                      mode: m,
                      isActive: m == _activeMode,
                      onApply: () => _select(m),
                    );
                  },
                ),
              ),
              // Page indicator dots
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(modes.length, (i) {
                    final on = i == _index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: on ? 24 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: on
                            ? AppTheme.flairFor(modes[i]).primary
                                .withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single full-screen theme page. The background is the theme's
/// scaffold colour, so the user immediately feels the palette.
class _ImmersiveThemePage extends StatelessWidget {
  final AppThemeMode mode;
  final bool isActive;
  final VoidCallback onApply;
  const _ImmersiveThemePage({
    required this.mode,
    required this.isActive,
    required this.onApply,
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
        builder: (context, _) => _buildPage(context),
      );
    }
    return _buildPage(context);
  }

  Widget _buildPage(BuildContext context) {
    final f = AppTheme.flairFor(mode);
    final cores = <_PaletteCore>[
      _PaletteCore(color: f.scaffold, label: 'BACKGROUND', weight: 34),
      _PaletteCore(color: f.card, label: 'CARD', weight: 22),
      _PaletteCore(color: f.primary, label: 'PRIMARY', weight: 18),
      _PaletteCore(color: f.secondary, label: 'SECONDARY', weight: 14),
      _PaletteCore(color: f.headlineStat, label: 'ACCENT', weight: 12),
    ];

    return Container(
      color: f.scaffold,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 2),

            // Theme name — large, bold, in the theme's headline colour
            Text(
              mode.label.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: f.headlineStat,
                letterSpacing: 4,
                height: 1.1,
                shadows: f.numberGlowColor != null
                    ? [
                        Shadow(
                          color: f.numberGlowColor!,
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideY(begin: 0.08, end: 0, duration: 400.ms),

            const SizedBox(height: 6),

            // Tagline — small, muted
            Text(
              mode.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: f.secondary.withValues(alpha: 0.7),
                letterSpacing: 1.2,
              ),
            ),

            const Spacer(flex: 1),

            // Large palette bar — the hero element
            // Weighted horizontal bars showing each colour's proportion
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 80,
                child: Row(
                  children: [
                    for (final c in cores)
                      Expanded(
                        flex: c.weight,
                        child: Container(
                          color: c.color,
                        ),
                      ),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: 200.ms)
            .slideY(begin: 0.12, end: 0, duration: 500.ms),

            const SizedBox(height: 10),

            // Colour labels under the bar
            Row(
              children: [
                for (final c in cores)
                  Expanded(
                    flex: c.weight,
                    child: Text(
                      c.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.35),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),

            // Big colour dots row — shows each colour as a large circle
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ColorDot(color: f.scaffold, size: 44),
                _ColorDot(color: f.card, size: 44),
                _ColorDot(color: f.primary, size: 56),
                _ColorDot(color: f.secondary, size: 44),
                _ColorDot(color: f.headlineStat, size: 44),
              ],
            )
            .animate()
            .fadeIn(duration: 500.ms, delay: 350.ms)
            .slideY(begin: 0.15, end: 0, duration: 500.ms),

            const Spacer(flex: 2),

            // Flavour description — 1-2 sentences, italic, centered
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GoopText(
                mode.whimsicalDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.65),
                  letterSpacing: 0.3,
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 450.ms),

            const Spacer(flex: 2),

            // Remix / palette chips (if applicable)
            if (mode == AppThemeMode.unicorn)
              ListenableBuilder(
                listenable: AppTheme.unicornPaletteNotifier,
                builder: (context, _) {
                  final active = AppTheme.unicornPalette;
                  return _RemixChips(
                    flair: f,
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
                    flair: f,
                    labels: remixes.map((r) => r.label).toList(),
                    activeIndex: active,
                    onTap: (i) {
                      AppTheme.setRemix(mode, i);
                      Haptics.selection();
                    },
                  );
                },
              ),

            // Custom theme editor button
            if (mode == AppThemeMode.custom)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: const Color(0xFF1E1E22),
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      builder: (sheetCtx) => const _CustomThemeEditorSheet(),
                    );
                    if (context.mounted) AppTheme.refresh();
                  },
                  icon: Icon(Icons.tune_rounded, size: 18, color: f.primary),
                  label: Text(
                    'Customize Colors',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: f.primary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: f.primary.withValues(alpha: 0.5), width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(f.chipRadius),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),

            // Apply button — the single call to action
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    backgroundColor: f.primary,
                    foregroundColor:
                        f.primary.computeLuminance() > 0.5
                            ? Colors.black87
                            : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: GoopText(
                    isActive ? '✓ Active' : 'Use This Palette',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 400.ms, delay: 600.ms)
            .slideY(begin: 0.1, end: 0, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

/// A large colour dot with a subtle border, used in the palette row.
class _ColorDot extends StatelessWidget {
  final Color color;
  final double size;
  const _ColorDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
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
      AppTheme.refresh();
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
                final selected = c.toARGB32() == current.toARGB32();
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          for (int i = 0; i < labels.length; i++)
            GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: i == activeIndex
                      ? flair.primary.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: i == activeIndex
                        ? flair.primary
                        : Colors.white.withValues(alpha: 0.1),
                    width: i == activeIndex ? 2.0 : 1.0,
                  ),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: i == activeIndex ? FontWeight.w900 : FontWeight.w700,
                    color: i == activeIndex
                        ? flair.primary
                        : Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
