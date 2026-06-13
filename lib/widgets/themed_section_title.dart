import 'package:flutter/material.dart';

import '../services/app_theme.dart';

/// Reusable section header used by WikiSection / Synergies / Referenced By
/// blocks. Reads `flair.headerGlyph`, `flair.headerAllCaps`,
/// `flair.headerUnderlineColor` so each theme stamps its identity on
/// every titled block: ❖ Coolmaxing, ♡ Unicorn, † Curseblaster,
/// ★ Winchester, and ALL-CAPS for Minimalist.
///
/// Pass [trailing] for the optional collapse chevron / count badge that
/// section accordions need to render alongside the title.
class ThemedSectionTitle extends StatelessWidget {
  /// Default Material icon. Used when the active flair has no
  /// `headerGlyph` and is not in all-caps mode (i.e. Coolmaxing default).
  /// Wait — Coolmaxing DOES have headerGlyph (❖). So this falls back
  /// only when no themed treatment is set, which currently never happens
  /// after the v2 themes — kept as a defensive default for future themes.
  final IconData icon;
  final Color iconColor;
  final String title;
  final int? count;
  final Widget? trailing;
  final double titleSize;

  const ThemedSectionTitle({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.count,
    this.trailing,
    this.titleSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flair;
    final caps = f.headerAllCaps;
    final glyph = f.headerGlyph;
    final underline = f.headerUnderlineColor;

    final titleText = caps ? title.toUpperCase() : title;
    final countText = count == null ? '' : '  (${count!})';

    Widget leading;
    if (caps) {
      // Minimalist: drop the icon entirely — the typography carries the
      // role. A leading SizedBox keeps Row baseline alignment consistent.
      leading = const SizedBox(width: 0);
    } else if (glyph != null) {
      leading = Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          glyph,
          style: TextStyle(
            fontSize: titleSize + 1,
            // Theme-tinted glyph: † always blood-red in Curseblaster,
            // ★ always brass in Winchester, etc. Section role is still
            // preserved by the underline + title text.
            color: f.primary,
            height: 1,
          ),
        ),
      );
    } else {
      leading = Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Icon(icon, size: titleSize + 3, color: iconColor),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            leading,
            Expanded(
              child: Text(
                '$titleText$countText',
                style: TextStyle(
                  fontSize: caps ? titleSize - 2 : titleSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: caps ? 1.6 : 0,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (underline != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(height: 1, color: underline),
          ),
      ],
    );
  }
}
