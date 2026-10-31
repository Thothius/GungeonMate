import 'package:flutter/material.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../theme/tokens.dart';
import '../../utils/responsive.dart';

/// Shared bottom Back bar — replaces top-left app-bar back arrows.
/// Mirrors the item_detail bottom-bar pattern: full-width outlined
/// button in the thumb zone, SafeArea-aware. Drop into a Scaffold's
/// `bottomNavigationBar` slot.
class BottomBackBar extends StatelessWidget {
  /// Custom pop behaviour; defaults to `Navigator.pop(context)`.
  final VoidCallback? onPressed;

  /// Optional label override (defaults to 'Back').
  final String label;

  const BottomBackBar({super.key, this.onPressed, this.label = 'Back'});

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SizedBox(
              width: double.infinity,
              height: 62 * sf,
              child: OutlinedButton.icon(
                icon: Icon(Icons.arrow_back, size: 24 * sf),
                label: GoopText(
                  label,
                  style: TextStyle(
                    fontSize: FontSizes.titleSmall * sf,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radii.lg),
                  ),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                onPressed: () {
                  Haptics.selection();
                  (onPressed ?? () => Navigator.pop(context))();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
