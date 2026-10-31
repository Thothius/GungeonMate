import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../theme/tokens.dart';
import '../utils/responsive.dart';
import '../widgets/scale_button.dart';

/// PALETTE MAKER — build a custom palette from 6 prime colors.
/// Top half: live preview painted with the working palette.
/// Bottom half: curated PRIME + SUPPORTING color slots, name, save.
/// Saved palettes land in CustomThemeStore and appear in the studio.
class PaletteMakerScreen extends StatefulWidget {
  const PaletteMakerScreen({super.key});

  @override
  State<PaletteMakerScreen> createState() => _PaletteMakerScreenState();
}

class _PaletteMakerScreenState extends State<PaletteMakerScreen> {
  late CustomThemeData _data = CustomThemeData.defaultTheme;
  final _nameCtrl = TextEditingController();
  String? _error;

  String _splashSlug = 'custom';
  static const _splashes = [
    'custom',
    'unicorn',
    'forge_master',
    'moonlit_chamber',
    'the_paradox',
    'the_bullet',
    'cat_lady',
    'robots_core',
    'mr_robot',
    'storm_caller',
    'valor_of_marines',
    'gunpowder',
    'dragunfire',
    'lichs_domain',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Working flair derived from the prime colors — supporting
  /// chrome (borders, dividers, glow) is generated from the primes.
  ThemeFlair get _flair => ThemeFlair(
    scaffold: _data.scaffold,
    card: _data.card,
    primary: _data.primary,
    secondary: _data.secondary,
    headlineStat: _data.headlineStat,
    bulletColor: _data.bulletColor,
    bulletGlyph: '\u25AA',
    tabularFigures: true,
    numberSizeScale: 1.0,
    numberWeight: FontWeight.w700,
    chipRadius: 8,
    cardRadius: 10,
    cardBorderColor: _data.primary.withValues(alpha: 0.25),
    cardBorderWidth: 1.0,
    dividerColor: _data.primary.withValues(alpha: 0.2),
    dividerThickness: 1.0,
    glowPrimary: _data.primary.withValues(alpha: 0.3),
    glowSecondary: _data.secondary.withValues(alpha: 0.2),
    auraStyle: _data.auraStyle,
    headerGlyph: '\u25AA',
    headerUnderlineColor: _data.primary.withValues(alpha: 0.5),
    statGroupCombat: _data.primary,
    statGroupHandling: _data.secondary,
    statGroupMeta: _data.headlineStat,
    font: _data.font,
  );

  static const _swatches = <int>[
    0xFF0D0A14,
    0xFF16161A,
    0xFF1A1226,
    0xFF241620,
    0xFF120B08,
    0xFF0F0C0A,
    0xFFECEFF1,
    0xFFFFFFFF,
    0xFF9E9E9E,
    0xFFB0BEC5,
    0xFF90A4AE,
    0xFF78909C,
    0xFFFF6B81,
    0xFFF8BBD0,
    0xFFE040FB,
    0xFFB388FF,
    0xFF7C4DFF,
    0xFF651FFF,
    0xFFFF4500,
    0xFFD84315,
    0xFFFF6E40,
    0xFFFF8A65,
    0xFFFFB74D,
    0xFFFFD740,
    0xFF00E5FF,
    0xFF4DD0E1,
    0xFF26C6DA,
    0xFF66BB6A,
    0xFF76FF03,
    0xFFFFD54F,
  ];

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final f = _flair;
    return Scaffold(
      backgroundColor: f.scaffold,
      appBar: AppBar(
        backgroundColor: f.scaffold,
        title: GoopText(
          'PALETTE MAKER',
          style: TextStyle(
            fontSize: FontSizes.titleSmall * sf,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: f.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Live preview — ~half the screen ──
          Expanded(flex: 4, child: _PreviewPane(flair: f, sf: sf)),
          // ── Slots + name + save — bottom half ──
          Expanded(
            flex: 6,
            child: SafeArea(
              top: false,
              child: ListView(
                padding: EdgeInsets.fromLTRB(16 * sf, 0, 16 * sf, 16 * sf),
                children: [
                  _sectionLabel('PRIME COLORS', f, sf),
                  _slot(
                    'Canvas',
                    _data.scaffold,
                    (c) => setState(() => _data = _data.copyWith(scaffold: c)),
                    f,
                    sf,
                  ),
                  _slot(
                    'Panels',
                    _data.card,
                    (c) => setState(() => _data = _data.copyWith(card: c)),
                    f,
                    sf,
                  ),
                  _slot(
                    'Accent',
                    _data.primary,
                    (c) => setState(() => _data = _data.copyWith(primary: c)),
                    f,
                    sf,
                  ),
                  _slot(
                    'Highlight',
                    _data.secondary,
                    (c) => setState(() => _data = _data.copyWith(secondary: c)),
                    f,
                    sf,
                  ),
                  _slot(
                    'Numbers',
                    _data.headlineStat,
                    (c) =>
                        setState(() => _data = _data.copyWith(headlineStat: c)),
                    f,
                    sf,
                  ),
                  _slot(
                    'Bullets',
                    _data.bulletColor,
                    (c) =>
                        setState(() => _data = _data.copyWith(bulletColor: c)),
                    f,
                    sf,
                  ),
                  const SizedBox(height: 12),
                  _sectionLabel('SUPPORTING', f, sf),
                  GoopText(
                    'Borders, dividers & glow are derived from your primes — pick 6, the palette does the rest.',
                    style: TextStyle(
                      fontSize: 10 * sf,
                      color: f.secondary.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionLabel('IMAGE — pick from the gungeon', f, sf),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 58,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _splashes.length,
                      itemBuilder: (context, i) {
                        final slug = _splashes[i];
                        final sel = slug == _splashSlug;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _splashSlug = slug);
                            Haptics.selection();
                          },
                          child: Container(
                            width: 58,
                            height: 58,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color:
                                    sel
                                        ? f.primary
                                        : Colors.white.withValues(alpha: 0.15),
                                width: sel ? 2.2 : 1,
                              ),
                              boxShadow:
                                  sel
                                      ? [
                                        BoxShadow(
                                          color: f.primary.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                      : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: Image.asset(
                                'assets/images/themes/splash/$slug.jpg',
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (c, e, st) => Container(
                                      color: f.primary.withValues(alpha: 0.1),
                                      child: Icon(
                                        Icons.palette_outlined,
                                        color: f.primary,
                                        size: 22,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    style: TextStyle(fontSize: 14 * sf, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Name your palette…',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13 * sf,
                      ),
                      errorText: _error,
                      filled: true,
                      fillColor: f.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                  const SizedBox(height: 12),
                  ScaleButton(
                    onTap: _save,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: f.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: f.primary.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: GoopText(
                          'SAVE PALETTE',
                          style: TextStyle(
                            fontSize: FontSizes.labelMedium * sf,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: f.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t, ThemeFlair f, double sf) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GoopText(
        t,
        style: TextStyle(
          fontSize: FontSizes.labelSmall * sf,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
          color: f.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  Widget _slot(
    String label,
    Color color,
    void Function(Color) onPick,
    ThemeFlair f,
    double sf,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _pickColor(label, color, onPick),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: f.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GoopText(
                label,
                style: TextStyle(
                  fontSize: 13 * sf,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const Spacer(),
              GoopText(
                '#${color.toARGB32().toRadixString(16).toUpperCase()}',
                style: TextStyle(
                  fontSize: 11 * sf,
                  color: f.secondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickColor(
    String label,
    Color current,
    void Function(Color) onPick,
  ) async {
    final sf = Responsive.factor(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _flair.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder:
          (_) => Padding(
            padding: EdgeInsets.all(16 * sf),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: FontSizes.labelSmall * sf,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: _flair.primary,
                  ),
                ),
                SizedBox(height: 10 * sf),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _swatches)
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(c),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  c == current.toARGB32()
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.15),
                              width: c == current.toARGB32() ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10 * sf),
              ],
            ),
          ),
    );
    if (picked != null) onPick(Color(picked));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name your palette first');
      return;
    }
    if (CustomThemeStore.themes.any(
      (t) => t.name.toLowerCase() == name.toLowerCase(),
    )) {
      setState(() => _error = 'A palette named "$name" already exists');
      return;
    }
    Haptics.success();
    await CustomThemeStore.save(
      SavedCustomTheme(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        splashSlug: _splashSlug,
        baseMode: AppThemeMode.custom,
        prefs: VisualPrefs.notifier.value,
        customData: _data.copyWith(name: name),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GoopText('Palette "$name" saved'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }
}

// ── Live preview — real card chrome painted with the working palette ──

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({required this.flair, required this.sf});
  final ThemeFlair flair;
  final double sf;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final name = p.runState.main.character?.name ?? 'MARINE';
    final guns = p.runState.main.guns;
    final gun = guns.isNotEmpty ? guns.first : null;
    return Container(
      color: flair.scaffold,
      padding: EdgeInsets.all(14 * sf),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Char panel
          Container(
            padding: EdgeInsets.all(12 * sf),
            decoration: BoxDecoration(
              color: flair.card,
              borderRadius: BorderRadius.circular(flair.cardRadius),
              border: Border.all(
                color: flair.cardBorderColor ?? Colors.white24,
              ),
              boxShadow: [
                BoxShadow(
                  color: flair.glowPrimary.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: flair.primary.withValues(alpha: 0.2),
                  child: Icon(Icons.person_outline, color: flair.primary),
                ),
                SizedBox(width: 10 * sf),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        name,
                        style: TextStyle(
                          fontSize: 15 * sf,
                          fontWeight: FontWeight.w900,
                          color: flair.headlineStat,
                        ),
                      ),
                      GoopText(
                        'ACTIVE RUN · P1',
                        style: TextStyle(
                          fontSize: 9 * sf,
                          letterSpacing: 1.5,
                          color: flair.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GoopText(
                  gun?.dps.isNotEmpty == true ? gun!.dps : '—',
                  style: TextStyle(
                    fontSize: 20 * sf,
                    fontWeight: FontWeight.w900,
                    color: flair.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10 * sf),
          // Periodic-style grid tiles — gun + item side by side so the
          // preview shows the real inventory chrome, not one card.
          if (gun != null)
            Row(
              children: [
                _previewTile(
                  Icons.gps_fixed,
                  gun.name.toUpperCase(),
                  '${gun.quality} · ${gun.dps} DPS',
                  flair,
                  sf,
                ),
                SizedBox(width: 8 * sf),
                _previewTile(
                  Icons.backpack_rounded,
                  'OILED CYLINDER',
                  'S · SYNERGY',
                  flair,
                  sf,
                ),
              ],
            ),
          SizedBox(height: 8 * sf),
          // Flavor + tags
          GoopText(
            '"${flair.font == AppFont.gungeon ? 'Enter the Gungeon' : 'A pale of your own making'}"',
            style: TextStyle(
              fontSize: 10 * sf,
              fontStyle: FontStyle.italic,
              color: flair.secondary.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 6 * sf),
          Row(
            children: [
              _tag('DARK', flair),
              SizedBox(width: 6 * sf),
              _tag('CLEAN', flair),
              SizedBox(width: 6 * sf),
              _tag('YOURS', flair),
            ],
          ),
        ],
      ),
    );
  }

  /// Periodic-grid-style preview tile — icon panel + name + meta,
  /// painted with the working palette.
  Widget _previewTile(
    IconData icon,
    String name,
    String meta,
    ThemeFlair f,
    double sf,
  ) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(8 * sf),
        decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(f.cardRadius),
          border: Border.all(color: f.cardBorderColor ?? Colors.white24),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: f.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: f.bulletColor, size: 20),
            ),
            SizedBox(height: 6 * sf),
            GoopText(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10 * sf,
                fontWeight: FontWeight.w800,
                color: f.headlineStat,
              ),
            ),
            GoopText(
              meta,
              maxLines: 1,
              style: TextStyle(fontSize: 8.5 * sf, color: f.secondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String t, ThemeFlair f) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: f.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(f.chipRadius),
        border: Border.all(color: f.primary.withValues(alpha: 0.3)),
      ),
      child: GoopText(
        t,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: f.primary,
        ),
      ),
    );
  }
}
