import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/run_log_entry.dart';
import '../../services/goop_talk_engine.dart';

class RunLogScreen extends StatelessWidget {
  const RunLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final entries = p.runState.log.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(
        title: const GoopText('EVENT LOG'),
        centerTitle: true,
      ),
      body: entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 64, color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  GoopText(
                    'No events logged yet',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GoopText(
                    'Pick up guns, items, use shrines, or tap quick actions\nto start building your run history.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.3),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 16, color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(width: 6),
                        GoopText(
                          '${entries.length} event${entries.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _FullLogTile(entry: entries[i]),
                    childCount: entries.length,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 8)),
                SliverToBoxAdapter(
                  child: _FullLogLegend(entries: entries),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
    );
  }
}

class _FullLogTile extends StatelessWidget {
  final RunLogEntry entry;
  const _FullLogTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final catColor = runLogCategoryColor(entry.category);
    final hasCurse = entry.affectsCurse;
    final hasCool = entry.affectsCoolness;

    final timeStr =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 12, right: 12),
      child: Container(
        decoration: BoxDecoration(
          color: catColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: catColor, width: 3),
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(runLogCategoryIcon(entry.category), size: 18, color: catColor),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GoopText(
                      entry.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        GoopText(
                          timeStr,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        if (entry.playerName != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: GoopText(
                              entry.playerName!,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: catColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasCurse)
                GoopText(
                  '${entry.curseDelta > 0 ? '+' : ''}${entry.curseDelta.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: entry.curseDelta > 0 ? catColor : Colors.redAccent,
                  ),
                ),
              if (hasCool) ...[
                if (hasCurse) const SizedBox(width: 6),
                GoopText(
                  '${entry.coolnessDelta > 0 ? '+' : ''}${entry.coolnessDelta.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: entry.coolnessDelta > 0 ? catColor : Colors.redAccent,
                  ),
                ),
              ],
              if (!hasCurse && !hasCool)
                Icon(runLogCategoryIcon(entry.category),
                    size: 14, color: catColor.withValues(alpha: 0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullLogLegend extends StatelessWidget {
  final List<RunLogEntry> entries;
  const _FullLogLegend({required this.entries});

  @override
  Widget build(BuildContext context) {
    final present = <RunLogCategory>{};
    for (final e in entries) {
      present.add(e.category);
    }
    final cats = present.toList()..sort((a, b) => a.index.compareTo(b.index));

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoopText(
            'LEGEND',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: cats.map((c) {
              final color = runLogCategoryColor(c);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  GoopText(
                    runLogCategoryLabel(c),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
