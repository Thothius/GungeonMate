import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gun.dart';
import '../models/gungeoneer.dart';
import '../models/item.dart';
import '../models/rich_text.dart';
import '../models/shrine.dart';
import '../providers/run_provider.dart';
import '../screens/item_detail_screen.dart';
import '../screens/stats_detail_screen.dart';
import '../services/app_theme.dart';
import 'game_icon.dart';
import 'quality_badge.dart';
import 'themed_number.dart';
import 'themed_section_title.dart';

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
    final base = (baseStyle ?? const TextStyle(fontSize: 14, height: 1.4))
        .copyWith(color: baseStyle?.color ?? Colors.white.withValues(alpha: 0.92));
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
      final style = ref.kind == RefKind.lore
          ? base.copyWith(
              color: color,
              fontStyle: FontStyle.italic,
            )
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
        final t = ref.name.toLowerCase() == 'curse'
            ? StatType.curse
            : StatType.coolness;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StatsDetailScreen(statType: t)),
        );
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(gun: gun, item: item),
      ),
    );
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
    backgroundColor: const Color(0xFF1E1E1E),
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

class _RefChipText extends StatelessWidget {
  final String label;
  final Color color;
  final TextStyle baseStyle;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _RefChipText({
    required this.label,
    required this.color,
    required this.baseStyle,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: baseStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: color.withValues(alpha: 0.45),
          decorationThickness: 1.2,
        ),
      ),
    );
  }
}

// =============================================================================
// Peek sheet — quick preview of an item/gun without nav-stack growth
// =============================================================================

class _PeekSheet extends StatelessWidget {
  final Gun? gun;
  final Item? item;
  const _PeekSheet({this.gun, this.item})
      : assert(gun != null || item != null);

