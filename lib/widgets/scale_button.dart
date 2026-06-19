import 'package:flutter/material.dart';
import '../services/haptics.dart';

/// A premium, generic, physical spring-button wrapper that animates
/// scale-down on-press and automatically emits tactile haptics.
class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableHaptics;

  const ScaleButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enableHaptics = true,
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled
          ? (_) {
              setState(() => _isPressed = true);
              if (widget.enableHaptics) {
                Haptics.light();
              }
            }
          : null,
      onTap: enabled && widget.onTap != null
          ? () {
              setState(() => _isPressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
      onLongPress: enabled && widget.onLongPress != null
          ? () {
              if (widget.enableHaptics) {
                Haptics.medium();
              }
              widget.onLongPress!();
            }
          : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
