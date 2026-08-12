import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/synergy.dart';
import '../services/app_theme.dart';
import '../providers/run_provider.dart';
import '../services/goop_talk_engine.dart';
import '../widgets/game_icon.dart';

class AllSynergiesScreen extends StatelessWidget {
  const AllSynergiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final ownedList = p.runState.allItemNames;
    final owned = ownedList.map((n) => n.toLowerCase()).toSet();
    final all = p.allSynergies;

    final active = <Synergy>[];
    final partial = <Synergy>[];
    final locked = <Synergy>[];
    for (final s in all) {
      if (s.matchesItems(ownedList)) {
        active.add(s);
      } else if (s.items.any((i) => owned.contains(i.toLowerCase())) ||
          (s.anyOf.isNotEmpty &&
              s.anyOf.any((i) => owned.contains(i.toLowerCase())))) {
        partial.add(s);
      } else {
        locked.add(s);
      }
    }

    active.sort((a, b) => a.name.compareTo(b.name));
    partial.sort((a, b) => a.name.compareTo(b.name));
    locked.sort((a, b) => a.name.compareTo(b.name));

    Widget sectionHeader(String label, Color color, int count) =>
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: color),
                const SizedBox(width: 8),
                GoopText(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const GoopText(
          'SYNERGIES',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GoopText(
                'Owned items are lit; missing are dim. Tap a synergy to view its details.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
          ),
          if (active.isNotEmpty) ...[
            sectionHeader('ACTIVE', Colors.greenAccent, active.length),
            _SynergyGrid(list: active, owned: owned, active: true),
          ],
          if (partial.isNotEmpty) ...[
            sectionHeader('PARTIAL', Colors.amberAccent, partial.length),
            _SynergyGrid(list: partial, owned: owned, active: false),
          ],
          if (locked.isNotEmpty) ...[
            sectionHeader('LOCKED', Colors.white38, locked.length),
            _SynergyGrid(list: locked, owned: owned, active: false),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _SynergyGrid extends StatelessWidget {
  final List<Synergy> list;
  final Set<String> owned;
  final bool active;

  const _SynergyGrid({
    required this.list,
    required this.owned,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.05,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate(
          (c, i) => _SynergyCard(s: list[i], owned: owned, isActive: active),
          childCount: list.length,
        ),
      ),
    );
  }
}

class _SynergyCard extends StatelessWidget {
  final Synergy s;
  final Set<String> owned;
  final bool isActive;

  const _SynergyCard({
    required this.s,
    required this.owned,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final hasAny = s.items.any((i) => owned.contains(i.toLowerCase())) ||
        (s.anyOf.isNotEmpty &&
            s.anyOf.any((i) => owned.contains(i.toLowerCase())));
    final cardColor = isActive ? Colors.greenAccent : (hasAny ? Colors.amberAccent : Colors.white38);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.flair.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: cardColor.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (s.icon.isNotEmpty)
                  GameIcon(assetPath: s.icon, size: 22, showRing: false)
                else
                  Icon(Icons.auto_awesome, size: 20, color: cardColor),
                const SizedBox(width: 8),
                Expanded(
                  child: GoopText(
                    s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: cardColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GoopText(
                s.prettyEffect.isNotEmpty ? s.prettyEffect : s.effect,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                ...s.items.map(
                    (i) => _MiniChip(i, owned: owned.contains(i.toLowerCase()))),
                if (s.anyOf.isNotEmpty)
                  ...s.anyOf.map((i) => _MiniChip(i,
                      owned: owned.contains(i.toLowerCase()), isAnyOf: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String name;
  final bool owned;
  final bool isAnyOf;

  const _MiniChip(
    this.name, {
    required this.owned,
    this.isAnyOf = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = owned
        ? (isAnyOf
            ? Colors.amber.withValues(alpha: 0.2)
            : Colors.green.withValues(alpha: 0.15))
        : Colors.white.withValues(alpha: 0.08);
    final fg = owned
        ? (isAnyOf ? Colors.amber.shade100 : Colors.greenAccent.shade200)
        : Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: fg.withValues(alpha: 0.4), width: 0.6),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 9,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