  @override
  Widget build(BuildContext context) {
    final name = gun?.name ?? item!.name;
    final quality = gun?.quality ?? item!.quality;
    final subtitle = gun != null ? gun!.type : item!.type;
    final quote = gun?.quote ?? item!.quote;
    final iconPath = gun?.icon ?? item!.icon;
    final body = gun != null ? gun!.notes : item!.effect;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GameIcon(
                  assetPath: iconPath,
                  fallback: gun != null
                      ? Icons.gps_fixed
                      : Icons.inventory_2_outlined,
                  quality: quality,
                  size: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (quality.isNotEmpty) ...[
                            QualityBadge(quality: quality, size: 14),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (quote.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '"$quote"',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withValues(alpha: 0.65),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (body.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                body,
                style: const TextStyle(fontSize: 13.5, height: 1.35),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open detail'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(gun: gun, item: item),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _CharacterPeekSheet — quick preview of a Gungeoneer
// =============================================================================

/// Compact peek for a [Gungeoneer]. Characters have no full detail
/// screen yet, so this sheet is the single canonical preview surface
/// for them. Shows portrait, name, and starting loadout — exactly what
/// a player wonders about when a wiki note mentions another character.
class _CharacterPeekSheet extends StatelessWidget {
  final Gungeoneer character;
  const _CharacterPeekSheet({required this.character});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GameIcon(
                  assetPath: character.icon,
                  fallback: Icons.person,
                  size: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Gungeoneer',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (character.startingGuns.isNotEmpty) ...[
              const SizedBox(height: 12),
              _PeekLoadoutRow(
                icon: Icons.gps_fixed,
                label: 'Starting guns',
                items: character.startingGuns,
              ),
            ],
            if (character.startingItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              _PeekLoadoutRow(
                icon: Icons.inventory_2_outlined,
                label: 'Starting items',
                items: character.startingItems,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeekLoadoutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> items;
  const _PeekLoadoutRow({
    required this.icon,
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                items.join(', '),
                style: const TextStyle(fontSize: 13.5, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _ShrinePeekSheet — quick preview of a Shrine
// =============================================================================

/// Compact peek for a [Shrine]. Surfaces the description / message /
/// effect lines and any auto-applied curse / coolness deltas so the
/// player can decide whether to seek the shrine out, all without
/// leaving the current detail screen.
class _ShrinePeekSheet extends StatelessWidget {
  final Shrine shrine;
  const _ShrinePeekSheet({required this.shrine});

  @override
  Widget build(BuildContext context) {
    final hasDelta = shrine.curse != 0 || shrine.coolness != 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GameIcon(
                  assetPath: shrine.icon,
                  fallback: Icons.temple_buddhist,
                  size: 56,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shrine.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Shrine',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (shrine.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                shrine.description,
                style: const TextStyle(fontSize: 13.5, height: 1.35),
              ),
            ],
            if (shrine.effect.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                shrine.effect,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.3,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
            if (hasDelta) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (shrine.curse != 0)
                    _ShrineDeltaChip(
                      label: 'Curse',
                      value: shrine.curse,
                      color: const Color(0xFFD32F2F),
                    ),
                  if (shrine.curse != 0 && shrine.coolness != 0)
                    const SizedBox(width: 8),
                  if (shrine.coolness != 0)
                    _ShrineDeltaChip(
                      label: 'Coolness',
                      value: shrine.coolness,
                      color: const Color(0xFF29B6F6),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShrineDeltaChip extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ShrineDeltaChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final sign = value > 0 ? '+' : '';
    final txt = value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label ',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          Text(
            '$sign$txt',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RichBulletList — render a forest of RichBullets as •-prefixed lines
// =============================================================================

/// Renders a list of [RichBullet]s as a column of bullet lines (`•`),
/// with nested bullets indented one level deeper. Handles arbitrary depth
/// but in practice wiki content stops at depth 2.
class RichBulletList extends StatelessWidget {
  final List<RichBullet> bullets;
  final TextStyle? baseStyle;
  final EdgeInsetsGeometry padding;

  const RichBulletList({
    super.key,
    required this.bullets,
    this.baseStyle,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (bullets.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          bullets.length,
          (i) => _BulletLine(
            bullet: bullets[i],
            depth: 0,
            siblingIndex: i,
            baseStyle: baseStyle,
          ),
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  final RichBullet bullet;
  final int depth;
  final int siblingIndex;
  final TextStyle? baseStyle;
  const _BulletLine({
    required this.bullet,
    required this.depth,
    this.siblingIndex = 0,
    this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Top-level bullets: themed glyph (✦ for Unicorn, — for Winchester,
    // • for Coolmaxing/default, · for the others).
    // Nested bullets stay neutral so the eye reads depth, not theme,
    // on indented quirks/exceptions.
    final isTop = depth == 0;
    final glyph = isTop
        ? ThemedBullet(
            index: siblingIndex,
            size: _glyphSize(),
          )
        : Icon(
            Icons.fiber_manual_record,
            size: 5,
            color: Colors.white.withValues(alpha: 0.6),
          );
    return Padding(
      padding: EdgeInsets.only(
        left: depth * 18.0,
        top: depth == 0 ? 6 : 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // Wider gutter than the old 6×6 dot needed because some
                // themed glyphs (✦) sit visually larger than a Material
                // circle icon — keep the text column aligned across themes.
                padding: const EdgeInsets.only(top: 1, right: 8),
                child: SizedBox(
                  width: 14,
                  child: Center(child: glyph),
                ),
              ),
              Expanded(
                child: RichLinkText(
                  tokens: bullet.tokens,
                  baseStyle: baseStyle,
                ),
              ),
            ],
          ),
          ...List.generate(bullet.sub.length, (i) {
            return _BulletLine(
              bullet: bullet.sub[i],
              depth: depth + 1,
              siblingIndex: i,
              baseStyle: baseStyle,
            );
          }),
        ],
      ),
    );
  }

  double _glyphSize() {
    // Tuned per-glyph so ✦ doesn't tower over —. The flair's bulletGlyph
    // is read by ThemedBullet itself; here we just choose the rendered
    // point size based on which theme is active.
    final f = AppTheme.flair;
    switch (f.bulletGlyph) {
      case '✦':
        return 11;
      case '—':
        return 12;
      case '·':
        return 14;
      default:
        return 8;
    }
  }
}

// =============================================================================
// WikiSection — collapsible header + bullet list
// =============================================================================

/// Self-contained accordion-style section: bold header with count badge,
/// optional collapse-by-default for long lists. Used for Notes / Trivia /
/// Item Interactions / Effects on the detail screen.
class WikiSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<RichBullet> bullets;

  /// If [bullets].length exceeds this, the section starts collapsed.
  /// 0 disables collapsing (always expanded).
  final int collapseThreshold;

  const WikiSection({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bullets,
    this.collapseThreshold = 4,
  });

  @override
  State<WikiSection> createState() => _WikiSectionState();
}

class _WikiSectionState extends State<WikiSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.collapseThreshold == 0 ||
        widget.bullets.length <= widget.collapseThreshold;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bullets.isEmpty) return const SizedBox.shrink();
    final canCollapse = widget.collapseThreshold > 0 &&
        widget.bullets.length > widget.collapseThreshold;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: canCollapse
                    ? () => setState(() => _expanded = !_expanded)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: ThemedSectionTitle(
                    icon: widget.icon,
                    iconColor: widget.iconColor,
                    title: widget.title,
                    count: widget.bullets.length,
                    trailing: canCollapse
                        ? Icon(
                            _expanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 22,
                            color: Colors.white54,
                          )
                        : null,
                  ),
                ),
              ),
              if (_expanded) ...[
                const SizedBox(height: 4),
                RichBulletList(bullets: widget.bullets),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
