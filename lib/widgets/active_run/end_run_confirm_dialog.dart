import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';

/// Gungeon-styled "End Run" confirmation dialog featuring the
/// Lord of the Jammed as a floating centerpiece.
///
/// The Lord bobs up and down on an infinite loop, a red-amber glow
/// pulses behind it, and the confirm/cancel buttons are styled as
/// chunky gungeon action buttons. Used by both the active-run header
/// menu and the settings Run tab.
class EndRunConfirmDialog extends StatefulWidget {
  /// True when the local player is the MP sidekick — changes the
  /// wording to "End & Disconnect".
  final bool isSidekick;

  /// Called when the user confirms. The dialog dismisses itself
  /// before calling this so the caller can navigate freely.
  final VoidCallback onConfirm;

  const EndRunConfirmDialog({
    super.key,
    this.isSidekick = false,
    required this.onConfirm,
  });

  /// Convenience wrapper — shows the dialog and calls [onConfirm] on
  /// confirm. Matches the signature of the old `_confirmEndRun` helpers.
  static Future<void> show(
    BuildContext context, {
    bool isSidekick = false,
    required VoidCallback onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (c) => EndRunConfirmDialog(
        isSidekick: isSidekick,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<EndRunConfirmDialog> createState() => _EndRunConfirmDialogState();
}

class _EndRunConfirmDialogState extends State<EndRunConfirmDialog>
    with TickerProviderStateMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _glowCtrl;

  static const _lordAsset =
      'assets/images/end_run/Lord_of_the_Jammed.webp';
  // Fallback: the existing enemy sprite (already in pubspec).
  static const _lordFallback =
      'assets/images/enemies/Lord_of_the_Jammed.png';

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSidekick = widget.isSidekick;
    return Dialog(
      backgroundColor: const Color(0xFF1E1E22),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.redAccent.withValues(alpha: 0.35),
          width: 1.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Lord of the Jammed centerpiece (floating) ──
            _buildCenterpiece(),
            const SizedBox(height: 12),
            // ── Title ──
            GoopText(
              isSidekick ? 'END RUN & DISCONNECT?' : 'END RUN?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                color: Colors.redAccent.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            // ── Body ──
            GoopText(
              isSidekick
                  ? 'The Lord of the Jammed awaits. This will disconnect you from the host, reset the current session, and return you to the main menu.'
                  : 'The Lord of the Jammed awaits. This resets the current run and returns you to the main menu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            // ── Action buttons ──
            Row(
              children: [
                Expanded(
                  child: _GungeonActionButton(
                    label: 'Cancel',
                    color: Colors.white.withValues(alpha: 0.15),
                    textColor: Colors.white.withValues(alpha: 0.7),
                    borderColor: Colors.white.withValues(alpha: 0.12),
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GungeonActionButton(
                    label: isSidekick ? 'End & Disconnect' : 'End Run',
                    color: Colors.red.shade900.withValues(alpha: 0.55),
                    textColor: Colors.redAccent,
                    borderColor: Colors.redAccent.withValues(alpha: 0.5),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onConfirm();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterpiece() {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing glow halo
          AnimatedBuilder(
            animation: _glowCtrl,
            builder: (_, __) {
              final t = _glowCtrl.value;
              return Container(
                width: 90 + t * 20,
                height: 90 + t * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.redAccent.withValues(alpha: 0.18 * (1 - t * 0.5)),
                      Colors.amber.withValues(alpha: 0.06 * (1 - t)),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          // Floating Lord of the Jammed
          AnimatedBuilder(
            animation: _floatCtrl,
            builder: (_, child) {
              // Ease-in-out float: -8px to +8px
              final t = _floatCtrl.value;
              final dy = (t * 2 - 1) * 8.0;
              return Transform.translate(
                offset: Offset(0, dy),
                child: child,
              );
            },
            child: Image.asset(
              _lordAsset,
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, __, ___) => Image.asset(
                _lordFallback,
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.dangerous_rounded,
                  size: 64,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }
}

// =============================================================================
// _GungeonActionButton — chunky gungeon-style action button
// =============================================================================

class _GungeonActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _GungeonActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        onTap();
      },
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.15),
              blurRadius: 6,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: GoopText(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
