import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/player.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';
import 'robot_dashboard.dart';
import 'junkan_dashboard.dart';
import 'special_gun_dashboards.dart';
import 'huntress_dashboard.dart';
import 'compact_dashboards.dart';

// Special Dashboard Swiper ΓÇö AnimatedSwitcher carousel for all active special dashboards
// =============================================================================

class DashboardSwiper extends StatefulWidget {
  final PlayerSlot slot;
  const DashboardSwiper({super.key, required this.slot});

  @override
  State<DashboardSwiper> createState() => DashboardSwiperState();
}

class DashboardSwiperState extends State<DashboardSwiper> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = widget.slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
    if (player == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final ownedGunNames = player.guns.map((g) => g.name.toLowerCase()).toSet();
    final ownedItemNames = player.items.map((i) => i.name.toLowerCase()).toSet();
    final charName = player.character?.name.toLowerCase() ?? '';

    // Build list of active dashboards
    final dashboards = <Widget>[];
    final labels = <String>[];

    if (charName.contains('robot')) {
      dashboards.add(const RobotDashboardSliver());
      labels.add('ROBOT');
    }
    if (charName.contains('hunter')) {
      dashboards.add(const HuntressDashboardSliver());
      labels.add('HUNTRESS');
    }
    if (ownedItemNames.any((n) => n.contains('ser junkan'))) {
      dashboards.add(JunkanDashboardSliver(slot: widget.slot));
      labels.add('JUNKAN');
    }
    if (ownedGunNames.contains('gunderfury')) {
      dashboards.add(GunderfuryDashboardSliver(slot: widget.slot));
      labels.add('GUNDERFURY');
    }
    if (ownedGunNames.contains('triple gun')) {
      dashboards.add(TripleGunDashboardSliver(slot: widget.slot));
      labels.add('TRIPLE GUN');
    }
    if (ownedGunNames.contains('evolver')) {
      dashboards.add(EvolverDashboardSliver(slot: widget.slot));
      labels.add('EVOLVER');
    }
    if (ownedGunNames.contains('shellegun')) {
      dashboards.add(ShellegunDashboard(slot: widget.slot));
      labels.add('SHELLEGUN');
    }
    if (ownedGunNames.contains('chamber gun')) {
      dashboards.add(ChamberGunDashboard(slot: widget.slot));
      labels.add('CHAMBER GUN');
    }
    if (ownedItemNames.contains('platinum bullets')) {
      dashboards.add(PlatinumBulletsDashboard(slot: widget.slot));
      labels.add('PLATINUM');
    }
    if (ownedItemNames.contains('iron coin')) {
      dashboards.add(IronCoinDashboard(slot: widget.slot));
      labels.add('IRON COIN');
    }
    if (ownedItemNames.contains('spice')) {
      dashboards.add(SpiceDashboard(slot: widget.slot));
      labels.add('SPICE');
    }
    if (ownedItemNames.contains('metronome')) {
      dashboards.add(MetronomeDashboard(slot: widget.slot));
      labels.add('METRONOME');
    }
    if (ownedItemNames.contains('sprun')) {
      dashboards.add(SprunDashboard(slot: widget.slot));
      labels.add('SPRUN');
    }
    if (ownedGunNames.contains('boxing glove')) {
      dashboards.add(BoxingGloveDashboard(slot: widget.slot));
      labels.add('BOXING');
    }
    if (ownedItemNames.contains('cigarettes')) {
      dashboards.add(CigarettesDashboard(slot: widget.slot));
      labels.add('CIGARETTES');
    }
    if (ownedGunNames.contains('polaris')) {
      dashboards.add(PolarisDashboard(slot: widget.slot));
      labels.add('POLARIS');
    }
    if (ownedGunNames.contains('gunther')) {
      dashboards.add(GuntherDashboard(slot: widget.slot));
      labels.add('GUNTHER');
    }
    if (ownedItemNames.contains('gun soul')) {
      dashboards.add(GunSoulDashboard(slot: widget.slot));
      labels.add('GUN SOUL');
    }
    if (dashboards.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    // Clamp page index
    if (_page >= dashboards.length) _page = 0;

    // Render each dashboard sliver at its full content height ΓÇö no
    // internal scrolling, no fixed height. shrinkWrap sizes to content;
    // NeverScrollableScrollPhysics prevents nested scroll jank.
    Widget dashboardChild(Widget sliver) {
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
      child: Column(
        children: [
          // Dashboard content ΓÇö height scales to content, no fixed height.
          GestureDetector(
            onHorizontalDragEnd: (details) {
              final v = details.primaryVelocity ?? 0;
              if (v < -200 && _page < dashboards.length - 1) {
                setState(() => _page++);
                Haptics.selection();
              } else if (v > 200 && _page > 0) {
                setState(() => _page--);
                Haptics.selection();
              }
            },
            child: KeyedSubtree(
              key: ValueKey(_page),
              child: dashboardChild(dashboards[_page]),
            ),
          ),
          const SizedBox(height: 6),
          // Dot indicators (tappable) + label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < dashboards.length; i++)
                GestureDetector(
                  onTap: () {
                    setState(() => _page = i);
                    Haptics.selection();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? Colors.lightGreenAccent : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GoopText(
            labels.isNotEmpty && _page < labels.length ? labels[_page] : '',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white54, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
