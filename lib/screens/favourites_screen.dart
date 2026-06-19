import 'package:flutter/material.dart';
import '../services/goop_talk_engine.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../widgets/periodic_tile.dart';
import 'item_detail_screen.dart';
import '../services/app_theme.dart';

/// Quick-access view for guns/items the user has starred. Shared across
/// runs and both players.
class FavouritesScreen extends StatelessWidget {
  /// When true, the screen is rendered inside the bottom-nav IndexedStack
  /// so we suppress the back arrow on the AppBar.
  final bool embedded;
  const FavouritesScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final guns = p.favouriteGuns;
    final items = p.favouriteItems;
    final total = guns.length + items.length;

    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        final flair = AppTheme.flair;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: !embedded,
            // No screen title — the bottom-nav heart icon + section
            // headers below already say "Favourites". The count moves
            // into a quiet leading badge so it's still glanceable.
            titleSpacing: 0,
            title: total == 0
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '$total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
            actions: [
              if (total > 0)
                IconButton(
                  tooltip: 'Reset favourites',
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () => _confirmReset(context, p),
                ),
            ],
          ),
          body: total == 0
              ? _EmptyState(flair: flair, prefs: prefs)
              : CustomScrollView(
                  slivers: [
                    if (guns.isNotEmpty) ...[
                      _SectionHeaderSliver(
                        title: 'Guns',
                        count: guns.length,
                        icon: Icons.gps_fixed,
                        flair: flair,
                        prefs: prefs,
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        sliver: SliverGrid.builder(
                          gridDelegate: _grid(context),
                          itemCount: guns.length,
                          itemBuilder: (c, i) {
                            final g = guns[i];
                            return PeriodicTile(
                              gun: g,
                              onTap: () => Navigator.push(
                                c,
                                MaterialPageRoute(
                                  builder: (_) => ItemDetailScreen(gun: g),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (items.isNotEmpty) ...[
                      _SectionHeaderSliver(
                        title: 'Items',
                        count: items.length,
                        icon: Icons.inventory_2_outlined,
                        flair: flair,
                        prefs: prefs,
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        sliver: SliverGrid.builder(
                          gridDelegate: _grid(context),
                          itemCount: items.length,
                          itemBuilder: (c, i) {
                            final it = items[i];
                            return PeriodicTile(
                              item: it,
                              onTap: () => Navigator.push(
                                c,
                                MaterialPageRoute(
                                  builder: (_) => ItemDetailScreen(item: it),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  SliverGridDelegate _grid(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final displayMode = VisualPrefs.notifier.value.inventoryDisplayMode;

    int cross;
    double ratio;

    switch (displayMode) {
      case InventoryDisplayMode.classicPeriodic:
        final savedColCount = VisualPrefs.notifier.value.periodicGridColumnCount;
        cross = (savedColCount > 0) ? savedColCount : (w < 360 ? 3 : w < 600 ? 4 : 6);
        ratio = 0.80;
        break;
      case InventoryDisplayMode.tacticalStats:
        cross = w < 500 ? 2 : w < 850 ? 3 : 5;
        ratio = 1.6;
        break;
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cross,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: ratio,
    );
  }

  void _confirmReset(BuildContext context, RunProvider p) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Reset favourites?'),
        content: Text(
            'This clears all ${p.favouritesCount} favourited items and guns. Can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              p.resetFavourites();
              Navigator.pop(c);
              // Guard against a pathological case where the host
              // screen is torn down mid-tap (e.g. tab switch racing
              // the dialog dismissal). `context` here is the screen
              // context, not the dialog's, so we have to verify it.
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Favourites cleared'),
                  duration: Duration(milliseconds: 1200),
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeFlair flair;
  final VisualPrefs prefs;

  const _EmptyState({required this.flair, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: flair.primary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 16),
            GoopText(
              'No favourites yet',
              style: prefs.font.textStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the ♥ heart on any gun/item detail to star it. Your favourites show up here for quick access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.65),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeaderSliver extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final ThemeFlair flair;
  final VisualPrefs prefs;

  const _SectionHeaderSliver({
    required this.title,
    required this.count,
    required this.icon,
    required this.flair,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: flair.primary),
            const SizedBox(width: 8),
            GoopText(
              title.toUpperCase(),
              style: prefs.font.textStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: flair.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: flair.primary.withValues(alpha: 0.25)),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
