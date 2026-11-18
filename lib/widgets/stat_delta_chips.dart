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
