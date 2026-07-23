import 'package:flutter/material.dart';

import '../../services/goop_talk_engine.dart';

class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onPressed;
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white.withValues(alpha: 0.7);
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(color: c.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: color == null ? null : c.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: c),
            const SizedBox(width: 5),
            Flexible(
              child: GoopText(
                label,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onPressed;
  const ToolbarIcon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = active
        ? Theme.of(context).colorScheme.primary
        : Colors.white.withValues(alpha: 0.6);
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: 44,
        width: 40,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: BorderSide(color: c.withValues(alpha: 0.45)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: active ? c.withValues(alpha: 0.12) : null,
          ),
          child: Icon(icon, size: 18, color: c),
        ),
      ),
    );
  }
}
