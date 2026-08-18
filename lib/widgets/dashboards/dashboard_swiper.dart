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

// Special Dashboard Tab System — swipeable panels with tappable tab chips
// =============================================================================

class _DashboardTab {
  final String label;
  final String iconPath;
  final Color color;
  final Widget widget;
  const _DashboardTab({
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
  if (ownedGunNames.contains('triple gun')) return true;
  if (ownedGunNames.contains('evolver')) return true;
  if (ownedGunNames.contains('shellegun')) return true;
  if (ownedGunNames.contains('chamber gun')) return true;
  if (ownedItemNames.contains('platinum bullets')) return true;
  if (ownedItemNames.contains('iron coin')) return true;
  if (ownedItemNames.contains('spice')) return true;
  if (ownedItemNames.contains('metronome')) return true;
  if (ownedItemNames.contains('sprun')) return true;
  if (ownedGunNames.contains('boxing glove')) return true;
  if (ownedItemNames.contains('cigarettes')) return true;
  if (ownedGunNames.contains('polaris')) return true;
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

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = widget.slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
    if (player == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final ownedGunNames = player.guns.map((g) => g.name.toLowerCase()).toSet();
    final ownedItemNames = player.items.map((i) => i.name.toLowerCase()).toSet();
    final charName = player.character?.name.toLowerCase() ?? '';

    final tabs = <_DashboardTab>[];

    if (charName.contains('robot')) {
      tabs.add(_DashboardTab(
        label: 'Robot',
        iconPath: localGungeoneerIcon('The Robot'),
        color: Colors.greenAccent,
        widget: const RobotDashboardSliver(),
      ));
    }
    if (charName.contains('hunter')) {
      tabs.add(_DashboardTab(
        label: 'Huntress',
        iconPath: localGungeoneerIcon('The Hunter'),
        color: Colors.amberAccent,
        widget: const HuntressDashboardSliver(),
      ));
    }
    if (ownedItemNames.any((n) => n.contains('ser junkan'))) {
      tabs.add(_DashboardTab(
        label: 'Junkan',
        iconPath: localItemIcon('Ser Junkan'),
        color: Colors.tealAccent,
        widget: JunkanDashboardSliver(slot: widget.slot),
      ));
    }
    if (ownedGunNames.contains('gunderfury')) {
      tabs.add(_DashboardTab(
        label: 'Gunderfury',
        iconPath: localGunIcon('Gunderfury'),
        color: Colors.purpleAccent,
        widget: GunderfuryDashboardSliver(slot: widget.slot),
      ));
    }
    if (ownedGunNames.contains('triple gun')) {
      tabs.add(_DashboardTab(
        label: 'Triple Gun',
        iconPath: localGunIcon('Triple Gun'),
        color: Colors.blueAccent,
        widget: TripleGunDashboardSliver(slot: widget.slot),
      ));
    }
    if (ownedGunNames.contains('evolver')) {
      tabs.add(_DashboardTab(
        label: 'Evolver',
        iconPath: localGunIcon('Evolver'),
        color: Colors.greenAccent,
        widget: EvolverDashboardSliver(slot: widget.slot),
      ));
    }
    if (ownedGunNames.contains('shellegun')) {
      tabs.add(_DashboardTab(
        label: 'Shellegun',
        iconPath: localGunIcon('Shellegun'),
        color: Colors.cyanAccent,
        widget: ShellegunDashboard(slot: widget.slot),
      ));
    }
    if (ownedGunNames.contains('chamber gun')) {
      tabs.add(_DashboardTab(
        label: 'Chamber Gun',
        iconPath: localGunIcon('Chamber Gun'),
        color: Colors.amberAccent,
        widget: ChamberGunDashboard(slot: widget.slot),
      ));
    }
    if (ownedItemNames.contains('platinum bullets')) {
      tabs.add(_DashboardTab(
        label: 'Platinum',
        iconPath: localItemIcon('Platinum Bullets'),
        color: Colors.white70,
        widget: PlatinumBulletsDashboard(slot: widget.slot),
      ));
    }
    if (ownedItemNames.contains('iron coin')) {
      tabs.add(_DashboardTab(
        label: 'Iron Coin',
        iconPath: localItemIcon('Iron Coin'),
        color: Colors.amber,
        widget: IronCoinDashboard(slot: widget.slot),
      ));
    }
    if (ownedItemNames.contains('spice')) {
      tabs.add(_DashboardTab(
        label: 'Spice',
        iconPath: localItemIcon('Spice'),
        color: Colors.redAccent,
        widget: SpiceDashboard(slot: widget.slot),
      ));
    }
    if (ownedItemNames.contains('metronome')) {
      tabs.add(_DashboardTab(
        label: 'Metronome',
        iconPath: localItemIcon('Metronome'),
        color: Colors.purpleAccent,
        widget: MetronomeDashboard(slot: widget.slot),
      ));
    }
    if (ownedItemNames.contains('sprun')) {
      tabs.add(_DashboardTab(
        label: 'Sprun',
        iconPath: localItemIcon('Sprun'),
        color: Colors.cyanAccent,
        widget: SprunDashboard(slot: widget.slot),
      ));
    }
    if (ownedGunNames.contains('boxing glove')) {
      tabs.add(_DashboardTab(
        label: 'Boxing Glove',
        iconPath: localGunIcon('Boxing Glove'),
        color: Colors.redAccent,
        widget: BoxingGloveDashboard(slot: widget.slot),
      ));
    }
    if (ownedItemNames.contains('cigarettes')) {
      tabs.add(_DashboardTab(
        label: 'Cigarettes',
        iconPath: localItemIcon('Cigarettes'),
        color: Colors.orangeAccent,
        widget: CigarettesDashboard(slot: widget.slot),
      ));
    }
    if (ownedGunNames.contains('polaris')) {
      tabs.add(_DashboardTab(
        label: 'Polaris',
        iconPath: localGunIcon('Polaris'),
        color: Colors.blueAccent,
        widget: PolarisDashboard(slot: widget.slot),
      ));
    }
    if (ownedGunNames.contains('gunther')) {
      tabs.add(_DashboardTab(
        label: 'Gunther',
        iconPath: localGunIcon('Gunther'),
        color: Colors.purpleAccent,
        widget: GuntherDashboard(slot: widget.slot),
      ));
    }
    if (ownedItemNames.contains('gun soul')) {
      tabs.add(_DashboardTab(
        label: 'Gun Soul',
        iconPath: localItemIcon('Gun Soul'),
        color: Colors.greenAccent,
        widget: GunSoulDashboard(slot: widget.slot),
      ));
    }

    if (tabs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    // Clamp selectedIndex if dashboards changed
    if (_selectedIndex >= tabs.length) _selectedIndex = 0;

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

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.flair.scaffold.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),

          ),
          child: Column(
            children: [
              // Tab row — fat tappable chips, up to 3 per row before wrapping
              Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(tabs.length, (i) {
                    final tab = tabs[i];
                    final isActive = i == _selectedIndex;
                    return _DashboardTabChip(
                      tab: tab,
                      isActive: isActive,
                      onTap: () {
                        Haptics.selection();
                        setState(() => _selectedIndex = i);
                      },
                    );
                  }),
                ),
              ),
              // Content panel — sizes to current tab's content, no scroll.
              // AnimatedSwitcher cross-fades between tabs.
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: KeyedSubtree(
                    key: ValueKey(_selectedIndex),
                    child: extractChild(tabs[_selectedIndex].widget),
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

class _DashboardTabChip extends StatelessWidget {
  final _DashboardTab tab;
  final bool isActive;
  final VoidCallback onTap;
  const _DashboardTabChip({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = tab.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.7)
                : color.withValues(alpha: 0.25),
            width: isActive ? 1.4 : 0.8,
          ),
          boxShadow: isActive
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
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.dashboard_outlined,
                  size: 16,
                  color: color,
                ),
              )
            else
              Icon(Icons.dashboard_outlined, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? color
                    : color.withValues(alpha: 0.6),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
