import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/player.dart';
import '../../utils/asset_paths.dart';
import '../../services/app_theme.dart';
import '../../services/haptics.dart';
import 'robot_dashboard.dart';
import 'junkan_dashboard.dart';
import 'special_gun_dashboards.dart';
import 'huntress_dashboard.dart';
import 'compact_dashboards.dart';
import '../../services/goop_talk_engine.dart';
import '../../utils/responsive.dart';

import '../../theme/tokens.dart';

// Special Dashboard Tab System — swipeable panels with tappable tab chips
// =============================================================================

class DashboardTab {
  final String label;
  final String iconPath;
  final Color color;
  final Widget widget;
  const DashboardTab({
    required this.label,
    required this.iconPath,
    required this.color,
    required this.widget,
  });
}

class DashboardSwiper extends StatelessWidget {
  final PlayerSlot slot;
  const DashboardSwiper({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player =
        slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
    if (player == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final tabs = buildDashboardTabs(player, slot);

    if (tabs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    // The sliver shell unwraps to a plain box so the header panel can
    // embed the whole swiper card (pills + expanding detail) — solo run
    // shows it inside the top panel; MP keeps it in the sliver slot.
    // Selection/collapse state lives inside DashboardSwiperCardBody so
    // both embed paths share one implementation (U-046).
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
        child: DashboardSwiperCardBody(tabs: tabs),
      ),
    );
  }
}

/// Builds the ordered dashboard tab list for a player — every owned
/// special item/gun/character tracker. Shared by the sliver path and
/// the embedded [DashboardSwiperCard].
List<DashboardTab> buildDashboardTabs(Player player, PlayerSlot slot) {
  final ownedGunNames = player.guns.map((g) => g.name.toLowerCase()).toSet();
  final ownedItemNames = player.items.map((i) => i.name.toLowerCase()).toSet();
  final charName = player.character?.name.toLowerCase() ?? '';

  final tabs = <DashboardTab>[];

  if (charName.contains('robot')) {
    tabs.add(
      DashboardTab(
        label: 'Robot',
        iconPath: localGungeoneerIcon('The Robot'),
        color: Colors.greenAccent,
        widget: const RobotDashboardSliver(),
      ),
    );
  }
  if (charName.contains('hunter')) {
    tabs.add(
      DashboardTab(
        label: 'Huntress',
        iconPath: localGungeoneerIcon('The Hunter'),
        color: Colors.amberAccent,
        widget: HuntressDashboardSliver(slot: slot),
      ),
    );
  }
  if (ownedItemNames.any((n) => n.contains('ser junkan'))) {
    tabs.add(
      DashboardTab(
        label: 'Junkan',
        iconPath: localItemIcon('Ser Junkan 1'),
        color: Colors.tealAccent,
        widget: JunkanDashboardSliver(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('gunderfury')) {
    tabs.add(
      DashboardTab(
        label: 'Gunderfury',
        iconPath: localGunIcon('Gunderfury'),
        color: Colors.purpleAccent,
        widget: GunderfuryDashboardSliver(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('triple gun')) {
    tabs.add(
      DashboardTab(
        label: 'Triple Gun',
        iconPath: localGunIcon('Triple Gun'),
        color: Colors.blueAccent,
        widget: TripleGunDashboardSliver(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('evolver')) {
    tabs.add(
      DashboardTab(
        label: 'Evolver',
        iconPath: localGunIcon('Evolver'),
        color: Colors.greenAccent,
        widget: EvolverDashboardSliver(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('shellegun')) {
    tabs.add(
      DashboardTab(
        label: 'Shellegun',
        iconPath: localGunIcon('Shellegun'),
        color: Colors.cyanAccent,
        widget: ShellegunDashboard(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('chamber gun')) {
    tabs.add(
      DashboardTab(
        label: 'Chamber Gun',
        iconPath: localGunIcon('Chamber Gun'),
        color: Colors.amberAccent,
        widget: ChamberGunDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('platinum bullets')) {
    tabs.add(
      DashboardTab(
        label: 'Platinum',
        iconPath: localItemIcon('Platinum Bullets'),
        color: Colors.white70,
        widget: PlatinumBulletsDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('iron coin')) {
    tabs.add(
      DashboardTab(
        label: 'Iron Coin',
        iconPath: localItemIcon('Iron Coin'),
        color: Colors.amber,
        widget: IronCoinDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('spice')) {
    tabs.add(
      DashboardTab(
        label: 'Spice',
        iconPath: localItemIcon('Spice'),
        color: Colors.redAccent,
        widget: SpiceDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('metronome')) {
    tabs.add(
      DashboardTab(
        label: 'Metronome',
        iconPath: localItemIcon('Metronome'),
        color: Colors.purpleAccent,
        widget: MetronomeDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('sprun')) {
    tabs.add(
      DashboardTab(
        label: 'Sprun',
        iconPath: localItemIcon('Sprun'),
        color: Colors.cyanAccent,
        widget: SprunDashboard(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('boxing glove')) {
    tabs.add(
      DashboardTab(
        label: 'Boxing Glove',
        iconPath: localGunIcon('Boxing Glove'),
        color: Colors.redAccent,
        widget: BoxingGloveDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('cigarettes')) {
    tabs.add(
      DashboardTab(
        label: 'Cigarettes',
        iconPath: localItemIcon('Cigarettes'),
        color: Colors.orangeAccent,
        widget: CigarettesDashboard(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('polaris')) {
    tabs.add(
      DashboardTab(
        label: 'Polaris',
        iconPath: localGunIcon('Polaris'),
        color: Colors.lightBlueAccent,
        widget: PolarisDashboard(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('gunther')) {
    tabs.add(
      DashboardTab(
        label: 'Gunther',
        iconPath: localGunIcon('Gunther'),
        color: Colors.purpleAccent,
        widget: GuntherDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('gun soul')) {
    tabs.add(
      DashboardTab(
        label: 'Gun Soul',
        iconPath: localItemIcon('Gun Soul'),
        color: Colors.greenAccent,
        widget: GunSoulDashboard(slot: slot),
      ),
    );
  }

  return tabs;
}

/// The swiper's rendered card — pills row + animated detail panel.
/// Owns selection/collapse state so every embed path (sliver or
/// header-panel card) behaves identically. Extracted so
/// [GungeoneerHeader] can embed it as a footer (solo run puts the
/// trackers inside the top panel instead of a separate one).
class DashboardSwiperCardBody extends StatefulWidget {
  final List<DashboardTab> tabs;
  const DashboardSwiperCardBody({super.key, required this.tabs});

  @override
  State<DashboardSwiperCardBody> createState() =>
      _DashboardSwiperCardBodyState();
}

class _DashboardSwiperCardBodyState extends State<DashboardSwiperCardBody> {
  int _selectedIndex = 0;
  bool _collapsed = false;

  void _onSelect(int i) {
    Haptics.selection();
    setState(() {
      if (i == _selectedIndex) {
        _collapsed = !_collapsed;
      } else {
        _selectedIndex = i;
        _collapsed = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.tabs;
    // Clamp selection if the dashboard set changed under us.
    final selected = _selectedIndex.clamp(0, tabs.length - 1);

    Widget extractChild(Widget sliver) {
      if (sliver is SliverToBoxAdapter && sliver.child != null) {
        return sliver.child!;
      }
      return CustomScrollView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        slivers: [sliver],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.flair.scaffold.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Tab row — fat tappable chips, up to 3 per row before wrapping
          Padding(
            padding: const EdgeInsets.all(6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(tabs.length, (i) {
                final tab = tabs[i];
                final isActive = i == selected;
                return DashboardTabChip(
                  tab: tab,
                  isActive: isActive,
                  isCollapsed: _collapsed,
                  onTap: () => _onSelect(i),
                );
              }),
            ),
          ),
          // Content panel — sizes to current tab's content, no scroll.
          // AnimatedSwitcher cross-fades between tabs.
          // Tapping the active pill toggles _collapsed, which hides
          // the content area while keeping the tab chips visible.
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child:
                _collapsed
                    ? const SizedBox.shrink()
                    : Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey(selected),
                          child: extractChild(tabs[selected].widget),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

class DashboardTabChip extends StatelessWidget {
  final DashboardTab tab;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;
  const DashboardTabChip({
    super.key,
    required this.tab,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = tab.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // Bigger hit target per request — pills are primary controls.
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color:
              isActive
                  ? color.withValues(alpha: 0.18)
                  : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isActive
                    ? color.withValues(alpha: 0.7)
                    : color.withValues(alpha: 0.25),
            width: isActive ? 1.4 : 0.8,
          ),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.12),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tab.iconPath.isNotEmpty)
              Image.asset(
                tab.iconPath,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                cacheWidth: 36,
                cacheHeight: 36,
                errorBuilder:
                    (_, _, _) =>
                        Icon(Icons.dashboard_outlined, size: 16, color: color),
              )
            else
              Icon(Icons.dashboard_outlined, size: 16, color: color),
            const SizedBox(width: 6),
            GoopText(
              tab.label,
              style: TextStyle(
                fontSize: FontSizes.chipStrong * Responsive.factor(context),
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? color : color.withValues(alpha: 0.6),
                letterSpacing: 0.3,
              ),
            ),
            // Show chevron on active pill to indicate collapse/expand state.
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                isCollapsed
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
                size: 14,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Self-contained embeddable swiper card — builds its own tab list from
/// RunProvider. Used when the tracker pills live inside the header panel
/// (solo run) instead of the sliver. Selection/collapse state lives in
/// [DashboardSwiperCardBody], shared with the sliver path (U-046).
class DashboardSwiperCard extends StatelessWidget {
  final PlayerSlot slot;
  const DashboardSwiperCard({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player =
        slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
    if (player == null) return const SizedBox.shrink();

    final tabs = buildDashboardTabs(player, slot);
    if (tabs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: DashboardSwiperCardBody(tabs: tabs),
    );
  }
}
