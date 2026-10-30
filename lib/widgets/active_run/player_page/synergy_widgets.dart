part of '../player_page.dart';



/// Circular quick-action button for the floating tile-actions pill.
class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
