import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/gun.dart';
import '../../../models/gungeoneer.dart';
import '../../../models/item.dart';
import '../../../models/player.dart';
import '../../../models/run_state.dart';
import '../../../providers/run_provider.dart';
import '../../../services/app_theme.dart';
import '../../../services/haptics.dart';
import '../../../services/goop_talk_engine.dart';
import '../../../utils/asset_paths.dart';
import '../../../utils/fast_route.dart';
import '../../../screens/item_detail_screen.dart';
import '../../game_icon.dart';
import '../depth_tile.dart';
import '../gungeon_meter.dart';
import '../mode_helpers.dart' as mh;

/// Mode 1 — The Gungeon Codex Book.
///
/// A leather-and-brass compendium layout. The screen reads as an open
/// book: left page = character portrait + stats, right page = guns /
/// items / synergies (swipeable). Page corners have a subtle curl
/// shadow. Gun/item rows use [DepthTile] for the 2.5D lift effect.
///
/// Receives [slot] and reads [RunProvider] itself — consistent with
/// how `PlayerPage` works. All MP/transfer/undo flows go through
/// `mode_helpers.dart` so we don't duplicate that logic.
class CodexBookMode extends StatefulWidget {
  final PlayerSlot slot;
  const CodexBookMode({super.key, required this.slot});

  @override
  State<CodexBookMode> createState() => _CodexBookModeState();
}

class _CodexBookModeState extends State<CodexBookMode> {
  late final PageController _pageController;
  int _currentRightPage = 0; // 0=Guns, 1=Items, 2=Synergies

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get isMain => widget.slot == PlayerSlot.main;

  void _goToPage(int page) {
    Haptics.selection();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

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
      child: Container(
        decoration: _bookBackground(flair),
        child: Column(
          children: [
            // The "book" — two pages side by side on wide screens,
            // stacked on narrow screens.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 600;
                  if (wide) {
                    return Row(
                      children: [
                        Expanded(flex: 2, child: _leftPage(player, state, p, flair)),
                        _bookSpine(flair),
                        Expanded(
                          flex: 3,
                          child: _rightPage(
                            player,
                            p,
                            flair,
                            glowColors,
                            topDps,
                            activeSynergies,
                            partialSynergies,
                          ),
                        ),
                      ],
                    );
                  }
                  // Narrow: stack vertically — character page on top,
                  // guns/items below in a PageView.
                  return Column(
                    children: [
                      SizedBox(
                        height: constraints.maxHeight * 0.28,
                        child: _leftPage(player, state, p, flair),
                      ),
                      _bookSpine(flair, horizontal: true),
                      Expanded(
                        child: _rightPage(
                          player,
                          p,
                          flair,
                          glowColors,
                          topDps,
                          activeSynergies,
                          partialSynergies,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _pageTurnBar(flair),
          ],
        ),
      ),
    );
  }

  // ---- Left page: character + stats ----------------------------------

  Widget _leftPage(Player player, RunState state, RunProvider p, ThemeFlair flair) {
    final char = player.character!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          _locketFrame(char, flair),
          const SizedBox(height: 12),
          GoopText(
            char.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: flair.primary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Interactive meters for coolness/curse (Main only — coop
          // doesn't have dungeon-scope stats). Tap or drag the bar to
          // adjust. Threshold at 10 = Lord of the Jammed / max cool.
          if (isMain) ...[
            GungeonMeter(
              value: state.totalCoolness.clamp(0.0, 15.0),
              isCool: true,
              color: const Color(0xFF00E5FF),
              label: 'COOLNESS',
              onDelta: (d) => p.adjustCoolness(d),
            ),
            const SizedBox(height: 10),
            GungeonMeter(
              value: state.totalCurse.clamp(0.0, 15.0),
              isCool: false,
              color: const Color(0xFFFF3D00),
              label: 'CURSE',
              onDelta: (d) => p.adjustCurse(d),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statCard('GUNS', '${player.guns.length}',
                      Icons.gps_fixed, flair.primary, flair),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard('ITEMS', '${player.items.length}',
                      Icons.inventory_2, Colors.amberAccent, flair),
                ),
              ],
            ),
          ] else
            _statCard('GUNS', '${player.guns.length}',
                Icons.gps_fixed, flair.primary, flair),
        ],
      ),
    );
  }

