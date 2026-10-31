import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/synergy.dart';
import '../services/app_theme.dart';
import '../providers/run_provider.dart';
import '../services/goop_talk_engine.dart';
import '../widgets/game_icon.dart';
import '../widgets/skeuo/skeuo_tokens.dart';

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
          style: TextStyle(
            fontSize: FontSizes.titleSmall,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Skeuo.collapse(Colors.white70)),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Summary bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  _summaryChip(
                    'ACTIVE',
                    active.length,
                    Skeuo.inkIf(Colors.greenAccent),
                  ),
                  SizedBox(width: 8),
                  _summaryChip(
                    'PARTIAL',
                    partial.length,
                    Skeuo.inkIf(Colors.amberAccent),
                  ),
                  SizedBox(width: 8),
                  _summaryChip(
                    'LOCKED',
                    locked.length,
                    Skeuo.collapse(Colors.white38),
                  ),
                ],
              ),
            ),
            // Responsive: side-by-side on wide screens, stacked on mobile.
            // 600px is the Material breakpoint for tablet/landscape.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  final gridCols = isWide ? 2 : 1;

                  if (isWide) {
                    // ── Two-column layout: acquired (left) | not-acquired (right) ──
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              _columnHeader(
                                'ACQUIRED',
                                Skeuo.inkIf(Colors.greenAccent),
                                active.length + partial.length,
                              ),
                              if (active.isNotEmpty) ...[
                                _subHeader(
                                  'Active',
                                  Skeuo.inkIf(Colors.greenAccent),
                                  active.length,
                                ),
                                _SynergyGrid(
                                  list: active,
                                  owned: owned,
                                  active: true,
                                  columns: gridCols,
                                ),
                              ],
                              if (partial.isNotEmpty) ...[
                                _subHeader(
                                  'Partial',
                                  Skeuo.inkIf(Colors.amberAccent),
                                  partial.length,
                                ),
                                _SynergyGrid(
                                  list: partial,
                                  owned: owned,
                                  active: false,
                                  columns: gridCols,
                                ),
                              ],
                              SliverToBoxAdapter(child: SizedBox(height: 80)),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          color: Skeuo.collapse(
                            Colors.white,
                          ).withValues(alpha: 0.06),
                        ),
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              _columnHeader(
                                'NOT ACQUIRED',
                                Skeuo.collapse(Colors.white38),
                                locked.length,
                              ),
                              _SynergyGrid(
                                list: locked,
                                owned: owned,
                                active: false,
                                columns: gridCols,
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 80),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // ── Stacked layout (mobile): all sections in one scroll ──
                  return CustomScrollView(
                    slivers: [
                      _columnHeader(
                        'ACQUIRED',
                        Skeuo.inkIf(Colors.greenAccent),
                        active.length + partial.length,
                      ),
                      if (active.isNotEmpty) ...[
                        _subHeader(
                          'Active',
                          Skeuo.inkIf(Colors.greenAccent),
                          active.length,
                        ),
                        _SynergyGrid(
                          list: active,
                          owned: owned,
                          active: true,
                          columns: 2,
                        ),
                      ],
                      if (partial.isNotEmpty) ...[
                        _subHeader(
                          'Partial',
                          Skeuo.inkIf(Colors.amberAccent),
                          partial.length,
                        ),
                        _SynergyGrid(
                          list: partial,
                          owned: owned,
                          active: false,
                          columns: 2,
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: Divider(
                          color: Skeuo.collapse(Colors.white12),
                          height: 24,
                        ),
                      ),
                      _columnHeader(
                        'NOT ACQUIRED',
                        Skeuo.collapse(Colors.white38),
                        locked.length,
                      ),
                      _SynergyGrid(
                        list: locked,
                        owned: owned,
                        active: false,
                        columns: 2,
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 80)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.sm,
        vertical: Insets.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.all(Radii.sm),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoopText(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GoopText(
            label,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
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
                  style: TextStyle(
                    fontSize: FontSizes.labelSmall,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _subHeader(String label, Color color, int count) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: color),
          const SizedBox(width: 4),
          GoopText(
            '$label ($count)',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
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
  final int columns;

  const _SynergyGrid({
    required this.list,
    required this.owned,
    required this.active,
    this.columns = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.md),
      sliver: SliverList(
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
    final hasAny =
        s.items.any((i) => owned.contains(i.toLowerCase())) ||
        (s.anyOf.isNotEmpty &&
            s.anyOf.any((i) => owned.contains(i.toLowerCase())));
    final cardColor =
        isActive
            ? Skeuo.inkIf(Colors.greenAccent)
            : (hasAny
                ? Skeuo.inkIf(Colors.amberAccent)
                : Skeuo.collapse(Colors.white38));

    // Compact row: synergy icon + name + required pieces share the top
    // line; the effect desc sits on the line below (per user request —
    // replaces the old 2-col card grid which was too big/busy).
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppTheme.flair.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cardColor.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (s.icon.isNotEmpty)
                  GameIcon(assetPath: s.icon, size: 20, showRing: false)
                else
                  Icon(Icons.auto_awesome, size: 18, color: cardColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      GoopText(
                        s.name,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: cardColor,
                        ),
                      ),
                      ...s.items.map(
                        (i) => _MiniChip(
                          i,
                          owned: owned.contains(i.toLowerCase()),
                        ),
                      ),
                      if (s.anyOf.isNotEmpty)
                        ...s.anyOf.map(
                          (i) => _MiniChip(
                            i,
                            owned: owned.contains(i.toLowerCase()),
                            isAnyOf: true,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if ((s.prettyEffect.isNotEmpty ? s.prettyEffect : s.effect)
                .isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: GoopText(
                  s.prettyEffect.isNotEmpty ? s.prettyEffect : s.effect,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Skeuo.collapse(Colors.white).withValues(alpha: 0.55),
                    height: 1.25,
                  ),
                ),
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

  const _MiniChip(this.name, {required this.owned, this.isAnyOf = false});

  @override
  Widget build(BuildContext context) {
    final bg =
        owned
            ? (isAnyOf
                ? Skeuo.inkIf(Colors.amber).withValues(alpha: 0.2)
                : Skeuo.inkIf(Colors.green).withValues(alpha: 0.15))
            : Skeuo.collapse(Colors.white).withValues(alpha: 0.08);
    final fg =
        owned
            ? (isAnyOf
                ? Skeuo.inkIf(Colors.amber.shade100)
                : Skeuo.inkIf(Colors.greenAccent.shade200))
            : Skeuo.collapse(Colors.white54);
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
          fontSize: FontSizes.labelSmall,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
