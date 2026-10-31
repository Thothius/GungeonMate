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
import '../skeuo/skeuo_tokens.dart';

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

/// Checks whether the given player has any special dashboards to show.
/// Mirrors the tab-building logic in [_DashboardSwiperState.build] so
/// the Panels toggle can proactively warn "No panels" instead of
/// silently toggling on an empty section.
bool hasSpecialDashboards({
  required Set<String> ownedGunNames,
  required Set<String> ownedItemNames,
  required String charName,
}) {
  if (charName.contains('robot')) return true;
  if (charName.contains('hunter')) return true;
  if (ownedItemNames.any((n) => n.contains('ser junkan'))) return true;
  if (ownedGunNames.contains('gunderfury')) return true;
  if (ownedGunNames.contains('evolver')) return true;
  if (ownedItemNames.contains('platinum bullets')) return true;
  if (ownedItemNames.contains('iron coin')) return true;
  if (ownedItemNames.contains('spice')) return true;
  if (ownedItemNames.contains('metronome')) return true;
  if (ownedItemNames.contains('sprun')) return true;
  if (ownedGunNames.contains('boxing glove')) return true;
  if (ownedItemNames.contains('cigarettes')) return true;
  if (ownedGunNames.contains('gunther')) return true;
  if (ownedItemNames.contains('gun soul')) return true;
  return false;
}

class DashboardSwiper extends StatefulWidget {
  final PlayerSlot slot;
  const DashboardSwiper({super.key, required this.slot});

  @override
  State<DashboardSwiper> createState() => _DashboardSwiperState();
}