  /// Oval "locket" frame for the character portrait — brass border
  /// with a subtle inner glow.
  Widget _locketFrame(Gungeoneer char, ThemeFlair flair) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            flair.primary.withValues(alpha: 0.15),
            flair.primary.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: flair.primary.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: flair.primary.withValues(alpha: 0.12),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipOval(
          child: Image.asset(
            gungeoneerGifPath(char.name),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.person,
              size: 36,
              color: flair.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, ThemeFlair flair) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          GoopText(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          GoopText(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ---- Right page: guns / items / synergies (swipeable) -------------

  Widget _rightPage(
    Player player,
    RunProvider p,
    ThemeFlair flair,
    Map<String, Color> glowColors,
    ({String name, double dps}) topDps,
    int activeSynergies,
    int partialSynergies,
  ) {
    final guns = player.guns;
    final items = player.items;

    return PageView(
      controller: _pageController,
      onPageChanged: (i) => setState(() => _currentRightPage = i),
      children: [
        _gunsPage(guns, p, flair, glowColors, topDps),
        _itemsPage(items, p, flair, glowColors),
        if (isMain) _synergiesPage(p, flair, activeSynergies, partialSynergies),
      ],
    );
  }

  Widget _gunsPage(
    List<Gun> guns,
    RunProvider p,
    ThemeFlair flair,
    Map<String, Color> glowColors,
    ({String name, double dps}) topDps,
  ) {
    if (guns.isEmpty) {
      return _emptyPage('No guns yet', Icons.gps_fixed, flair);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: guns.length,
      itemBuilder: (c, i) {
        final g = guns[i];
        final isTop = g.name == topDps.name;
        final glow = glowColors[g.name.toLowerCase()];
        final dps = mh.effectiveDps(g, p);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
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
            child: _codexRow(
              icon: GameIcon(
                assetPath: g.icon,
                fallback: Icons.gps_fixed,
                quality: g.quality,
                size: 28,
                showRing: false,
              ),
              title: g.name,
              subtitle: g.type,
              trailing: '${dps.toStringAsFixed(1)} DPS',
              isTop: isTop,
              glow: glow,
              flair: flair,
            ),
          ),
        );
      },
    );
  }

  Widget _itemsPage(
    List<Item> items,
    RunProvider p,
    ThemeFlair flair,
    Map<String, Color> glowColors,
  ) {
    if (items.isEmpty) {
      return _emptyPage('No items yet', Icons.inventory_2, flair);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (c, i) {
        final it = items[i];
        final glow = glowColors[it.name.toLowerCase()];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
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
            child: _codexRow(
              icon: GameIcon(
                assetPath: it.icon,
                fallback: it.type.toLowerCase() == 'active'
                    ? Icons.flash_on
                    : Icons.inventory_2_outlined,
                quality: it.quality,
                size: 28,
                showRing: false,
              ),
              title: it.name,
              subtitle: it.type,
              trailing: it.rechargeTime.isNotEmpty ? it.rechargeTime : '',
              isTop: false,
              glow: glow,
              flair: flair,
            ),
          ),
        );
      },
    );
  }

  Widget _synergiesPage(
    RunProvider p,
    ThemeFlair flair,
    int activeCount,
    int partialCount,
  ) {
    final active = p.getActiveSynergies();
    final partial = p.getPartialSynergies();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _synergyHeader('ACTIVE', activeCount, flair.primary, flair),
        const SizedBox(height: 8),
        if (active.isEmpty)
          _emptyPage('No active synergies', Icons.link, flair)
        else
          ...active.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _synergyRow(s.name, s.items.length, flair.primary, flair),
              )),
        const SizedBox(height: 16),
        _synergyHeader('PARTIAL', partialCount, Colors.amberAccent, flair),
        const SizedBox(height: 8),
        if (partial.isEmpty)
          _emptyPage('No partial synergies', Icons.link_off, flair)
        else
          ...partial.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _synergyRow(s.name, s.items.length, Colors.amberAccent, flair),
              )),
      ],
    );
  }

  Widget _synergyHeader(String label, int count, Color color, ThemeFlair flair) {
    return Row(
      children: [
        GoopText(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: GoopText(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _synergyRow(String name, int itemCount, Color color, ThemeFlair flair) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.link, size: 14, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: GoopText(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GoopText(
            '$itemCount',
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.6),
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  // ---- Row card -------------------------------------------------------

  Widget _codexRow({
    required Widget icon,
    required String title,
    required String subtitle,
    required String trailing,
    required bool isTop,
    required Color? glow,
    required ThemeFlair flair,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1815),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTop
              ? Colors.amberAccent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
          width: isTop ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 28, height: 28, child: icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isTop ? Colors.amberAccent : Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  GoopText(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (trailing.isNotEmpty)
            GoopText(
              trailing,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: flair.primary.withValues(alpha: 0.8),
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  // ---- Page turn bar (bottom chevrons) --------------------------------

  Widget _pageTurnBar(ThemeFlair flair) {
    final pages = isMain ? 3 : 2;
    final labels = isMain
        ? ['GUNS', 'ITEMS', 'SYNERGIES']
        : ['GUNS', 'ITEMS'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border(top: BorderSide(color: flair.primary.withValues(alpha: 0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left_rounded, size: 20, color: flair.primary),
            onPressed: _currentRightPage > 0 ? () => _goToPage(_currentRightPage - 1) : null,
            tooltip: 'Previous page',
          ),
          Row(
            children: List.generate(pages, (i) {
              final active = i == _currentRightPage;
              return GestureDetector(
                onTap: () => _goToPage(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: active
                        ? flair.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GoopText(
                    labels[i],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: active
                          ? flair.primary
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              );
            }),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded, size: 20, color: flair.primary),
            onPressed: _currentRightPage < pages - 1 ? () => _goToPage(_currentRightPage + 1) : null,
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }

  // ---- Misc helpers ---------------------------------------------------

  Widget _bookSpine(ThemeFlair flair, {bool horizontal = false}) {
    if (horizontal) {
      return Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              flair.primary.withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
      );
    }
    return Container(
      width: 2,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            flair.primary.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  BoxDecoration _bookBackground(ThemeFlair flair) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1E1A14), // warm parchment-dark
          const Color(0xFF15120E),
        ],
      ),
    );
  }

  Widget _emptyPage(String message, IconData icon, ThemeFlair flair) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          GoopText(
            message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
