import 'package:flutter/material.dart';
import '../services/goop_talk_engine.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import '../utils/asset_paths.dart';

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

    return Container(
      color: f.scaffold,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 1),

            // Theme name — large, bold, in the theme's headline colour
            GoopText(
              mode.label.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
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

            const SizedBox(height: 4),

            // Tagline — small, muted
            GoopText(
              mode.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: f.secondary.withValues(alpha: 0.7),
                letterSpacing: 1.2,
              ),
            ),

            const Spacer(flex: 1),

            // ═══════════════════════════════════════════
            // DASHBOARD PREVIEW — mini GungeoneerHeader mockup
            // ═══════════════════════════════════════════
            _DashboardPreview(f: f)
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .slideY(begin: 0.1, end: 0, duration: 500.ms),

            const Spacer(flex: 1),

            // Flavour description — 1-2 sentences, italic, centered
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GoopText(
                mode.whimsicalDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.55),
                  letterSpacing: 0.3,
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: 400.ms),

            const Spacer(flex: 1),

            // ═══════════════════════════════════════════
            // PALETTE / REMIX SELECTOR — big tappable cards
            // ═══════════════════════════════════════════
            if (mode == AppThemeMode.unicorn)
              ListenableBuilder(
                listenable: AppTheme.unicornPaletteNotifier,
                builder: (context, _) {
                  final active = AppTheme.unicornPalette;
                  return _PaletteSelector(
                    flair: f,
                    items: UnicornPalette.values.map((p) {
                      final pf = p.flair;
                      return (
                        label: p.label,
                        colors: [pf.scaffold, pf.primary, pf.headlineStat],
                      );
                    }).toList(),
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
                  return _PaletteSelector(
                    flair: f,
                    items: remixes.map((r) {
                      final rf = r.flair;
                      return (
                        label: r.label,
                        colors: rf != null
                            ? [rf.scaffold, rf.primary, rf.headlineStat]
                            : [f.scaffold, f.primary, f.headlineStat],
                      );
                    }).toList(),
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
                padding: const EdgeInsets.only(bottom: 8),
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
                  label: GoopText(
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

/// Simple HSV color picker dialog — hue/saturation/lightness sliders.
class _HsvColorPickerDialog extends StatefulWidget {
  final Color initial;
  const _HsvColorPickerDialog({required this.initial});

  @override
  State<_HsvColorPickerDialog> createState() => _HsvColorPickerDialogState();
}

class _HsvColorPickerDialogState extends State<_HsvColorPickerDialog> {
  late double _hue;
  late double _saturation;
  late double _value;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initial);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
  }

  Color get _color => HSVColor.fromAHSV(1.0, _hue, _saturation, _value).toColor();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E22),
      title: const Text('Pick Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color preview
          Container(
            width: double.infinity,
            height: 48,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
          ),
          // Hue slider
          _HueSlider(
            value: _hue,
            onChanged: (v) => setState(() => _hue = v),
          ),
          const SizedBox(height: 12),
          // Saturation slider
          _SatSlider(
            hue: _hue,
            value: _saturation,
            onChanged: (v) => setState(() => _saturation = v),
          ),
          const SizedBox(height: 12),
          // Value slider
          _ValSlider(
            hue: _hue,
            saturation: _saturation,
            value: _value,
            onChanged: (v) => setState(() => _value = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _HueSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const _HueSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
        Slider(
          value: value,
          min: 0,
          max: 360,
          activeColor: HSVColor.fromAHSV(1.0, value, 1.0, 1.0).toColor(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SatSlider extends StatelessWidget {
  final double hue;
  final double value;
  final ValueChanged<double> onChanged;
  const _SatSlider({required this.hue, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Saturation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
        Slider(
          value: value,
          activeColor: HSVColor.fromAHSV(1.0, hue, value, 1.0).toColor(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ValSlider extends StatelessWidget {
  final double hue;
  final double saturation;
  final double value;
  final ValueChanged<double> onChanged;
  const _ValSlider({required this.hue, required this.saturation, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lightness', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70)),
        Slider(
          value: value,
          activeColor: HSVColor.fromAHSV(1.0, hue, saturation, value).toColor(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Font picker for the custom theme editor.
class _FontSlotPicker extends StatelessWidget {
  final AppFont current;
  final ValueChanged<AppFont> onPicked;
  const _FontSlotPicker({required this.current, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FONT TYPE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.4),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: AppFont.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final font = AppFont.values[i];
                final selected = font == current;
                return GestureDetector(
                  onTap: () {
                    onPicked(font);
                    Haptics.selection();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? Colors.white70 : Colors.white12,
                        width: selected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        font.label,
                        style: font.textStyle.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : Colors.white54,
                        ),
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
                const GoopText(
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
                  label: const GoopText('Randomize', style: TextStyle(fontSize: 12)),
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

            // Font type picker
            _FontSlotPicker(
              current: _data.font,
              onPicked: (f) => setState(() => _data = _data.copyWith(font: f)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton(
                onPressed: _save,
                child: const GoopText(
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
              GoopText(
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
              itemCount: _kCustomColorPalette.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                // Last item: custom color picker button
                if (i == _kCustomColorPalette.length) {
                  return GestureDetector(
                    onTap: () async {
                      final picked = await showDialog<Color>(
                        context: context,
                        builder: (_) => _HsvColorPickerDialog(initial: current),
                      );
                      if (picked != null) {
                        onPicked(picked);
                        Haptics.selection();
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white30,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(Icons.add, size: 18, color: Colors.white70),
                    ),
                  );
                }
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

// ═══════════════════════════════════════════════════════════════
// _DashboardPreview — Mini GungeoneerHeader mockup that shows how
// the theme looks on the actual active run screen.
// ═══════════════════════════════════════════════════════════════
class _DashboardPreview extends StatelessWidget {
  final ThemeFlair f;
  const _DashboardPreview({required this.f});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(f.cardRadius),
        border: Border.all(
          color: f.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: f.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Portrait + Name + trailing dots
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                // Portrait
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: f.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: f.primary.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      localGungeoneerIcon('The Marine'),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 22,
                        color: f.primary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name
                Expanded(
                  child: GoopText(
                    'THE MARINE',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                      height: 1.1,
                    ),
                  ),
                ),
                // Trailing menu icon
                Icon(Icons.more_vert_rounded, size: 18, color: f.primary.withValues(alpha: 0.5)),
              ],
            ),
          ),
          // Row 2: Stat capsules
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Row(
              children: [
                _previewCapsule(f, const Color(0xFF00E5FF), '+3.0', 'COOL', true),
                const SizedBox(width: 4),
                _previewCapsule(f, const Color(0xFFE040FB), '+1.5', 'CURSE', true),
                const SizedBox(width: 4),
                _previewCapsule(f, const Color(0xFFFFD740), '4', 'SYN', true),
                const SizedBox(width: 4),
                _previewCapsule(f, const Color(0xFFFF9100), '52', 'DPS', true),
              ],
            ),
          ),
          // Divider
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.05),
          ),
          // Row 3: Mini inventory rows
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _previewInventoryRow(f, 'Marine Sidearm', 'A', const Color(0xFF00E5FF)),
                const SizedBox(height: 4),
                _previewInventoryRow(f, 'Supply Drop', 'B', const Color(0xFF00E676)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewCapsule(
    ThemeFlair f,
    Color color,
    String value,
    String label,
    bool isActive,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(f.chipRadius),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.10),
            width: 1.0,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            children: [
              GoopText(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isActive ? Colors.white : Colors.white38,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              GoopText(
                label,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: isActive ? color : Colors.white24,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewInventoryRow(
    ThemeFlair f,
    String name,
    String quality,
    Color qualityColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: f.primary.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Quality badge dot
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: qualityColor.withValues(alpha: 0.18),
              border: Border.all(color: qualityColor.withValues(alpha: 0.55), width: 1.2),
            ),
            child: Center(
              child: GoopText(
                quality,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: qualityColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Icon placeholder
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: f.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.inventory_2_outlined, size: 12, color: f.primary.withValues(alpha: 0.4)),
          ),
          const SizedBox(width: 8),
          // Name
          Expanded(
            child: GoopText(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          // DPS / stat number
          Text(
            '14.2',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: f.headlineStat,
              shadows: f.numberGlowColor != null
                  ? [Shadow(color: f.numberGlowColor!, blurRadius: 6)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// _PaletteSelector — Big tappable palette cards with color swatches.
// Replaces the old small _RemixChips with something much more
// tactile and visual.
// ═══════════════════════════════════════════════════════════════
class _PaletteSelector extends StatelessWidget {
  final ThemeFlair flair;
  final List<({String label, List<Color> colors})> items;
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _PaletteSelector({
    required this.flair,
    required this.items,
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final item = items[i];
            final isActive = i == activeIndex;
            return GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? flair.primary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isActive
                        ? flair.primary
                        : Colors.white.withValues(alpha: 0.08),
                    width: isActive ? 2.0 : 1.0,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: flair.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Color swatch stack
                    Row(
                      children: [
                        for (int c = 0; c < item.colors.length; c++) ...[
                          if (c > 0) const SizedBox(width: 3),
                          Container(
                            width: 16,
                            height: 32,
                            decoration: BoxDecoration(
                              color: item.colors[c],
                              borderRadius: BorderRadius.horizontal(
                                left: c == 0 ? const Radius.circular(4) : Radius.zero,
                                right: c == item.colors.length - 1
                                    ? const Radius.circular(4)
                                    : Radius.zero,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 10),
                    // Label
                    GoopText(
                      item.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                        color: isActive
                            ? flair.primary
                            : Colors.white.withValues(alpha: 0.65),
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded, size: 14, color: flair.primary),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