class _DashboardSwiperState extends State<DashboardSwiper> {
  int _selectedIndex = 0;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player =
        widget.slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
    if (player == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final tabs = buildDashboardTabs(player, widget.slot);

    if (tabs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    // Clamp selectedIndex if dashboards changed
    if (_selectedIndex >= tabs.length) _selectedIndex = 0;

    // The sliver shell unwraps to a plain box so the header panel can
    // embed the whole swiper card (pills + expanding detail) — solo run
    // shows it inside the top panel; MP keeps it in the sliver slot.
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
        child: DashboardSwiperCardBody(
          tabs: tabs,
          selectedIndex: _selectedIndex,
          collapsed: _collapsed,
          onSelect: (i) {
            Haptics.selection();
            if (i == _selectedIndex) {
              setState(() => _collapsed = !_collapsed);
            } else {
              setState(() {
                _selectedIndex = i;
                _collapsed = false;
              });
            }
          },
        ),
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
        color: Skeuo.inkIf(Colors.greenAccent),
        widget: const RobotDashboardSliver(),
      ),
    );
  }
  if (charName.contains('hunter')) {
    tabs.add(
      DashboardTab(
        label: 'Huntress',
        iconPath: localGungeoneerIcon('The Hunter'),
        color: Skeuo.inkIf(Colors.amberAccent),
        widget: const HuntressDashboardSliver(),
      ),
    );
  }
  if (ownedItemNames.any((n) => n.contains('ser junkan'))) {
    tabs.add(
      DashboardTab(
        label: 'Junkan',
        iconPath: localItemIcon('Ser Junkan 1'),
        color: Skeuo.inkIf(Colors.tealAccent),
        widget: JunkanDashboardSliver(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('gunderfury')) {
    tabs.add(
      DashboardTab(
        label: 'Gunderfury',
        iconPath: localGunIcon('Gunderfury'),
        color: Skeuo.inkIf(Colors.purpleAccent),
        widget: GunderfuryDashboardSliver(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('evolver')) {
    tabs.add(
      DashboardTab(
        label: 'Evolver',
        iconPath: localGunIcon('Evolver'),
        color: Skeuo.inkIf(Colors.greenAccent),
        widget: EvolverDashboardSliver(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('platinum bullets')) {
    tabs.add(
      DashboardTab(
        label: 'Platinum',
        iconPath: localItemIcon('Platinum Bullets'),
        color: Skeuo.collapse(Colors.white70),
        widget: PlatinumBulletsDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('iron coin')) {
    tabs.add(
      DashboardTab(
        label: 'Iron Coin',
        iconPath: localItemIcon('Iron Coin'),
        color: Skeuo.inkIf(Colors.amber),
        widget: IronCoinDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('spice')) {
    tabs.add(
      DashboardTab(
        label: 'Spice',
        iconPath: localItemIcon('Spice'),
        color: Skeuo.inkIf(Colors.redAccent),
        widget: SpiceDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('metronome')) {
    tabs.add(
      DashboardTab(
        label: 'Metronome',
        iconPath: localItemIcon('Metronome'),
        color: Skeuo.inkIf(Colors.purpleAccent),
        widget: MetronomeDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('sprun')) {
    tabs.add(
      DashboardTab(
        label: 'Sprun',
        iconPath: localItemIcon('Sprun'),
        color: Skeuo.inkIf(Colors.cyanAccent),
        widget: SprunDashboard(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('boxing glove')) {
    tabs.add(
      DashboardTab(
        label: 'Boxing Glove',
        iconPath: localGunIcon('Boxing Glove'),
        color: Skeuo.inkIf(Colors.redAccent),
        widget: BoxingGloveDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('cigarettes')) {
    tabs.add(
      DashboardTab(
        label: 'Cigarettes',
        iconPath: localItemIcon('Cigarettes'),
        color: Skeuo.inkIf(Colors.orangeAccent),
        widget: CigarettesDashboard(slot: slot),
      ),
    );
  }
  if (ownedGunNames.contains('gunther')) {
    tabs.add(
      DashboardTab(
        label: 'Gunther',
        iconPath: localGunIcon('Gunther'),
        color: Skeuo.inkIf(Colors.purpleAccent),
        widget: GuntherDashboard(slot: slot),
      ),
    );
  }
  if (ownedItemNames.contains('gun soul')) {
    tabs.add(
      DashboardTab(
        label: 'Gun Soul',
        iconPath: localItemIcon('Gun Soul'),
        color: Skeuo.inkIf(Colors.greenAccent),
        widget: GunSoulDashboard(slot: slot),
      ),
    );
  }

  return tabs;
}

/// The swiper's rendered card — pills row + animated detail panel.
/// Extracted so [GungeoneerHeader] can embed it as a footer (solo run
/// puts the trackers inside the top panel instead of a separate one).
class DashboardSwiperCardBody extends StatelessWidget {
  final List<DashboardTab> tabs;
  final int selectedIndex;
  final bool collapsed;
  final void Function(int) onSelect;
  const DashboardSwiperCardBody({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.collapsed,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
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
                final isActive = i == selectedIndex;
                return DashboardTabChip(
                  tab: tab,
                  isActive: isActive,
                  isCollapsed: collapsed,
                  onTap: () => onSelect(i),
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
                collapsed
                    ? const SizedBox.shrink()
                    : Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey(selectedIndex),
                          child: extractChild(tabs[selectedIndex].widget),
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
                fontSize: 12.5 * Responsive.factor(context),
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
/// RunProvider and owns selection/collapse state. Used when the tracker
/// pills live inside the header panel (solo run) instead of the sliver.
class DashboardSwiperCard extends StatefulWidget {
  final PlayerSlot slot;
  const DashboardSwiperCard({super.key, required this.slot});

  @override
  State<DashboardSwiperCard> createState() => _DashboardSwiperCardState();
}

class _DashboardSwiperCardState extends State<DashboardSwiperCard> {
  int _selectedIndex = 0;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player =
        widget.slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
    if (player == null) return const SizedBox.shrink();

    final tabs = buildDashboardTabs(player, widget.slot);
    if (tabs.isEmpty) return const SizedBox.shrink();
    if (_selectedIndex >= tabs.length) _selectedIndex = 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: DashboardSwiperCardBody(
        tabs: tabs,
        selectedIndex: _selectedIndex,
        collapsed: _collapsed,
        onSelect: (i) {
          Haptics.selection();
          if (i == _selectedIndex) {
            setState(() => _collapsed = !_collapsed);
          } else {
            setState(() {
              _selectedIndex = i;
              _collapsed = false;
            });
          }
        },
      ),
    );
  }
}
