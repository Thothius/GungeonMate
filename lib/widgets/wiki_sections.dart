import 'package:flutter/material.dart';

import '../models/rich_text.dart';
import 'rich_link_text.dart';

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
/// Plain (non-sliver) wiki sections — for embedding inside other
/// scrollables/panels (e.g. the gun detail NOTES tab).
List<Widget> buildWikiSections(WikiContent wiki) {
  if (!wiki.hasAny) return const [];
  return [
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
}

List<Widget> buildWikiSlivers(WikiContent wiki) {
  return buildWikiSections(
    wiki,
  ).map((s) => SliverToBoxAdapter(child: s)).toList();
}
