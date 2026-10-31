import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../utils/fast_route.dart';
import '../widgets/browse/browse_pills.dart';
import '../widgets/browse/browse_row.dart';
import '../widgets/active_run/player_page.dart';
import '../widgets/periodic_tile.dart';
import '../widgets/skeuo/skeuo_backdrop.dart';
import '../widgets/skeuo/skeuo_surface.dart';
import '../widgets/skeuo/skeuo_tokens.dart';
import 'item_detail_screen.dart';

/// Neo-Skeuo component sheet — a replica of the reference kit poster
/// with every element translated into GungeonMate's skeuo widgets.
/// This screen is the style sandbox: kit pieces are perfected here
/// before they roll out to real app screens.
class NeoSkeuoLabScreen extends StatefulWidget {
  const NeoSkeuoLabScreen({super.key});

  @override
  State<NeoSkeuoLabScreen> createState() => _NeoSkeuoLabScreenState();
}

class _NeoSkeuoLabScreenState extends State<NeoSkeuoLabScreen> {
  // Demo control state.
  bool _checked = true;
  bool _switchOn = true;
  int _radio = 0;
  double _slider = 75;
  int _tab = 0;
  int _page = 2;
  int _step = 2;
  bool _confirmDelete = false;
  int _sheetTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Skeuo.paper,
      body: Stack(
        children: [
          const SkeuoPaperBackdrop(posterChrome: true),
          SafeArea(
            child: Column(
              children: [
                _sheetTabs(),
                Expanded(
                  child: IndexedStack(
                    index: _sheetTab,
                    children: [
                      _specSheetTab(),
                      _activeRunTab(),
                      _browseTab(),
                      _detailTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _skeuoBackBar(context),
    );
  }

  /// Skeuo segmented tab row — SPEC SHEET / ACTIVE RUN / BROWSE / DETAIL.
  Widget _sheetTabs() {
    const labels = ['SPEC SHEET', 'ACTIVE RUN', 'BROWSE', 'DETAIL'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 12, 20, 8),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _sheetTab = i);
                  Haptics.selection();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _sheetTab == i ? Skeuo.ink : Skeuo.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Skeuo.ink, width: 1.6),
                    boxShadow: const [
                      BoxShadow(color: Skeuo.ink, offset: Offset(2, 2)),
                    ],
                  ),
                  child: GoopText(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: _sheetTab == i ? Skeuo.card : Skeuo.ink,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _specSheetTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 16, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kitHeader(),
              const SizedBox(height: 18),
              _section('TYPEFACE', _fontPicker()),
              _section('FOUNDATIONS', _foundations()),
              _section('CONTROLS', _controls()),
              _section('NAVIGATION', _navigation()),
              _section('DATA DISPLAY', _dataDisplay()),
              _section('FEEDBACK', _feedback()),
              const SizedBox(height: 8),
              const Center(
                child: GoopText(
                  'DRAWN WITH CARE IN THE GUNGEON',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.6,
                    color: Skeuo.pencil,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TYPEFACE ───────────────────────────────────────────────────
  Widget _fontPicker() {
    return Wrap(
      spacing: 8,
      children: [
        for (var i = 0; i < AppTheme.skeuoFonts.length; i++)
          GestureDetector(
            onTap: () {
              AppTheme.setSkeuoFont(i);
              setState(() {});
              Haptics.selection();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.skeuoFontIndex == i ? Skeuo.ink : Skeuo.card,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Skeuo.ink, width: 1.6),
                boxShadow: const [
                  BoxShadow(color: Skeuo.ink, offset: Offset(2, 2)),
                ],
              ),
              child: GoopText(
                AppTheme.skeuoFonts[i].label,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppTheme.skeuoFonts[i].textStyle.fontFamily,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.skeuoFontIndex == i ? Skeuo.card : Skeuo.ink,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── ACTIVE RUN (real widgets) ──────────────────────────────────
  Widget _activeRunTab() {
    final p = context.watch<RunProvider>();
    final guns = p.allGuns.take(8).toList();
    final items = p.allItems.take(8).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subLabel('PLAYER PANEL (REAL)'),
          // The real run panel — avatar, cool/curse/syn chips, stats
          // strip, dashboards, inventory — mounted unmodified so every
          // skeuo defect is visible in place.
          const SizedBox(
            height: 640,
            child: ClipRect(child: PlayerPage(slot: PlayerSlot.main)),
          ),
          _subLabel('GUN TILES · 4-COL DEMO'),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.72,
            children: [for (final g in guns) PeriodicTile(gun: g, onTap: () {})],
          ),
          _subLabel('ITEM TILES · 4-COL DEMO'),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.72,
            children: [
              for (final it in items) PeriodicTile(item: it, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  // ── BROWSE (real rows) ─────────────────────────────────────────
  Widget _browseTab() {
    final p = context.watch<RunProvider>();
    final guns = p.allGuns.take(6).toList();
    final items = p.allItems.take(4).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 16, 20, 24),
      children: [
        for (final g in guns)
          BrowseRow(
            name: g.name,
            quality: g.quality,
            iconPath: g.icon,
            fallback: Icons.gps_fixed,
            meta: GunMeta(gun: g, synergyCount: p.synergyCountFor(g.name)),
            inRun: false,
            isRobot: false,
            onTap:
                () => Navigator.push(
                  context,
                  fastRoute(ItemDetailScreen(gun: g)),
                ),
            onAdd: () {},
          ),
        for (final it in items)
          BrowseRow(
            name: it.name,
            quality: it.quality,
            iconPath: it.icon,
            fallback: Icons.backpack_outlined,
            meta: ItemMeta(item: it, synergyCount: p.synergyCountFor(it.name)),
            inRun: false,
            isRobot: false,
            onTap:
                () => Navigator.push(
                  context,
                  fastRoute(ItemDetailScreen(item: it)),
                ),
            onAdd: () {},
          ),
      ],
    );
  }

  // ── DETAIL (real screen, embedded) ─────────────────────────────
  Widget _detailTab() {
    final p = context.watch<RunProvider>();
    final guns = p.allGuns;
    if (guns.isEmpty) {
      return const Center(
        child: GoopText('Loading…', style: TextStyle(color: Skeuo.ink)),
      );
    }
    // A.W.P. if present — the reference detail screen.
    final gun = guns.firstWhere(
      (g) => g.name.contains('A.W.P'),
      orElse: () => guns.first,
    );
    return ClipRect(child: ItemDetailScreen(gun: gun));
  }

  // ── Header ─────────────────────────────────────────────────────
  Widget _kitHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: GoopText(
            'NEO-SKEUO UI KIT',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Skeuo.ink,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(height: 2, color: Skeuo.ink),
        const SizedBox(height: 4),
        Row(
          children: [
            const GoopText(
              'GUNGEONMATE EDITION · COMPONENT SHEET',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                color: Skeuo.pencil,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GoopText(
              'p. 32',
              style: TextStyle(fontSize: 11, color: Skeuo.pencil),
            ),
          ],
        ),
      ],
    );
  }

  // ── Section scaffold ───────────────────────────────────────────
  Widget _section(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoopText(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Skeuo.ink,
            ),
          ),
          const SizedBox(height: 2),
          Container(height: 1, color: Skeuo.ink.withValues(alpha: 0.35)),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }

  Widget _subLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 10),
    child: GoopText(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Skeuo.pencil,
      ),
    ),
  );

  // ── FOUNDATIONS ────────────────────────────────────────────────
  Widget _foundations() {
    Widget tile(String label, SkeuoElevation e) => Expanded(
      child: SkeuoSurface(
        elevation: e,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
        child: Center(
          child: GoopText(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Skeuo.ink,
            ),
          ),
        ),
      ),
    );

    Widget specChip(String label, Widget visual) => Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          visual,
          const SizedBox(height: 4),
          GoopText(
            label,
            style: const TextStyle(fontSize: 10, color: Skeuo.pencil),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tile('Base\nSurface', SkeuoElevation.base),
            const SizedBox(width: 10),
            tile('Raised\nSurface', SkeuoElevation.raised),
            const SizedBox(width: 10),
            tile('Inset\nSurface', SkeuoElevation.inset),
            const SizedBox(width: 10),
            tile('Pressed\nSurface', SkeuoElevation.pressed),
          ],
        ),
        _subLabel('ELEVATION LEVELS'),
        Wrap(
          children: [
            specChip(
              'Level 1 · 3px',
              SkeuoSurface(
                elevation: SkeuoElevation.raised,
                shadowStyle: SkeuoShadowStyle.solid,
                radius: Skeuo.rSm,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: const GoopText(
                  'Low Shadow',
                  style: TextStyle(fontSize: 11, color: Skeuo.ink),
                ),
              ),
            ),
            specChip(
              'Level 2 · 5px',
              SkeuoSurface(
                elevation: SkeuoElevation.high,
                shadowStyle: SkeuoShadowStyle.solid,
                radius: Skeuo.rSm,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: const GoopText(
                  'Medium',
                  style: TextStyle(fontSize: 11, color: Skeuo.ink),
                ),
              ),
            ),
          ],
        ),
        _subLabel('BORDER THICKNESS'),
        Wrap(
          children: [
            for (final w in [
              Skeuo.borderThin,
              Skeuo.borderMed,
              Skeuo.borderThick,
            ])
              specChip(
                '${w.toInt()}px',
                SkeuoSurface(
                  elevation: SkeuoElevation.base,
                  borderWidth: w,
                  radius: Skeuo.rSm,
                  sketchy: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: const GoopText(
                    'Stroke',
                    style: TextStyle(fontSize: 11, color: Skeuo.ink),
                  ),
                ),
              ),
          ],
        ),
        _subLabel('RADIUS SCALE'),
        Wrap(
          children: [
            for (final r in [Skeuo.rSharp, Skeuo.rSm, Skeuo.rMd, Skeuo.rLg])
              specChip(
                '${r.toInt()}px',
                SkeuoSurface(
                  elevation: SkeuoElevation.base,
                  radius: r,
                  sketchy: false,
                  padding: const EdgeInsets.all(10),
                  child: const SizedBox(width: 10, height: 10),
                ),
              ),
            for (final r in [8.0, 12.0, 20.0])
              specChip(
                '${r.toInt()}px ⌀',
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Skeuo.ink, width: 2),
                  ),
                ),
              ),
          ],
        ),
        _subLabel('ICONOGRAPHY · 2PX STROKE'),
        Wrap(
          children: [
            specChip(
              '16px Regular',
              const Icon(Icons.settings_outlined, size: 16, color: Skeuo.ink),
            ),
            specChip(
              '20px Medium',
              const Icon(Icons.person_outline, size: 20, color: Skeuo.ink),
            ),
            specChip(
              '24px Large',
              const Icon(Icons.favorite_outline, size: 24, color: Skeuo.ink),
            ),
          ],
        ),
      ],
    );
  }

  // ── CONTROLS ───────────────────────────────────────────────────
  Widget _controls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subLabel('BUTTON SETS'),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            SkeuoButton.primary(label: 'Primary', compact: true, onTap: () {}),
            const SkeuoSurface(
              elevation: SkeuoElevation.pressed,
              radius: Skeuo.rMd,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: GoopText(
                'Primary (Pressed)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Skeuo.ink,
                  decoration: TextDecoration.lineThrough,
                  decorationThickness: 2,
                ),
              ),
            ),
            const SkeuoButton.disabled(label: 'Secondary', compact: true),
            const SkeuoButton(
              label: 'Loading',
              style: SkeuoButtonStyle.outline,
              loading: true,
              compact: true,
            ),
          ],
        ),
        _subLabel('TEXT FIELD'),
        const _SkeuoFieldDemo(),
        _subLabel('CHECKBOX · RADIO · SWITCH · SLIDER'),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Checkbox pair.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _skeuoCheck(_checked, () {
                  setState(() => _checked = !_checked);
                  Haptics.selection();
                }),
                const SizedBox(width: 8),
                _skeuoCheck(false, () {
                  setState(() => _checked = true);
                  Haptics.selection();
                }),
              ],
            ),
            // Radio pair.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _skeuoRadio(_radio == 0, () {
                  setState(() => _radio = 0);
                  Haptics.selection();
                }),
                const SizedBox(width: 8),
                _skeuoRadio(_radio == 1, () {
                  setState(() => _radio = 1);
                  Haptics.selection();
                }),
              ],
            ),
            // Switch pair.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _skeuoSwitch(_switchOn, () {
                  setState(() => _switchOn = !_switchOn);
                  Haptics.selection();
                }),
                const SizedBox(width: 8),
                _skeuoSwitch(false, () {
                  setState(() => _switchOn = true);
                  Haptics.selection();
                }),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _skeuoSlider(),
      ],
    );
  }

  Widget _skeuoCheck(bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: on ? Skeuo.ink : Skeuo.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Skeuo.ink, width: 2),
        ),
        child: on ? const Icon(Icons.check, size: 15, color: Skeuo.card) : null,
      ),
    );
  }

  Widget _skeuoRadio(bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Skeuo.ink, width: 2),
        ),
        child:
            on
                ? Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Skeuo.ink,
                    ),
                  ),
                )
                : null,
      ),
    );
  }

  Widget _skeuoSwitch(bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: on ? Skeuo.ink : Skeuo.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Skeuo.ink, width: 2),
        ),
        child: Align(
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? Skeuo.card : Skeuo.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeuoSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoopText(
          'Value Label: ${_slider.toInt()}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Skeuo.ink,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder:
              (context, c) => GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final w = c.maxWidth - 16;
                  setState(
                    () =>
                        _slider =
                            ((_slider / 100) * w + d.delta.dx)
                                .clamp(0, w)
                                .toDouble() /
                            w *
                            100,
                  );
                },
                onTapDown: (d) {
                  final w = c.maxWidth - 16;
                  setState(
                    () =>
                        _slider =
                            ((d.localPosition.dx - 8) / w * 100)
                                .clamp(0, 100)
                                .toDouble(),
                  );
                },
                child: SizedBox(
                  height: 28,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _SkeuoSliderPainter(value: _slider),
                  ),
                ),
              ),
        ),
      ],
    );
  }

  // ── NAVIGATION ─────────────────────────────────────────────────
  Widget _navigation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subLabel('TABS · BREADCRUMBS · PAGINATION'),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _skeuoTab(
                      ['Tabs', 'Rounder', 'Library'][i],
                      _tab == i,
                      () {
                        setState(() => _tab = i);
                        Haptics.selection();
                      },
                      radius: i == 0 ? Skeuo.rSm : (i == 1 ? Skeuo.rLg : 999),
                    ),
                  ),
              ],
            ),
            const GoopText(
              'Home  ›  Library  ›  Data',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Skeuo.ink,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 6; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child:
                        i == 3
                            ? const GoopText(
                              '…',
                              style: TextStyle(color: Skeuo.pencil),
                            )
                            : _skeuoPageDot(
                              '${i > 3 ? i + 1 : i + 1}',
                              _page == i,
                              () {
                                setState(() => _page = i);
                                Haptics.selection();
                              },
                            ),
                  ),
              ],
            ),
          ],
        ),
        _subLabel('4-STEP PROCESS'),
        Row(
          children: [
            Expanded(child: _skeuoStepper()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GoopText(
                  'Active Step:',
                  style: TextStyle(fontSize: 10, color: Skeuo.pencil),
                ),
                const GoopText(
                  'Configure',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Skeuo.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _skeuoTab(
    String label,
    bool on,
    VoidCallback onTap, {
    double radius = 8,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: on ? Skeuo.ink : Skeuo.card,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Skeuo.ink, width: 1.6),
          boxShadow: const [
            BoxShadow(color: Skeuo.ink, offset: Offset(2.5, 2.5)),
          ],
        ),
        child: GoopText(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: on ? Skeuo.card : Skeuo.ink,
          ),
        ),
      ),
    );
  }

  Widget _skeuoPageDot(String label, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? Skeuo.ink : Skeuo.card,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Skeuo.ink, width: 1.6),
        ),
        child: GoopText(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: on ? Skeuo.card : Skeuo.ink,
          ),
        ),
      ),
    );
  }

  Widget _skeuoStepper() {
    return SizedBox(
      height: 30,
      child: LayoutBuilder(
        builder:
            (context, c) => GestureDetector(
              onTapUp: (d) {
                final idx = (d.localPosition.dx / (c.maxWidth / 4))
                    .floor()
                    .clamp(0, 3);
                setState(() => _step = idx);
                Haptics.selection();
              },
              child: CustomPaint(painter: _SkeuoStepperPainter(step: _step)),
            ),
      ),
    );
  }

  // ── DATA DISPLAY ───────────────────────────────────────────────
  Widget _dataDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            // Gun card — the kit card translated to a real gun row.
            SizedBox(
              width: 330,
              child: SkeuoSurface(
                elevation: SkeuoElevation.high,
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeuoSurface(
                      elevation: SkeuoElevation.inset,
                      radius: Skeuo.rSm,
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/images/game/guns/blasphemy.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, _, _) => const Icon(
                              Icons.gps_fixed,
                              size: 32,
                              color: Skeuo.ink,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: GoopText(
                                  'Blasphemy',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Skeuo.ink,
                                  ),
                                ),
                              ),
                              _inkPill('SEMIAUTO'),
                              const SizedBox(width: 6),
                              _inkPill('A', fill: true),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const GoopText(
                            'A sword that fires bullets when the bearer is uninjured. Trusty blade of the Bullet.',
                            maxLines: 3,
                            style: TextStyle(
                              fontSize: 11.5,
                              height: 1.35,
                              color: Skeuo.pencil,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // List items + badges column.
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _listItem('Item Title', 'Secondary text'),
                const SizedBox(height: 8),
                _listItem('Item Title', 'Secondary text'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [_inkPill('New'), _inkPill('Updated')],
                ),
              ],
            ),
          ],
        ),
        _subLabel('TOOLTIP · TABLE HEADER'),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const SkeuoSurface(
              elevation: SkeuoElevation.raised,
              radius: Skeuo.rSm,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: GoopText(
                'Information here',
                style: TextStyle(fontSize: 12, color: Skeuo.ink),
              ),
            ),
            SkeuoSurface(
              elevation: SkeuoElevation.raised,
              radius: Skeuo.rSm,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _headCell('Name'),
                  _headCell('Status'),
                  _headCell('Date'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _listItem(String title, String sub) {
    return SkeuoSurface(
      elevation: SkeuoElevation.base,
      radius: Skeuo.rSm,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Skeuo.ink, width: 1.6),
            ),
            child: const Icon(Icons.person_outline, size: 16, color: Skeuo.ink),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoopText(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Skeuo.ink,
                ),
              ),
              GoopText(
                sub,
                style: const TextStyle(fontSize: 11, color: Skeuo.pencil),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inkPill(String text, {bool fill = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fill ? Skeuo.ink : Skeuo.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Skeuo.ink, width: 1.6),
      ),
      child: GoopText(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fill ? Skeuo.card : Skeuo.ink,
        ),
      ),
    );
  }

  Widget _headCell(String t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GoopText(
          t,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Skeuo.ink,
          ),
        ),
        const SizedBox(width: 2),
        const Icon(Icons.unfold_more, size: 12, color: Skeuo.pencil),
      ],
    ),
  );

  // ── FEEDBACK ───────────────────────────────────────────────────
  Widget _feedback() {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        // Modal confirm mock.
        SkeuoSurface(
          elevation: SkeuoElevation.high,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 28, color: Skeuo.ink),
              const SizedBox(height: 8),
              const GoopText(
                'Delete item?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Skeuo.ink,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkeuoButton(
                    label: 'Delete',
                    compact: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onTap: () {
                      setState(() => _confirmDelete = !_confirmDelete);
                      Haptics.selection();
                    },
                  ),
                  const SizedBox(width: 10),
                  SkeuoButton.primary(
                    label: _confirmDelete ? 'Deleted!' : 'Confirm',
                    compact: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onTap: () {
                      setState(() => _confirmDelete = !_confirmDelete);
                      Haptics.medium();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        // Toast stack + alert banner.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _toast(),
            const SizedBox(height: 8),
            _toast(),
            const SizedBox(height: 12),
            const SkeuoSurface(
              elevation: SkeuoElevation.raised,
              radius: Skeuo.rSm,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Skeuo.ink),
                  SizedBox(width: 8),
                  GoopText(
                    'Warning',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Skeuo.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Empty state + skeletons + progress.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeuoSurface(
              elevation: SkeuoElevation.raised,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 34,
                    color: Skeuo.ink,
                  ),
                  const SizedBox(height: 6),
                  const GoopText(
                    'No data found',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Skeuo.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SkeuoButton(
                    label: 'Create New',
                    compact: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    onTap: () => Haptics.selection(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Container(
                  width: i == 0 ? 200 : (i == 1 ? 170 : 60),
                  height: 12,
                  decoration: BoxDecoration(
                    color: Skeuo.insetPaper,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Skeuo.ink.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GoopText(
                    'LINEAR PROGRESS',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      color: Skeuo.pencil,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Skeuo.card,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Skeuo.ink, width: 1.4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: 0.62,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Skeuo.ink,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _toast() {
    return SkeuoSurface(
      elevation: SkeuoElevation.raised,
      radius: Skeuo.rSm,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_outlined, size: 16, color: Skeuo.ink),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoopText(
                'Notification',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Skeuo.ink,
                ),
              ),
              GoopText(
                'Your current notification',
                style: TextStyle(fontSize: 10, color: Skeuo.pencil),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Icon(Icons.close, size: 14, color: Skeuo.ink),
        ],
      ),
    );
  }

  // ── Back bar ───────────────────────────────────────────────────
  Widget _skeuoBackBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        // Align + heightFactor — Center without it grows the bottomNav
        // to fill the screen (documented blank-body landmine).
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SkeuoButton(
              label: 'Back',
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inset-well text field with label, helper, and error line —
/// the reference's focused state is the inset highlight.
class _SkeuoFieldDemo extends StatelessWidget {
  const _SkeuoFieldDemo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GoopText(
            'Label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Skeuo.ink,
            ),
          ),
          const SizedBox(height: 5),
          SkeuoSurface(
            elevation: SkeuoElevation.inset,
            radius: Skeuo.rSm,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              style: const TextStyle(fontSize: 14, color: Skeuo.ink),
              cursorColor: Skeuo.ink,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Placeholder text',
                hintStyle: TextStyle(color: Skeuo.pencil, fontSize: 14),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              GoopText(
                'Helper text',
                style: TextStyle(fontSize: 10, color: Skeuo.pencil),
              ),
              SizedBox(width: 8),
              Icon(Icons.turn_left, size: 10, color: Skeuo.pencil),
              SizedBox(width: 16),
              GoopText(
                'Error message',
                style: TextStyle(
                  fontSize: 10,
                  color: Skeuo.accent,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Hand-drawn slider — baseline with tick marks, ink knob, 0/100 caps.
class _SkeuoSliderPainter extends CustomPainter {
  final double value;
  const _SkeuoSliderPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final track =
        Paint()
          ..color = Skeuo.ink
          ..strokeWidth = 1.6
          ..isAntiAlias = true;
    final cy = size.height / 2;
    final left = 8.0;
    final right = size.width - 8;
    canvas.drawLine(Offset(left, cy), Offset(right, cy), track);
    // Tick marks.
    final tick =
        Paint()
          ..color = Skeuo.ink
          ..strokeWidth = 1.0;
    for (var i = 0; i <= 10; i++) {
      final x = left + (right - left) * i / 10;
      canvas.drawLine(Offset(x, cy - 4), Offset(x, cy + 4), tick);
    }
    // End caps.
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final (label, x) in [('0', left), ('100', right)]) {
      tp.text = TextSpan(
        text: label,
        style: const TextStyle(fontSize: 9, color: Skeuo.ink),
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, cy + 7));
    }
    // Knob.
    final kx = left + (right - left) * (value / 100);
    canvas.drawCircle(
      Offset(kx, cy),
      8,
      Paint()
        ..color = Skeuo.card
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      Offset(kx, cy),
      8,
      Paint()
        ..color = Skeuo.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..isAntiAlias = true,
    );
    canvas.drawCircle(Offset(kx, cy), 2.5, Paint()..color = Skeuo.ink);
  }

  @override
  bool shouldRepaint(_SkeuoSliderPainter old) => old.value != value;
}

/// Four-step process — circles on a baseline, active gets a double
/// ring and the connector stops drawing past it in the reference.
class _SkeuoStepperPainter extends CustomPainter {
  final int step;
  const _SkeuoStepperPainter({required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    final n = 4;
    final cy = size.height / 2;
    final r = 8.0;
    final xs = <double>[for (var i = 0; i < n; i++) size.width * (i + 0.5) / n];
    final line =
        Paint()
          ..color = Skeuo.ink
          ..strokeWidth = 1.6;
    for (var i = 0; i < n - 1; i++) {
      canvas.drawLine(Offset(xs[i] + r, cy), Offset(xs[i + 1] - r, cy), line);
    }
    for (var i = 0; i < n; i++) {
      final active = i == step;
      final done = i < step;
      canvas.drawCircle(
        Offset(xs[i], cy),
        r,
        Paint()..color = done || active ? Skeuo.ink : Skeuo.card,
      );
      canvas.drawCircle(
        Offset(xs[i], cy),
        r,
        Paint()
          ..color = Skeuo.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
      if (active) {
        canvas.drawCircle(
          Offset(xs[i], cy),
          r + 3.5,
          Paint()
            ..color = Skeuo.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SkeuoStepperPainter old) => old.step != step;
}
