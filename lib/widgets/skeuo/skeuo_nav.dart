import 'package:flutter/material.dart';

import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../theme/tokens.dart';
import 'skeuo_tokens.dart';

/// One destination in a [SkeuoNavBar] — icon, selected icon, label.
class SkeuoNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const SkeuoNavItem(this.icon, this.selectedIcon, this.label);
}

/// Paper bottom bar for the skeuo skin — a 2px ink top rule over a
/// paper strip; each destination is a small chip, the selected one
/// filled with ink like the kit's Tabs/Rounder/Library example.
class SkeuoNavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  final List<SkeuoNavItem> items;

  const SkeuoNavBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final noMotion = MediaQuery.of(context).disableAnimations;
    return Container(
      decoration: const BoxDecoration(
        color: Skeuo.card,
        border: Border(
          top: BorderSide(color: Skeuo.ink, width: Skeuo.borderMed),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _chip(context, i, noMotion)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, int i, bool noMotion) {
    final item = items[i];
    final sel = i == index;
    final fg = sel ? Skeuo.paper : Skeuo.ink;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Haptics.selection();
        onSelect(i);
      },
      child: AnimatedContainer(
        duration: noMotion ? Duration.zero : Motion.fast,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: sel ? Skeuo.ink : Skeuo.card,
          borderRadius: BorderRadius.circular(Skeuo.rSm),
          border: Border.all(
            color: sel ? Skeuo.ink : Skeuo.ink.withValues(alpha: 0.55),
            width: sel ? Skeuo.borderMed : 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(sel ? item.selectedIcon : item.icon, size: 20, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: GoopText(
                  item.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: fg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
