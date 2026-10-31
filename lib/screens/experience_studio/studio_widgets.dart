part of '../experience_studio_screen.dart';

class _StepLabel extends StatelessWidget {
  final String text;
  const _StepLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return GoopText(
      text,
      style: TextStyle(
        fontSize: FontSizes.bodyMedium,
        fontWeight: FontWeight.w900,
        color: AppTheme.flair.primary.withValues(alpha: 0.85),
        letterSpacing: 1.5,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Insets.sm),
      decoration: BoxDecoration(
        color: flair.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.all(Radii.sm),
        border: Border.all(color: flair.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: GoopText(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: flair.primary,
            activeTrackColor: flair.primary.withValues(alpha: 0.25),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _StudioSlider extends StatelessWidget {
  final String label, displayValue;
  final double value, min, max;
  final int divisions;
  final Color color;
  final ValueChanged<double> onChanged;
  const _StudioSlider(
    this.label,
    this.displayValue,
    this.value,
    this.min,
    this.max,
    this.divisions,
    this.color,
    this.onChanged,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GoopText(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              GoopText(
                displayValue,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 28,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6.0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 12.0,
                ),
                activeTrackColor: color,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Schema chip — colored dots + name for the per-theme color pick.
class _SchemaChip extends StatelessWidget {
  final ({String name, List<Color> colors}) schema;
  final bool active;
  final VoidCallback onTap;
  const _SchemaChip({
    required this.schema,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color:
              active
                  ? flair.primary.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                active ? flair.primary : Colors.white.withValues(alpha: 0.15),
            width: active ? 1.6 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < schema.colors.length && i < 4; i++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: schema.colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            GoopText(
              schema.name,
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color:
                    active
                        ? flair.primary
                        : Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
