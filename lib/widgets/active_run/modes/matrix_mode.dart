import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/player.dart';
import '../../../models/run_state.dart';
import '../../../providers/run_provider.dart';
import '../../../services/app_theme.dart';
import '../../../services/goop_talk_engine.dart';
import '../../../utils/asset_paths.dart';
import '../../../utils/fast_route.dart';
import '../../../screens/item_detail_screen.dart';
import '../../game_icon.dart';
import '../depth_tile.dart';
import '../mode_helpers.dart' as mh;
import '../../backgrounds/gungeon_matrix_rain.dart';

/// Mode 3 — Purple Gungeon Matrix.
///
/// Deep purple-black background with falling glyph columns. Active
/// run data in translucent glassmorphic panels floating over the
/// rain. Character portrait in a circular "terminal" frame. Stats
/// as a vertical data readout on the right edge. Guns + items as
/// horizontal drifting data stream chips. Central focus panel for
/// the top-DPS gun.
///
/// Performance: single AnimationController for rain, single
/// controller for chip drift. Rain capped at 24x18 glyphs, DPR-aware
/// reduction. No sensors_plus parallax (user-confirmed).
class MatrixMode extends StatefulWidget {
  final PlayerSlot slot;
  const MatrixMode({super.key, required this.slot});

  @override
  State<MatrixMode> createState() => _MatrixModeState();
}

