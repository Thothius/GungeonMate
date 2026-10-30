import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gun.dart';
import '../models/gungeoneer.dart';
import '../models/item.dart';
import '../models/rich_text.dart';
import '../models/shrine.dart';
import '../providers/run_provider.dart';
import '../screens/item_detail_screen.dart';
import '../utils/fast_route.dart';
import '../screens/stats_detail_screen.dart';
import '../services/app_theme.dart';
import 'game_icon.dart';
import 'quality_badge.dart';
import 'themed_number.dart';
import 'themed_section_title.dart';
import '../services/goop_talk_engine.dart';
part 'rich_link/peek_sheets.dart';
part 'rich_link/list_widgets.dart';

// =============================================================================
// Color palette for ref tokens
// =============================================================================

/// Colour an inline cross-link by what it points to. Items/guns get the
/// canonical amber "wikilink" tone; stat pages lean into the matching
/// stat colour; lore + unresolved fade out so plain prose still reads as
/// the dominant signal.
Color _colorForRef(RefKind kind) {
  switch (kind) {
    case RefKind.item:
    case RefKind.gun:
      return const Color(0xFFFFB74D); // warm amber
    case RefKind.character:
      return const Color(0xFF80DEEA); // cyan, matches gungeoneer accents
    case RefKind.shrine:
      return const Color(0xFFB39DDB); // muted purple
    case RefKind.stat:
      return const Color(0xFFFFD54F); // bright yellow (coolness/curse)
    case RefKind.lore:
      return Colors.white70;
    case RefKind.unresolved:
      return Colors.white;
  }
}

// =============================================================================
// RichLinkText — render a flat token list as a Text.rich
// =============================================================================

/// Renders a flat list of [RichToken]s as a `Text.rich`. Internal refs
/// to items/guns are tappable (single tap = navigate, long-press = peek).
/// Stat refs route to the [StatsDetailScreen]. External, lore and
/// unresolved tokens render as styled but non-interactive runs so the
/// surrounding prose stays readable.
class RichLinkText extends StatelessWidget {
  final List<RichToken> tokens;
  final TextStyle? baseStyle;
  final TextAlign textAlign;

