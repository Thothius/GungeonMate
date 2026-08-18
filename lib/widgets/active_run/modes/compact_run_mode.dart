import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/player.dart';
import '../../../models/run_state.dart';
import '../../../providers/run_provider.dart';
import '../../../services/app_theme.dart';
import '../../../services/haptics.dart';
import '../../../services/goop_talk_engine.dart';
import '../../../utils/fast_route.dart';
import '../../../screens/item_detail_screen.dart';
import '../../game_icon.dart';
import '../depth_tile.dart';
import '../mode_helpers.dart' as mh;

/// Mode 2 — Super-Compact Quick Run.
///
/// A tactical HUD layout. Everything fits in one screen-height on a
/// typical phone — no scroll for the core loadout. Dense, monospace,
/// neon.
///
/// Layout:
/// - Top strip: character name + 4 inline stat chips.
/// - Middle: 2-column grid — left guns (icon + name + DPS), right
///   items (icon + name + recharge). ~6 rows visible.
/// - Overflow: "X more" chip opens a scrollable sheet.
/// - No section headers, no sort pickers.
///
/// 2.5D: tiles use a flatter tilt (~4°). Top-DPS gun gets a gold
/// left-border accent.
class CompactRunMode extends StatelessWidget {
  final PlayerSlot slot;
  const CompactRunMode({super.key, required this.slot});

  static const int _maxRows = 6;

  bool get isMain => slot == PlayerSlot.main;

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

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D0F),
          border: Border(
            top: BorderSide(color: flair.primary.withValues(alpha: 0.08)),
          ),
        ),
        child: Column(
          children: [
            _statStrip(player, state, p, topDps, flair),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _column(
                      context,
                      items: player.guns.map((g) => _CompactEntry(
                            name: g.name,
                            icon: g.icon,
                            quality: g.quality,
                            trailing:
                                mh.effectiveDps(g, p).toStringAsFixed(0),
                            trailingSuffix: 'DPS',
                            isTopDps: g.name == topDps.name,
                            glow: glowColors[g.name.toLowerCase()],
                            onTap: () => Navigator.push(
                              context,
                              fastRoute(
                                  ItemDetailScreen(gun: g, ownerSlot: slot)),
                            ),
                            onLongPress: () => mh.promptTileActions(
                              context,
                              slot: slot,
                              gun: g,
                            ),
                          )),
                      fallbackIcon: Icons.gps_fixed,
                      flair: flair,
                      emptyText: 'No guns',
                    ),
                  ),
                  Container(width: 1, color: Colors.white.withValues(alpha: 0.05)),
                  Expanded(
                    child: _column(
                      context,
                      items: player.items.map((it) => _CompactEntry(
                            name: it.name,
                            icon: it.icon,
                            quality: it.quality,
                            trailing: it.rechargeTime.isNotEmpty
                                ? it.rechargeTime.replaceAll(RegExp(r'[^0-9.]'), '')
                                : '',
                            trailingSuffix: it.rechargeTime.isNotEmpty ? 's' : '',
                            glow: glowColors[it.name.toLowerCase()],
                            onTap: () => Navigator.push(
                              context,
                              fastRoute(
                                  ItemDetailScreen(item: it, ownerSlot: slot)),
                            ),
                            onLongPress: () => mh.promptTileActions(
                              context,
                              slot: slot,
                              item: it,
                            ),
                          )),
                      fallbackIcon: Icons.inventory_2_outlined,
                      flair: flair,
                      emptyText: 'No items',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Top stat strip ------------------------------------------------

  Widget _statStrip(
    Player player,
    RunState state,
    RunProvider p,
    ({String name, double dps}) topDps,
    ThemeFlair flair,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: flair.primary.withValues(alpha: 0.04),
        border: Border(
          bottom: BorderSide(color: flair.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // Character name
          GoopText(
            player.character!.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: flair.primary,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 8),
          if (isMain) ...[
            _statChip('COOL', state.totalCoolness.toStringAsFixed(0),
                Colors.cyanAccent),
            const SizedBox(width: 6),
            _statChip('CURSE', state.totalCurse.toStringAsFixed(0),
                Colors.deepOrangeAccent),
            const SizedBox(width: 6),
          ],
          _statChip(
              'GUNS', '${player.guns.length}', flair.primary),
          const SizedBox(width: 6),
          _statChip(
              'ITEMS', '${player.items.length}', Colors.amberAccent),
          const Spacer(),
          if (topDps.dps > 0)
            _statChip('TOP', topDps.dps.toStringAsFixed(0),
                Colors.greenAccent,
                suffix: 'DPS'),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color,
      {String suffix = ''}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoopText(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: color.withValues(alpha: 0.7),
              letterSpacing: 0.5,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 3),
          GoopText(
            '$value${suffix.isNotEmpty ? ' $suffix' : ''}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ---- 2-column grid --------------------------------------------------

  Widget _column(
    BuildContext context, {
    required Iterable<_CompactEntry> items,
    required IconData fallbackIcon,
    required ThemeFlair flair,
    required String emptyText,
  }) {
    final list = items.toList();
    if (list.isEmpty) {
      return Center(
        child: GoopText(
          emptyText,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.2),
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    final visible = list.take(_maxRows).toList();
    final overflow = list.length - visible.length;

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: [
          ...visible.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _compactRow(e, flair),
              )),
          if (overflow > 0)
            GestureDetector(
              onTap: () => _showOverflowSheet(context, list, flair),
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: flair.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: GoopText(
                  '+$overflow MORE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: flair.primary,
                    letterSpacing: 0.8,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _compactRow(_CompactEntry entry, ThemeFlair flair) {
    return DepthTile(
      isTopDps: entry.isTopDps,
      glowColor: entry.glow,
      onTap: entry.onTap,
      onLongPress: entry.onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: entry.glow != null
                ? entry.glow!.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.04),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            if (entry.isTopDps)
              Container(
                width: 2,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.amberAccent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            if (entry.isTopDps) const SizedBox(width: 4),
            SizedBox(
              height: 20,
              width: 20,
              child: GameIcon(
                assetPath: entry.icon,
                fallback: Icons.help_outline,
                quality: entry.quality,
                size: 20,
                showRing: false,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: GoopText(
                entry.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: entry.isTopDps
                      ? Colors.amberAccent
                      : Colors.white.withValues(alpha: 0.85),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.trailing.isNotEmpty)
              GoopText(
                '${entry.trailing}${entry.trailingSuffix}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: flair.primary.withValues(alpha: 0.8),
                  fontFamily: 'monospace',
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---- Overflow sheet -------------------------------------------------

  void _showOverflowSheet(
      BuildContext context, List<_CompactEntry> all, ThemeFlair flair) {
    Haptics.selection();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131316),
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: all.length,
        itemBuilder: (c, i) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _compactRow(all[i], flair),
        ),
      ),
    );
  }
}

/// A single compact row entry — gun or item flattened to the common
/// fields the compact layout needs.
class _CompactEntry {
  final String name;
  final String icon;
  final String quality;
  final String trailing;
  final String trailingSuffix;
  final bool isTopDps;
  final Color? glow;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  _CompactEntry({
    required this.name,
    required this.icon,
    required this.quality,
    required this.trailing,
    this.trailingSuffix = '',
    this.isTopDps = false,
    this.glow,
    required this.onTap,
    this.onLongPress,
  });
}
