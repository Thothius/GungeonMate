import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';
import '../../utils/asset_paths.dart';
import '../../utils/fast_route.dart';
import '../quality_badge.dart';

class DebugTab extends StatelessWidget {
  const DebugTab({super.key});

  // Names exactly matching _DashboardSwiper trigger conditions.
  static const _specialGunNames = [
    'Gunderfury', 'Triple Gun', 'Evolver', 'Shellegun',
    'Chamber Gun', 'Boxing Glove', 'Polaris', 'Gunther',
  ];
  static const _specialItemNames = [
    'Ser Junkan', 'Platinum Bullets', 'Iron Coin', 'Spice',
    'Metronome', 'Sprun', 'Cigarettes', 'Gun Soul',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final hasRun = p.runState.main.character != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(Icons.bug_report_rounded, size: 48, color: Colors.greenAccent.withValues(alpha: 0.6)),
        const SizedBox(height: 12),
        const GoopText(
          'DEBUG MODE',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.greenAccent),
        ),
        const SizedBox(height: 6),
        GoopText(
          'Testing tools for dashboards and special item interactions.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
        ),
        const SizedBox(height: 24),
        _utilTile(
          context,
          icon: Icons.grid_view_rounded,
          title: 'Special Items & Guns',
          subtitle: 'Spawn all 18 dashboard-triggering items/guns into your inventory',
          onTap: hasRun
              ? () {
                  Haptics.selection();
                  Navigator.push(context, fastRoute(const SpecialItemsGridScreen()));
                }
              : null,
        ),
        if (!hasRun) ...[
          const SizedBox(height: 12),
          GoopText(
            'Start a run first to use debug tools.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.orangeAccent.withValues(alpha: 0.7)),
          ),
        ],
      ],
    );
  }

  Widget _utilTile(BuildContext context, {required IconData icon, required String title, required String subtitle, VoidCallback? onTap}) {
    return Card(
      color: Colors.white.withValues(alpha: 0.03),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: Colors.greenAccent, size: 22),
        title: GoopText(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: GoopText(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
        trailing: Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3), size: 20),
        onTap: onTap,
      ),
    );
  }
}

// =============================================================================
// Special Items Grid GÇö 4-column picker with add/remove + Add All
// =============================================================================

class SpecialItemsGridScreen extends StatefulWidget {
  const SpecialItemsGridScreen({super.key});

  @override
  State<SpecialItemsGridScreen> createState() => SpecialItemsGridScreenState();
}

class SpecialItemsGridScreenState extends State<SpecialItemsGridScreen> {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = p.runState.main;
    final ownedGunNames = player.guns.map((g) => g.name.toLowerCase()).toSet();
    final ownedItemNames = player.items.map((i) => i.name.toLowerCase()).toSet();

    final entries = <_SpecialEntry>[];

    for (final name in DebugTab._specialGunNames) {
      final gun = p.gunByName(name);
      entries.add(_SpecialEntry(
        name: name,
        isGun: true,
        owned: ownedGunNames.contains(name.toLowerCase()),
        iconPath: gun?.icon ?? localGunIcon(name),
        quality: gun?.quality ?? '',
      ));
    }
    for (final name in DebugTab._specialItemNames) {
      final item = p.itemByName(name);
      entries.add(_SpecialEntry(
        name: name,
        isGun: false,
        owned: ownedItemNames.contains(name.toLowerCase()),
        iconPath: item?.icon ?? localItemIcon(name),
        quality: item?.quality ?? '',
      ));
    }

    final allOwned = entries.every((e) => e.owned);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E22),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const GoopText('SPECIAL ITEMS & GUNS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Haptics.selection();
              if (allOwned) {
                for (final name in DebugTab._specialGunNames) {
                  final gun = p.gunByName(name);
                  if (gun != null && ownedGunNames.contains(name.toLowerCase())) {
                    p.removeGun(gun, force: true);
                  }
                }
                for (final name in DebugTab._specialItemNames) {
                  final item = p.itemByName(name);
                  if (item != null && ownedItemNames.contains(name.toLowerCase())) {
                    p.removeItem(item, force: true);
                  }
                }
              } else {
                for (final name in DebugTab._specialGunNames) {
                  final gun = p.gunByName(name);
                  if (gun != null && !ownedGunNames.contains(name.toLowerCase())) {
                    p.addGun(gun, force: true);
                  }
                }
                for (final name in DebugTab._specialItemNames) {
                  final item = p.itemByName(name);
                  if (item != null && !ownedItemNames.contains(name.toLowerCase())) {
                    p.addItem(item, force: true);
                  }
                }
              }
            },
            icon: Icon(allOwned ? Icons.remove_circle : Icons.add_circle, size: 18, color: Colors.greenAccent),
            label: GoopText(
              allOwned ? 'Remove All' : 'Add All',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.greenAccent),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.82,
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final e = entries[index];
          return _SpecialGridTile(
            entry: e,
            onTap: () {
              Haptics.light();
              if (e.owned) {
                if (e.isGun) {
                  final gun = p.gunByName(e.name);
                  if (gun != null) p.removeGun(gun, force: true);
                } else {
                  final item = p.itemByName(e.name);
                  if (item != null) p.removeItem(item, force: true);
                }
              } else {
                if (e.isGun) {
                  final gun = p.gunByName(e.name);
                  if (gun != null) p.addGun(gun, force: true);
                } else {
                  final item = p.itemByName(e.name);
                  if (item != null) p.addItem(item, force: true);
                }
              }
            },
          );
        },
      ),
    );
  }
}

class _SpecialEntry {
  final String name;
  final bool isGun;
  final bool owned;
  final String iconPath;
  final String quality;
  const _SpecialEntry({required this.name, required this.isGun, required this.owned, required this.iconPath, required this.quality});
}

class _SpecialGridTile extends StatelessWidget {
  final _SpecialEntry entry;
  final VoidCallback onTap;
  const _SpecialGridTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = QualityBadge.colorFor(entry.quality);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: entry.owned ? accent.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: entry.owned ? accent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
            width: entry.owned ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    entry.iconPath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      entry.isGun ? Icons.gps_fixed : Icons.star,
                      color: Colors.white24,
                      size: 20,
                    ),
                  ),
                ),
                if (entry.owned)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      child: const Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GoopText(
              entry.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: entry.owned ? accent : Colors.white.withValues(alpha: 0.5),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
