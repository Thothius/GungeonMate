import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Uniform blue synergy badge — small bolt in a blue-outlined circle.
/// Marks "part of a synergy" on inventory tiles and list rows: one
/// marker meaning the same thing for all synergies.
///
/// (The animated `SynergyGlowOverlay` border was retired — the badge
/// replaced the color-coded glow; the overlay + its effect-index
/// helpers were dead code and were removed in the S5 sweep.)
class SynergyBadge extends StatelessWidget {
  const SynergyBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1F30),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4FC3F7), width: 1.2),
      ),
      child: const Icon(
        Icons.keyboard_double_arrow_up_rounded,
        size: ChipStyle.iconMicro,
        color: Color(0xFF4FC3F7),
      ),
    );
  }
}
