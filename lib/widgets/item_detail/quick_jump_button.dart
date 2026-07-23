import 'package:flutter/material.dart';
import '../../services/goop_talk_engine.dart';

class QuickJumpButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const QuickJumpButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? Colors.white54 : Colors.white12,
            width: 1,
          ),
        ),
        child: GoopText(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.white : Colors.white60,
          ),
        ),
      ),
    );
  }
}
