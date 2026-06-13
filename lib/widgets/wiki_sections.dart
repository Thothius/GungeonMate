import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rich_text.dart';
import '../providers/run_provider.dart';
import '../screens/item_detail_screen.dart';
import 'game_icon.dart';
import 'rich_link_text.dart';
import 'themed_section_title.dart';

// =============================================================================
// Wiki-content slivers — Effects / Item Interactions / Notes / Tips / Trivia
// =============================================================================

/// Build the slivers that render the rich wiki sections for the current
/// entity. Sections that are empty (missing from cache) emit nothing,
/// which lets the layout stay tight for entries with thin coverage.
///
/// Order is deliberate: most-actionable content first.
///   1. Effects        — concrete mechanic bullets (often expands the
///                       single-line `effect` text into specifics).
///   2. Item Interactions — non-synergy interactions with other items.
///   3. Notes          — gameplay quirks, edge cases, niche behaviour.
///   4. Tips           — strategy advice (rare on wiki.gg, kept for
///                       forward-compat with future scrape passes).
/// Trivia is intentionally omitted — flavour-only content that pushes the
/// useful information off-screen.
List<Widget> buildWikiSlivers(WikiContent wiki) {
  if (!wiki.hasAny) return const [];
  final sections = <Widget>[
    if (wiki.effects.isNotEmpty)
      WikiSection(
        title: 'Effects',
        icon: Icons.auto_awesome,
        iconColor: Colors.lightGreenAccent,
        bullets: wiki.effects,
        collapseThreshold: 0,
      ),
    if (wiki.interactions.isNotEmpty)
      WikiSection(
        title: 'Item Interactions',
        icon: Icons.compare_arrows,
        iconColor: Colors.cyanAccent,
        bullets: wiki.interactions,
        collapseThreshold: 0,
      ),
    if (wiki.notes.isNotEmpty)
      WikiSection(
        title: 'Notes',
        icon: Icons.sticky_note_2_outlined,
        iconColor: Colors.amberAccent,
        bullets: wiki.notes,
      ),
    if (wiki.tips.isNotEmpty)
      WikiSection(
        title: 'Tips',
        icon: Icons.tips_and_updates_outlined,
        iconColor: Colors.lightBlueAccent,
        bullets: wiki.tips,
      ),
  ];
  return sections.map((s) => SliverToBoxAdapter(child: s)).toList();
}

// =============================================================================
// Referenced By — entities whose own wiki content mentions this one
// =============================================================================

/// Reverse-index card: which other guns/items refer to *this* one in
/// their wiki notes. Populated from `back_refs.json`.
///
/// Each referrer is resolved against the master data and grouped into
/// **Guns** / **Items** / **Other** so a heavy ref list (Duct Tape has
/// 33) becomes scannable instead of a wall. Each group caps at the
/// first 8 chips by default with a `Show all (N)` toggle for the
/// remainder — keeps the page short for the common case while still
/// letting power-users expand.
class ReferencedBySection extends StatefulWidget {
  final List<String> referrers;
  const ReferencedBySection({super.key, required this.referrers});

  @override
  State<ReferencedBySection> createState() => _ReferencedBySectionState();
}

class _ReferencedBySectionState extends State<ReferencedBySection> {
  /// Collapser threshold — groups longer than this start collapsed.
  /// Tuned so the common case (≤8 refs in a group) never shows a
  /// `Show all` toggle.
  static const int _collapseThreshold = 8;

  /// Per-group "expanded?" state. Keyed by group label so adding new
  /// kinds in future doesn't shuffle existing toggles.
  final Map<String, bool> _expanded = {};

  /// Number of groups whose ref count exceeds [_collapseThreshold] —
  /// i.e. groups that *would* render their own per-group `Show all`
  /// chip. The master toggle only surfaces when this is ≥2 (so it
  /// genuinely saves taps over flipping each group individually).
  int _collapsibleGroupCount(
    List<String> guns,
    List<String> items,
    List<String> other,
  ) {
    var n = 0;
    if (guns.length > _collapseThreshold) n++;
    if (items.length > _collapseThreshold) n++;
    if (other.length > _collapseThreshold) n++;
    return n;
  }

  /// True when every collapsible group is currently expanded. Drives
  /// the toggle's "Expand all" ↔ "Collapse all" label flip.
  bool _allGroupsExpanded(
    List<String> guns,
    List<String> items,
    List<String> other,
  ) {
    bool ok(String label, List<String> list) {
      if (list.length <= _collapseThreshold) return true;
      return _expanded[label] == true;
    }
    return ok('Guns', guns) && ok('Items', items) && ok('Other', other);
  }

