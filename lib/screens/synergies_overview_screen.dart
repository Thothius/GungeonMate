import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../widgets/game_icon.dart';
import 'item_detail_screen.dart';

class SynergiesOverviewScreen extends StatefulWidget {
  const SynergiesOverviewScreen({super.key});

  @override
  State<SynergiesOverviewScreen> createState() =>
      _SynergiesOverviewScreenState();
}

class _SynergiesOverviewScreenState extends State<SynergiesOverviewScreen> {
  bool _onlyActive = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final all = p.getSynergiesByInventory();
    final filtered = all
        .map((group) {
          final entries = _onlyActive
              ? group.entries.where((e) => e.active).toList()
              : group.entries;
          return ItemSynergies(
            itemName: group.itemName,
            isGun: group.isGun,
            entries: entries,
          );
        })
        .where((g) => g.entries.isNotEmpty)
        .toList();

    final activeCount = all.fold<int>(
      0,
      (sum, g) => sum + g.entries.where((e) => e.active).length,
    );

    return Scaffold(
      appBar: AppBar(
        // No screen title — the inline summary banner below already
        // labels the section ("N active synergies across your run").
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_onlyActive ? 'Active only' : 'All'),
              selected: _onlyActive,
              onSelected: (v) => setState(() => _onlyActive = v),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.amber.withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(Icons.hub, color: Colors.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$activeCount active synergies across your run',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No synergies for current inventory.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: filtered.length,
                    itemBuilder: (c, i) =>
                        _ItemGroupCard(group: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ItemGroupCard extends StatelessWidget {
  final ItemSynergies group;
  const _ItemGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final activeCount = group.entries.where((e) => e.active).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: activeCount > 0,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        leading: Icon(
          group.isGun ? Icons.gps_fixed : Icons.inventory_2_outlined,
          color: Colors.white70,
        ),
        title: Text(
          group.itemName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${group.entries.length} synergies'
          '${activeCount > 0 ? '  •  $activeCount active' : ''}',
          style: TextStyle(
            color: activeCount > 0
                ? Colors.amber
                : Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        children: group.entries.map((s) => _SynergyRow(status: s)).toList(),
      ),
    );
  }
}

class _SynergyRow extends StatelessWidget {
  final SynergyStatus status;
  const _SynergyRow({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.synergy;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: status.active
            ? Colors.amber.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: status.active
              ? Colors.amber.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status.active
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 15,
                color: status.active ? Colors.amber : Colors.white54,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  s.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (!status.active)
                Text(
                  'needs ${status.missing.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
            ],
          ),
          if (status.missing.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: status.missing
                  .map((m) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          m,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
          if (s.anyOf.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.alt_route,
                  size: 13,
                  color: Colors.amber.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 4),
                Text(
                  'Alternative Partners:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.amber.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _AnyOfChips(names: s.anyOf),
          ],
          if (s.prettyEffect.isNotEmpty &&
              !s.effect.toLowerCase().startsWith('one of the following') &&
              !s.effect.toLowerCase().startsWith('any of the following')) ...[
            const SizedBox(height: 6),
            Text(
              s.prettyEffect,
              style: const TextStyle(fontSize: 12.5, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact row of image+name chips representing the alternatives of an
/// "any_of" synergy. Each chip is tappable when its name resolves to a
/// real gun/item in master data.
class _AnyOfChips extends StatelessWidget {
  final List<String> names;
  const _AnyOfChips({required this.names});

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();
    final owned = p.currentOwnedLower;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: names.map((n) {
        final r = p.entityByName(n);
        final gun = r.gun;
        final item = r.item;
        final resolvable = gun != null || item != null;
        final isOwned = owned.contains(n.toLowerCase());
        final iconPath = gun?.icon ?? item?.icon ?? '';
        final quality = gun?.quality ?? item?.quality ?? '';

        final body = Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isOwned
                ? Colors.amber.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOwned
                  ? Colors.amber.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (resolvable && iconPath.isNotEmpty) ...[
                Opacity(
                  opacity: isOwned ? 1.0 : 0.55,
                  child: GameIcon(
                    assetPath: iconPath,
                    fallback: gun != null
                        ? Icons.gps_fixed
                        : Icons.inventory_2_outlined,
                    quality: quality,
                    size: 18,
                    showRing: false,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                n,
                style: TextStyle(
                  fontSize: 12,
                  color: isOwned ? Colors.white : Colors.white70,
                ),
              ),
              if (resolvable) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right,
                  size: 13,
                  color: isOwned ? Colors.amber : Colors.white38,
                ),
              ],
            ],
          ),
        );

        if (!resolvable) return body;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(gun: gun, item: item),
              ),
            ),
            child: body,
          ),
        );
      }).toList(),
    );
  }
}
