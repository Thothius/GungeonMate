import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/player.dart';
import '../services/effect_tagger.dart';

/// Aggregates every passive/active effect currently in a player's (or the
/// team's) loadout into a categorized list. Each tag shows the source
/// items that contribute to it.
class EffectsSummaryScreen extends StatelessWidget {
  /// null = team (combined across both players when co-op is active).
  final PlayerSlot? slot;
  const EffectsSummaryScreen({super.key, this.slot});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final state = p.runState;

    final guns = <dynamic>[];
    final items = <dynamic>[];
    String title;
    if (slot == null) {
      // Team view
      guns.addAll(state.main.guns);
      items.addAll(state.main.items);
      if (state.hasCoop) {
        guns.addAll(state.coop!.guns);
        items.addAll(state.coop!.items);
      }
      title = 'Team Effects';
    } else if (slot == PlayerSlot.main) {
      guns.addAll(state.main.guns);
      items.addAll(state.main.items);
      title = 'Effects · ${state.main.character?.name ?? "P1"}';
    } else {
      final c = state.coop;
      if (c != null) {
        guns.addAll(c.guns);
        items.addAll(c.items);
      }
      title = 'Effects · ${c?.character?.name ?? "P2"}';
    }

    final scan = EffectTagger.scan(
      guns: guns.cast(),
      items: items.cast(),
    );
    final groups = EffectTagger.groupByCategory(scan);
    final totalTags = scan.length;
    final totalSources = scan.values.fold<int>(0, (a, b) => a + b.length);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: scan.isEmpty
          ? _Empty(loadoutEmpty: guns.isEmpty && items.isEmpty)
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _Summary(
                  totalTags: totalTags,
                  totalSources: totalSources,
                  groupCount: groups.length,
                ),
                const SizedBox(height: 12),
                for (final cat in EffectCategory.values)
                  if (groups.containsKey(cat))
                    _CategorySection(
                      category: cat,
                      tags: groups[cat]!,
                      occurrences: scan,
                    ),
              ],
            ),
    );
  }
}

class _Summary extends StatelessWidget {
  final int totalTags;
  final int totalSources;
  final int groupCount;
  const _Summary({
    required this.totalTags,
    required this.totalSources,
    required this.groupCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalTags distinct effects',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$totalSources sources · $groupCount categories',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
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
}

class _Empty extends StatelessWidget {
  final bool loadoutEmpty;
  const _Empty({required this.loadoutEmpty});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              loadoutEmpty
                  ? 'No loadout yet — pick up some stuff'
                  : 'Nothing detected in current effects text',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final EffectCategory category;
  final List<EffectTag> tags;
  final Map<EffectTag, List<EffectOccurrence>> occurrences;
  const _CategorySection({
    required this.category,
    required this.tags,
    required this.occurrences,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Row(
            children: [
              Icon(category.icon, color: category.color, size: 18),
              const SizedBox(width: 6),
              Text(
                category.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: category.color,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tags.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: category.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              for (int i = 0; i < tags.length; i++)
                _EffectRow(
                  tag: tags[i],
                  occurrences: occurrences[tags[i]]!,
                  isLast: i == tags.length - 1,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EffectRow extends StatelessWidget {
  final EffectTag tag;
  final List<EffectOccurrence> occurrences;
  final bool isLast;
  const _EffectRow({
    required this.tag,
    required this.occurrences,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = tag.category.color;
    // Every row surfaces at least the tag blurb; when the wiki text had
    // numbers we prefer the excerpt (e.g. "+30% damage") so the real
    // values are always visible without a detail-screen drill.
    final hasAnyExcerpt = occurrences.any((o) => o.excerpt.isNotEmpty);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: catColor.withValues(alpha: 0.35)),
            ),
            child: Icon(tag.icon, size: 16, color: catColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tag.label,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '×${occurrences.length}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                // Skip the generic blurb entirely when we already show
                // per-source excerpts — saves a line of vertical space
                // per row and the excerpts are strictly more useful.
                if (!hasAnyExcerpt) ...[
                  const SizedBox(height: 1),
                  Text(
                    tag.blurb,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.25,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                for (final o in occurrences) _SourceLine(occurrence: o),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact source + excerpt line. Renders as `◎ Item Name — "+30% damage"`.
/// When no excerpt could be pulled we fall back to just the source name
/// so the user at least sees *what* contributed the effect.
class _SourceLine extends StatelessWidget {
  final EffectOccurrence occurrence;
  const _SourceLine({required this.occurrence});

  @override
  Widget build(BuildContext context) {
    final c = occurrence.sourceIsGun
        ? Colors.deepOrangeAccent
        : Colors.lightGreenAccent;
    final hasExcerpt = occurrence.excerpt.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            occurrence.sourceIsGun
                ? Icons.gps_fixed
                : Icons.inventory_2_outlined,
            size: 11,
            color: c,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, height: 1.3),
                children: [
                  TextSpan(
                    text: occurrence.sourceName,
                    style: TextStyle(
                      color: c.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasExcerpt)
                    TextSpan(
                      text: '  —  ${occurrence.excerpt}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