  void _toggleAll(
    List<String> guns,
    List<String> items,
    List<String> other,
  ) {
    final expand = !_allGroupsExpanded(guns, items, other);
    setState(() {
      if (guns.length > _collapseThreshold) _expanded['Guns'] = expand;
      if (items.length > _collapseThreshold) _expanded['Items'] = expand;
      if (other.length > _collapseThreshold) _expanded['Other'] = expand;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.referrers.isEmpty) return const SizedBox.shrink();
    final p = context.read<RunProvider>();

    final guns = <String>[];
    final items = <String>[];
    final other = <String>[];
    for (final n in widget.referrers) {
      final resolved = p.entityByName(n);
      if (resolved.gun != null) {
        guns.add(n);
      } else if (resolved.item != null) {
        items.add(n);
      } else {
        // Names that didn't resolve (unlikely — back_refs is built from
        // master data) still get rendered so we don't silently drop
        // them; they'll just render as plain pills.
        other.add(n);
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ThemedSectionTitle(
                icon: Icons.share_outlined,
                iconColor: Colors.lightBlueAccent,
                title: 'Referenced by',
                count: widget.referrers.length,
                // Master expand/collapse toggle. Surfaces only when at
                // least two groups would individually need their own
                // `Show all` chip — for shorter ref lists the per-group
                // chips are already enough.
                trailing: _collapsibleGroupCount(guns, items, other) >= 2
                    ? _MasterToggle(
                        allExpanded:
                            _allGroupsExpanded(guns, items, other),
                        onTap: () => _toggleAll(guns, items, other),
                      )
                    : null,
              ),
              const SizedBox(height: 4),
              if (guns.isNotEmpty) _buildGroup('Guns', guns),
              if (items.isNotEmpty) _buildGroup('Items', items),
              if (other.isNotEmpty) _buildGroup('Other', other),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(String label, List<String> names) {
    final expanded = _expanded[label] ?? false;
    final shouldCollapse = names.length > _collapseThreshold && !expanded;
    final visible = shouldCollapse
        ? names.take(_collapseThreshold).toList()
        : names;
    final hiddenCount = names.length - visible.length;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${label.toUpperCase()}  ·  ${names.length}',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final n in visible) BackRefChip(name: n),
              if (hiddenCount > 0)
                _ShowMoreChip(
                  hiddenCount: hiddenCount,
                  onTap: () => setState(() => _expanded[label] = true),
                ),
              if (expanded && names.length > _collapseThreshold)
                _ShowMoreChip(
                  collapse: true,
                  onTap: () => setState(() => _expanded[label] = false),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small sibling of [BackRefChip] that toggles the parent group between
/// collapsed (first 8) and fully expanded. Renders with a quiet outline
/// so it reads as an affordance, not a content chip.
class _ShowMoreChip extends StatelessWidget {
  final int hiddenCount;
  final bool collapse;
  final VoidCallback onTap;
  const _ShowMoreChip({
    this.hiddenCount = 0,
    this.collapse = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = collapse ? 'Show less' : 'Show all (+$hiddenCount)';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.lightBlueAccent.withValues(alpha: 0.45),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                collapse ? Icons.expand_less : Icons.expand_more,
                size: 14,
                color: Colors.lightBlueAccent.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.lightBlueAccent.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One-tap "Expand all groups" / "Collapse all groups" affordance shown
/// in the [ReferencedBySection] header when at least two groups are
/// individually collapsible. Sits opposite the title so it never
/// crowds the count, and uses a quieter outline than the per-group
/// `Show all` chips so the eye still treats those as the primary
/// drilldown.
class _MasterToggle extends StatelessWidget {
  final bool allExpanded;
  final VoidCallback onTap;
  const _MasterToggle({
    required this.allExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = allExpanded ? 'Collapse all' : 'Expand all';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                allExpanded ? Icons.unfold_less : Icons.unfold_more,
                size: 14,
                color: Colors.lightBlueAccent.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.lightBlueAccent.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single tappable chip used inside [ReferencedBySection]. Resolves the
/// referenced entity once via the indexed name maps on [RunProvider]
/// (no list scan), and renders a quality-tinted `GameIcon` plus the
/// canonical name.
class BackRefChip extends StatelessWidget {
  final String name;
  const BackRefChip({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();
    // O(1) lookup via the indexed name maps. We accept a no-op tap if
    // for some reason the back-ref points to a name we don't have
    // (shouldn't happen since the index was built from our master data).
    final resolved = p.entityByName(name);
    final g = resolved.gun;
    final it = resolved.item;
    final quality = g?.quality ?? it?.quality ?? '';
    final iconPath = g?.icon ?? it?.icon ?? '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (g == null && it == null) return;
          FocusManager.instance.primaryFocus?.unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemDetailScreen(gun: g, item: it),
            ),
          );
        },
        // Matches the peek affordance on synergy chips and inline rich-
        // link refs — long-press anywhere a reference shows up to see a
        // quick preview without leaving the current detail page.
        onLongPress: () {
          if (g == null && it == null) return;
          FocusManager.instance.primaryFocus?.unfocus();
          showEntityPeekSheet(context, gun: g, item: it);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconPath.isNotEmpty) ...[
                GameIcon(
                  assetPath: iconPath,
                  fallback: g != null
                      ? Icons.gps_fixed
                      : Icons.inventory_2_outlined,
                  quality: quality,
                  size: 22,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
