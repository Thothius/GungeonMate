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
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _summaryChip('ACTIVE', active.length, Colors.greenAccent),
                const SizedBox(width: 8),
                _summaryChip('PARTIAL', partial.length, Colors.amberAccent),
                const SizedBox(width: 8),
                _summaryChip('LOCKED', locked.length, Colors.white38),
              ],
            ),
          ),
          // Two-column layout: acquired (left) | not-acquired (right)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LEFT: Acquired (active + partial) ──
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      _columnHeader('ACQUIRED', Colors.greenAccent,
                          active.length + partial.length),
                      if (active.isNotEmpty) ...[
                        _subHeader('Active', Colors.greenAccent, active.length),
                        _SynergyGrid(list: active, owned: owned, active: true),
                      ],
                      if (partial.isNotEmpty) ...[
                        _subHeader('Partial', Colors.amberAccent, partial.length),
                        _SynergyGrid(list: partial, owned: owned, active: false),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
                // ── Divider ──
                Container(width: 1, color: Colors.white.withValues(alpha: 0.06)),
                // ── RIGHT: Not acquired (locked) ──
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      _columnHeader('NOT ACQUIRED', Colors.white38, locked.length),
                      _SynergyGrid(list: locked, owned: owned, active: false),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoopText(
            '$count',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(width: 4),
          GoopText(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.7), letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _columnHeader(String label, Color color, int count) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              GoopText(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _subHeader(String label, Color color, int count) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Icon(Icons.circle, size: 6, color: color),
              const SizedBox(width: 4),
              GoopText(
                '$label ($count)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
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
