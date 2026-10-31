part of 'gun_stats.dart';

/// Uniform borderless stat grid — every cell is label-over-number,
/// same size, no icons. 3 columns; last row may be partial.
class _StatGrid extends StatelessWidget {
  final List<(String, String)> specs;
  const _StatGrid({required this.specs});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final rows = <Widget>[];
    for (var i = 0; i < specs.length; i += 3) {
      final row = specs.sublist(i, (i + 3).clamp(0, specs.length));
      rows.add(
        Row(
          children: [
            for (final (label, value) in row)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 2),
                      GoopText(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (var e = row.length; e < 3; e++)
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );
      if (i + 3 < specs.length) {
        rows.add(Divider(height: 1, color: onSurface.withValues(alpha: 0.06)));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}