  const RichLinkText({
    super.key,
    required this.tokens,
    this.baseStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final base = (baseStyle ??
            const TextStyle(fontSize: FontSizes.bodyMedium, height: 1.4))
        .copyWith(
          color: baseStyle?.color ?? Colors.white.withValues(alpha: 0.92),
        );
    final spans = tokens.map((tok) => _buildSpan(context, tok, base)).toList();
    return Text.rich(
      TextSpan(children: spans, style: base),
      textAlign: textAlign,
    );
  }

  InlineSpan _buildSpan(BuildContext context, RichToken tok, TextStyle base) {
    if (tok is RichTextRun) {
      var style = base;
      switch (tok.style) {
        case TextStyleFlag.italic:
          style = style.copyWith(fontStyle: FontStyle.italic);
          break;
        case TextStyleFlag.code:
          style = style.copyWith(
            fontFamily: 'monospace',
            fontFamilyFallback: const ['Courier New', 'monospace'],
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            letterSpacing: 0,
          );
          break;
        case TextStyleFlag.plain:
          break;
      }
      return TextSpan(text: tok.text, style: style);
    }
    if (tok is RichRef) {
      return _refSpan(context, tok, base);
    }
    if (tok is RichSynRef) {
      return TextSpan(
        text: tok.synergyName,
        style: base.copyWith(
          color: const Color(0xFF00B3CE),
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (tok is RichExt) {
      // External (Wikipedia etc.) — styled but non-interactive. We append
      // a tiny ↗ glyph so users can see it leads outside the app.
      return TextSpan(
        text: '${tok.label}\u2009↗',
        style: base.copyWith(
          color: Colors.white.withValues(alpha: 0.78),
          decoration: TextDecoration.underline,
          decorationStyle: TextDecorationStyle.dotted,
          decorationColor: Colors.white.withValues(alpha: 0.35),
        ),
      );
    }
    return TextSpan(text: '', style: base);
  }

  InlineSpan _refSpan(BuildContext context, RichRef ref, TextStyle base) {
    final color = _colorForRef(ref.kind);

    // Non-navigable refs render as styled-but-flat text.
    if (!ref.isNavigable) {
      final style =
          ref.kind == RefKind.lore
              ? base.copyWith(color: color, fontStyle: FontStyle.italic)
              : base.copyWith(color: color);
      return TextSpan(text: ref.name, style: style);
    }

    // Navigable: wrap in a WidgetSpan so we can attach BOTH single-tap
    // (navigate) and long-press (peek) gestures, which a TextSpan recogniser
    // can't do simultaneously.
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _RefChipText(
        label: ref.name,
        color: color,
        baseStyle: base,
        onTap: () => _handleTap(context, ref),
        onLongPress: () => _handlePeek(context, ref),
      ),
    );
  }

  static void _handleTap(BuildContext context, RichRef ref) {
    final p = context.read<RunProvider>();
    switch (ref.kind) {
      case RefKind.stat:
        final t =
            ref.name.toLowerCase() == 'curse'
                ? StatType.curse
                : StatType.coolness;
        Navigator.push(context, fastRoute(StatsDetailScreen(statType: t)));
        return;
      case RefKind.gun:
        final g = p.gunByName(ref.name);
        if (g != null) _openItemDetail(context, gun: g);
        return;
      case RefKind.item:
        final it = p.itemByName(ref.name);
        if (it != null) _openItemDetail(context, item: it);
        return;
      case RefKind.character:
        // Characters have no full detail screen — a tap surfaces the
        // same peek sheet as a long-press. Cheap UX since the peek
        // already shows everything we know about them.
        final c = p.gungeoneerByName(ref.name);
        if (c != null) showEntityPeekSheet(context, character: c);
        return;
      case RefKind.shrine:
        final s = p.shrineByName(ref.name);
        if (s != null) showEntityPeekSheet(context, shrine: s);
        return;
      case RefKind.lore:
      case RefKind.unresolved:
        return; // not handled
    }
  }

  static void _handlePeek(BuildContext context, RichRef ref) {
    final p = context.read<RunProvider>();
    switch (ref.kind) {
      case RefKind.gun:
        final g = p.gunByName(ref.name);
        if (g != null) showEntityPeekSheet(context, gun: g);
        return;
      case RefKind.item:
        final it = p.itemByName(ref.name);
        if (it != null) showEntityPeekSheet(context, item: it);
        return;
      case RefKind.character:
        final c = p.gungeoneerByName(ref.name);
        if (c != null) showEntityPeekSheet(context, character: c);
        return;
      case RefKind.shrine:
        final s = p.shrineByName(ref.name);
        if (s != null) showEntityPeekSheet(context, shrine: s);
        return;
      case RefKind.stat:
      case RefKind.lore:
      case RefKind.unresolved:
        // No peek sheet for these — fall through to the navigation
        // path so a long-press still does *something* sensible (e.g.
        // a stat ref opens the stat screen).
        _handleTap(context, ref);
        return;
    }
  }

  static void _openItemDetail(BuildContext context, {Gun? gun, Item? item}) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.push(context, fastRoute(ItemDetailScreen(gun: gun, item: item)));
  }
}

/// Opens the shared "peek" bottom sheet for the given entity — a quick
/// preview that avoids growing the navigation stack. Exactly one of
/// [gun] / [item] / [character] / [shrine] should be supplied; the
/// function no-ops if none are. Shared across `RichLinkText`, synergy
/// chips, and back-reference chips so long-press peek feels identical
/// everywhere it's offered.
void showEntityPeekSheet(
  BuildContext context, {
  Gun? gun,
  Item? item,
  Gungeoneer? character,
  Shrine? shrine,
}) {
  if (gun == null && item == null && character == null && shrine == null) {
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.flair.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      if (character != null) return _CharacterPeekSheet(character: character);
      if (shrine != null) return _ShrinePeekSheet(shrine: shrine);
      return _PeekSheet(gun: gun, item: item);
    },
  );
}

// =============================================================================
// _RefChipText — inline tappable text inside a TextSpan run
// =============================================================================

// =============================================================================
// Peek sheet — quick preview of an item/gun without nav-stack growth
// =============================================================================

// =============================================================================
// _CharacterPeekSheet — quick preview of a Gungeoneer
// =============================================================================

// =============================================================================
// _ShrinePeekSheet — quick preview of a Shrine
// =============================================================================

// =============================================================================
// RichBulletList — render a forest of RichBullets as •-prefixed lines
// =============================================================================

// =============================================================================
// WikiSection — collapsible header + bullet list
// =============================================================================
