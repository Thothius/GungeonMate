part of '../periodic_tile.dart';

/// Paints a single faint diagonal line across the tile face, used to
/// flag actives that get destroyed on use (e.g. Junk, Glass Guon Stone).
/// Kept as a `CustomPainter` rather than a rotated container so the
/// stroke stays crisp at any tile aspect ratio.
class _StrikethroughPainter extends CustomPainter {
  final Color color;
  const _StrikethroughPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
    // Top-right → bottom-left, leaving a small inset so the line doesn't
    // hug the tile corners.
    final inset = size.shortestSide * 0.18;
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StrikethroughPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// A 2-column grid of stat label/value pairs for the tactical stats tile.
/// Each cell shows a tiny label above a bold colored value.
class _StatGrid extends StatelessWidget {
  final List<(String, String, Color)> stats;
  final double valueSize;
  final double labelSize;

  const _StatGrid({
    required this.stats,
    required this.valueSize,
    required this.labelSize,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.0,
        mainAxisSpacing: 2,
        crossAxisSpacing: 6,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final (label, value, color) = stats[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GoopText(
              label,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.bold,
                color: Skeuo.collapse(Colors.white60),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 1),
            GoopText(
              value.isEmpty ? 'N/A' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        );
      },
    );
  }
}
