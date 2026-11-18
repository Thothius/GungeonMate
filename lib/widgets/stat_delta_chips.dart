import 'package:flutter/material.dart';

import '../services/goop_talk_engine.dart';
import '../services/synergy_stats.dart';

/// Old→new stat chips under a synergy row. Tap toggles the per-stat
/// clause breakdown so players can see the original value + source text.
/// Self-contained — manages its own expand state.
class StatDeltaChips extends StatefulWidget {
  final List<StatDelta> deltas;
  const StatDeltaChips({super.key, required this.deltas});

  @override
  State<StatDeltaChips> createState() => _StatDeltaChipsState();
}

class _StatDeltaChipsState extends State<StatDeltaChips> {
  bool _show = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _show = !_show),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: [
              for (final d in widget.deltas)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: (d.improved ? Colors.greenAccent : Colors.redAccent)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (d.improved
                              ? Colors.greenAccent
                              : Colors.redAccent)
                          .withValues(alpha: 0.35),
                      width: 0.7,
                    ),
                  ),
                  child: GoopText(
                    d.oldText == null
                        ? '${d.label} ${d.newText}'
                        : '${d.label} ${d.oldText}→${d.newText}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color:
                          d.improved
                              ? Colors.greenAccent.shade200
                              : Colors.redAccent.shade200,
                    ),
                  ),
                ),
            ],
          ),
          if (_show) ...[
            const SizedBox(height: 5),
            for (final d in widget.deltas)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: GoopText(
                  '${d.label}: ${d.oldText ?? '—'} → ${d.newText}  ·  ${d.clause}',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.3,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Qualitative + fx-tag chips from the Gemini classification pass
/// (synergy_meta.json). Renders stat arrows for unquantified buffs and
/// small mechanic tags (freeze, bullet_homing, ...).
class SynergyMetaChips extends StatelessWidget {
  final SynergyMeta? meta;
  const SynergyMetaChips({super.key, required this.meta});

  static const _maxFx = 8;

  @override
  Widget build(BuildContext context) {
    final m = meta;
    if (m == null || (m.qb.isEmpty && m.fx.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (m.qb.isNotEmpty)
          Wrap(
            spacing: 5,
            runSpacing: 4,
            children: [
              for (final q in m.qb)
                Tooltip(
                  message: q.note.isEmpty ? q.stat : q.note,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: _qbColor(q.dir).withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _qbColor(q.dir).withValues(alpha: 0.35),
                        width: 0.7,
                      ),
                    ),
                    child: GoopText(
                      '${synStatLabelFor(q.stat)}${_qbArrow(q.dir)}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: _qbColor(q.dir),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (m.fx.isNotEmpty) ...[
          if (m.qb.isNotEmpty) const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 3,
            children: [
              for (final tag in m.fx.take(_maxFx))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                      width: 0.6,
                    ),
                  ),
                  child: GoopText(
                    tag.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              if (m.fx.length > _maxFx)
                GoopText(
                  '+${m.fx.length - _maxFx}',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  static Color _qbColor(String dir) => switch (dir) {
    'up' => Colors.greenAccent,
    'down' => Colors.redAccent,
    'mixed' => Colors.amberAccent,
    _ => Colors.white54,
  };

  static String _qbArrow(String dir) => switch (dir) {
    'up' => '↑',
    'down' => '↓',
    'mixed' => '↕',
    _ => '·',
  };
}