class _MatrixModeState extends State<MatrixMode>
    with TickerProviderStateMixin {
  late final AnimationController _drift;
  late final AnimationController _scan;
  late final ScrollController _gunStream;
  late final ScrollController _itemStream;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _scan = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _gunStream = ScrollController();
    _itemStream = ScrollController();
  }

  @override
  void dispose() {
    _drift.dispose();
    _scan.dispose();
    _gunStream.dispose();
    _itemStream.dispose();
    super.dispose();
  }

  bool get isMain => widget.slot == PlayerSlot.main;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final state = p.runState;
    final player = isMain ? state.main : state.coop;

    if (player == null || player.character == null) {
      return const Center(child: GoopText('No player'));
    }

    final flair = AppTheme.flair;
    final glowColors = mh.synergyGlowColors(p);
    final topDps = mh.topDpsInfo(player, p);
    final activeSynergies = isMain ? p.getActiveSynergies().length : 0;
    final partialSynergies = isMain ? p.getPartialSynergies().length : 0;

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          // Layer 0: matrix rain background
          const Positioned.fill(
            child: IgnorePointer(child: GungeonMatrixRain()),
          ),

          // Layer 1: content
 Positioned.fill(
            child: Column(
              children: [
                // Top row: terminal portrait + data readout
                SizedBox(
                  height: 120,
                  child: Row(
                    children: [
                      _terminalPortrait(player, flair),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _dataReadout(
                          player,
                          state,
                          topDps,
                          activeSynergies,
                          partialSynergies,
                          flair,
                        ),
                      ),
                    ],
                  ),
                ),
                // Focus panel: top-DPS gun
                if (topDps.dps > 0 && player.guns.isNotEmpty)
                  _focusPanel(player, p, topDps, flair),
                // Data streams
                Expanded(
                  child: Column(
                    children: [
                      _streamLabel('GUN STREAM', flair),
                      Expanded(child: _gunStreamRow(player, p, flair, glowColors)),
                      _streamLabel('ITEM STREAM', flair),
                      Expanded(child: _itemStreamRow(player, flair, glowColors)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Terminal portrait ---------------------------------------------

  Widget _terminalPortrait(Player player, ThemeFlair flair) {
    final char = player.character!;
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: flair.primary.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: flair.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                gungeoneerGifPath(char.name),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.terminal,
                  size: 32,
                  color: flair.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          // Scanning line
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _scan,
                builder: (_, __) {
                  final y = 8.0 + _scan.value * 84.0;
                  return CustomPaint(
                    painter: _ScanLinePainter(
                      y: y,
                      color: flair.primary,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Data readout (right edge stats) --------------------------------

  Widget _dataReadout(
    Player player,
    RunState state,
    ({String name, double dps}) topDps,
    int activeSynergies,
    int partialSynergies,
    ThemeFlair flair,
  ) {
    final stats = <_DataLine>[
      _DataLine('CHAR', player.character!.name, flair.primary),
      if (isMain) ...[
        _DataLine('COOL', state.totalCoolness.toStringAsFixed(0), Colors.cyanAccent),
        _DataLine('CURSE', state.totalCurse.toStringAsFixed(0), Colors.deepOrangeAccent),
      ],
      _DataLine('GUNS', '${player.guns.length}', flair.primary),
      _DataLine('ITEMS', '${player.items.length}', Colors.amberAccent),
      if (topDps.dps > 0)
        _DataLine('TOP_DPS', topDps.dps.toStringAsFixed(1), Colors.greenAccent),
      if (isMain && activeSynergies > 0)
        _DataLine('SYN_ACT', '$activeSynergies', flair.primary),
      if (isMain && partialSynergies > 0)
        _DataLine('SYN_PART', '$partialSynergies', Colors.amberAccent),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(
              color: flair.primary.withValues(alpha: 0.2),
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: stats.map((s) => _dataLine(s, flair)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _dataLine(_DataLine line, ThemeFlair flair) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GoopText(
          '${line.label}:',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.4),
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 4),
        GoopText(
          line.value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: line.color,
            fontFamily: 'monospace',
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ---- Focus panel (top-DPS gun) --------------------------------------

  Widget _focusPanel(
    Player player,
    RunProvider p,
    ({String name, double dps}) topDps,
    ThemeFlair flair,
  ) {
    final gun = player.guns.firstWhere(
      (g) => g.name == topDps.name,
      orElse: () => player.guns.first,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          fastRoute(ItemDetailScreen(gun: gun, ownerSlot: widget.slot)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: flair.primary.withValues(alpha: 0.08),
                border: Border.all(
                  color: flair.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: flair.primary.withValues(alpha: 0.1),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, size: 16, color: flair.primary),
                  const SizedBox(width: 8),
                  GoopText(
                    'FOCUS:',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.4),
                      fontFamily: 'monospace',
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GoopText(
                      gun.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: flair.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GoopText(
                    '${topDps.dps.toStringAsFixed(1)} DPS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.greenAccent,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Data streams (guns + items) ------------------------------------

  Widget _streamLabel(String label, ThemeFlair flair) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 2),
      child: GoopText(
        '> $label',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: flair.primary.withValues(alpha: 0.5),
          fontFamily: 'monospace',
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _gunStreamRow(
    Player player,
    RunProvider p,
    ThemeFlair flair,
    Map<String, Color> glowColors,
  ) {
    if (player.guns.isEmpty) {
      return _emptyStream('NO GUNS LOADED', flair);
    }
    return ListView.builder(
      controller: _gunStream,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: player.guns.length,
      itemBuilder: (c, i) {
        final g = player.guns[i];
        final isTop = g.name == mh.topDpsInfo(player, p).name;
        final glow = glowColors[g.name.toLowerCase()];
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: DepthTile(
            isTopDps: isTop,
            glowColor: glow,
            onTap: () => Navigator.push(
              c,
              fastRoute(ItemDetailScreen(gun: g, ownerSlot: widget.slot)),
            ),
            onLongPress: () => mh.promptTileActions(
              c,
              slot: widget.slot,
              gun: g,
            ),
            child: _streamChip(
              g.name,
              '${mh.effectiveDps(g, p).toStringAsFixed(0)} DPS',
              g.icon,
              g.quality,
              isTop,
              glow,
              flair,
            ),
          ),
        );
      },
    );
  }

  Widget _itemStreamRow(
    Player player,
    ThemeFlair flair,
    Map<String, Color> glowColors,
  ) {
    if (player.items.isEmpty) {
      return _emptyStream('NO ITEMS LOADED', flair);
    }
    return ListView.builder(
      controller: _itemStream,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: player.items.length,
      itemBuilder: (c, i) {
        final it = player.items[i];
        final glow = glowColors[it.name.toLowerCase()];
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: DepthTile(
            glowColor: glow,
            onTap: () => Navigator.push(
              c,
              fastRoute(ItemDetailScreen(item: it, ownerSlot: widget.slot)),
            ),
            onLongPress: () => mh.promptTileActions(
              c,
              slot: widget.slot,
              item: it,
            ),
            child: _streamChip(
              it.name,
              it.rechargeTime.isNotEmpty ? it.rechargeTime : '',
              it.icon,
              it.quality,
              false,
              glow,
              flair,
            ),
          ),
        );
      },
    );
  }

  Widget _streamChip(
    String name,
    String stat,
    String icon,
    String quality,
    bool isTop,
    Color? glow,
    ThemeFlair flair,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isTop
              ? Colors.amberAccent.withValues(alpha: 0.5)
              : glow != null
                  ? glow.withValues(alpha: 0.3)
                  : flair.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: GameIcon(
              assetPath: icon,
              fallback: Icons.help_outline,
              quality: quality,
              size: 18,
              showRing: false,
            ),
          ),
          const SizedBox(width: 6),
          GoopText(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isTop ? Colors.amberAccent : Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (stat.isNotEmpty) ...[
            const SizedBox(width: 6),
            GoopText(
              stat,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: flair.primary,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyStream(String message, ThemeFlair flair) {
    return Center(
      child: GoopText(
        '> $message',
        style: TextStyle(
          fontSize: 10,
          color: flair.primary.withValues(alpha: 0.3),
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// A single line in the data readout panel.
class _DataLine {
  final String label;
  final String value;
  final Color color;
  _DataLine(this.label, this.value, this.color);
}

/// Scanning line painter for the terminal portrait.
class _ScanLinePainter extends CustomPainter {
  final double y;
  final Color color;
  _ScanLinePainter({required this.y, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    canvas.drawLine(
      Offset(8, y),
      Offset(size.width - 8, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.y != y;
}
