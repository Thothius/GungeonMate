part of '../stats_detail_screen.dart';

class _EventLog extends StatefulWidget {
  final bool isCool;
  const _EventLog({required this.isCool});

  @override
  State<_EventLog> createState() => _EventLogState();
}

class _EventLogState extends State<_EventLog> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final entries = widget.isCool ? p.coolnessLog : p.curseLog;
    final title = widget.isCool ? 'Coolness event log' : 'Curse event log';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tap-to-expand header with entry count badge
        InkWell(
          onTap:
              entries.isEmpty
                  ? null
                  : () {
                    Haptics.selection();
                    setState(() => _collapsed = !_collapsed);
                  },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
            child: Row(
              children: [
                GoopText(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                    color: Skeuo.collapse(Colors.white).withValues(alpha: 0.65),
                  ),
                ),
                SizedBox(width: 8),
                if (entries.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Skeuo.collapse(
                        Colors.white,
                      ).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.all(Radii.sm),
                    ),
                    child: Text(
                      '${entries.length}',
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w700,
                        color: Skeuo.collapse(
                          Colors.white,
                        ).withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                Spacer(),
                if (entries.isNotEmpty)
                  AnimatedRotation(
                    turns: _collapsed ? 0 : 0.5,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: Skeuo.collapse(
                        Colors.white,
                      ).withValues(alpha: 0.4),
                    ),
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child:
              (!_collapsed && entries.isNotEmpty)
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...entries
                          .take(20)
                          .map(
                            (e) => _LogTile(entry: e, isCool: widget.isCool),
                          ),
                      SizedBox(height: 8),
                      _LogLegend(entries: entries),
                    ],
                  )
                  : const SizedBox.shrink(),
        ),
        if (_collapsed && entries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Insets.lg),
            decoration: BoxDecoration(
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Skeuo.collapse(Colors.white).withValues(alpha: 0.06),
              ),
            ),
            child: GoopText(
              'No events yet. Pick up items or use quick actions above to start tracking.',
              style: TextStyle(
                fontSize: FontSizes.labelMedium,
                color: Skeuo.collapse(Colors.white).withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _LogTile extends StatelessWidget {
  final RunLogEntry entry;
  final bool isCool;
  const _LogTile({required this.entry, required this.isCool});

  @override
  Widget build(BuildContext context) {
    final catColor = runLogCategoryColor(entry.category);
    final delta = isCool ? entry.coolnessDelta : entry.curseDelta;
    final hasDelta = (isCool ? entry.affectsCoolness : entry.affectsCurse);
    final isPositive = delta > 0;
    final deltaColor = isPositive ? catColor : Skeuo.inkIf(Colors.redAccent);

    final timeStr =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
        '${entry.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          color: catColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.all(Radii.sm),
          border: Border.all(
            color: Skeuo.collapse(Colors.white).withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(
                runLogCategoryIcon(entry.category),
                size: 18,
                color: catColor,
              ),
              SizedBox(width: 8),
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
                    SizedBox(height: 2),
                    Row(
                      children: [
                        GoopText(
                          timeStr,
                          style: TextStyle(
                            fontSize: FontSizes.labelSmall,
                            color: Skeuo.collapse(
                              Colors.white,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        if (entry.playerName != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: GoopText(
                              entry.playerName!,
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
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
              if (hasDelta)
                GoopText(
                  '${isPositive ? '+' : ''}${delta.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.w900,
                    color: deltaColor,
                  ),
                )
              else
                Icon(
                  runLogCategoryIcon(entry.category),
                  size: 14,
                  color: catColor.withValues(alpha: 0.4),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Color-to-category legend shown at the bottom of the event log.
/// Only shows categories that actually appear in the current log.
class _LogLegend extends StatelessWidget {
  final List<RunLogEntry> entries;
  const _LogLegend({required this.entries});

  @override
  Widget build(BuildContext context) {
    final present = <RunLogCategory>{};
    for (final e in entries) {
      present.add(e.category);
    }
    final cats = present.toList()..sort((a, b) => a.index.compareTo(b.index));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Skeuo.collapse(Colors.white).withValues(alpha: 0.02),
        borderRadius: BorderRadius.all(Radii.sm),
        border: Border.all(
          color: Skeuo.collapse(Colors.white).withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoopText(
            'LEGEND',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children:
                cats.map((c) {
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
                      SizedBox(width: 4),
                      GoopText(
                        runLogCategoryLabel(c),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Skeuo.collapse(
                            Colors.white,
                          ).withValues(alpha: 0.7),
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
