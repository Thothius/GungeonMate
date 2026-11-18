import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/synergy.dart';
import '../../providers/run_provider.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../theme/tokens.dart';
import '../game_icon.dart';
import '../skeuo/skeuo_tokens.dart';
import 'entity_synergies_view.dart';

/// SYNERGIES section for gun detail — a swipeable pager:
///
/// * **ALL** — every synergy grouped COMPLETE / PARTIAL / LOCKED against
///   the combined P1+P2 inventory, with owner pills showing which
///   player(s) hold pieces.
/// * **P1 / P2** — the same grouping computed against that player's
///   inventory only (co-op runs only; empty players show just a label).
/// * **LEB** — Lich's Eye Bullets simulated view: every synergy the gun
///   participates in as a ghost/dashed row, with EXTRA REQ chips where
///   the effect text implies additional requirements. Only present when
///   the resolved [lebView] context allows simulation (catalog/browse/
///   codex on, active-run surfaces off).
class GunSynergiesTab extends StatefulWidget {
  final String currentName;

  /// Whether the LEB simulated page is offered (and starts selected).
  /// Resolved by ItemDetailScreen from the lebView param / prefs.
  final bool lebView;
  const GunSynergiesTab({
    super.key,
    required this.currentName,
    required this.lebView,
  });

  @override
  State<GunSynergiesTab> createState() => _GunSynergiesTabState();
}

class _GunSynergiesTabState extends State<GunSynergiesTab> {
  final _pageCtrl = PageController();
  int _page = 0;
  bool _didInitLeb = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  List<SynergyStatus> _statusesFor(
    RunProvider p,
    List<String> ownedNames,
  ) {
    final ownedLower = ownedNames.map((n) => n.toLowerCase()).toSet();
    return p
        .getSynergiesFor(widget.currentName)
        .map(
          (s) => SynergyStatus(
            synergy: s,
            missing: s.missingFor(ownedLower),
            active: s.matchesItems(ownedNames),
          ),
        )
        .toList()
      ..sort((a, b) {
        if (a.active != b.active) return a.active ? -1 : 1;
        return a.missing.length.compareTo(b.missing.length);
      });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final coop = p.runState.coop;
    final hasCoop = coop != null;

    // Page keys in display order — LEB last so ALL stays the default
    // landing view even when simulation is enabled.
    final pages = <String>['ALL'];
    if (hasCoop) pages.addAll(['P1', 'P2']);
    if (widget.lebView) pages.add('LEB');

    // Solo + no LEB → nothing to page between; render the flat list.
    if (pages.length == 1) {
      final owned = p.runState.allItemNames;
      return EntitySynergiesView(
        statuses: _statusesFor(p, owned),
        currentName: widget.currentName,
        ownedLower: owned.map((n) => n.toLowerCase()).toSet(),
      );
    }

    // LEB-enabled contexts land on the simulated page — that's the
    // "every gun has the list by default" ask. ALL/P1/P2 remain one
    // swipe away for real-state inspection. Jump once, then leave the
    // user in control of the pager.
    if (widget.lebView && !_didInitLeb && pages.last == 'LEB') {
      _didInitLeb = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageCtrl.hasClients) {
          _pageCtrl.jumpToPage(pages.length - 1);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageChips(
          pages: pages,
          selected: _page,
          onSelect: (i) {
            Haptics.selection();
            _pageCtrl.animateToPage(
              i,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
            );
          },
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.52,
          child: PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: pages.length,
            itemBuilder: (context, i) {
              final key = pages[i];
              return _pageFor(key, p, coop != null);
            },
          ),
        ),
      ],
    );
  }

  Widget _pageFor(String key, RunProvider p, bool hasCoop) {
    switch (key) {
      case 'LEB':
        return _LebPage(currentName: widget.currentName);
      case 'P1':
      case 'P2':
        final owned =
            key == 'P1'
                ? p.runState.main.allItemNames
                : (p.runState.coop?.allItemNames ?? const <String>[]);
        if (owned.isEmpty) {
          return _EmptyPlayerNote(label: key);
        }
        return _scrollable(
          EntitySynergiesView(
            statuses: _statusesFor(p, owned),
            currentName: widget.currentName,
            ownedLower: owned.map((n) => n.toLowerCase()).toSet(),
          ),
        );
      default:
        final owned = p.runState.allItemNames;
        return _scrollable(
          EntitySynergiesView(
            statuses: _statusesFor(p, owned),
            currentName: widget.currentName,
            ownedLower: owned.map((n) => n.toLowerCase()).toSet(),
          ),
        );
    }
  }

  Widget _scrollable(Widget child) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: child,
    );
  }
}

class _PageChips extends StatelessWidget {
  final List<String> pages;
  final int selected;
  final ValueChanged<int> onSelect;
  const _PageChips({
    required this.pages,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Row(
        children: [
          for (var i = 0; i < pages.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _chip(pages[i], i == selected, () => onSelect(i)),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    final leb = label == 'LEB';
    final color =
        leb ? const Color(0xFFB388FF) : (active ? Colors.white : Colors.white54);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color:
              active
                  ? (leb
                      ? const Color(0xFFB388FF).withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.12))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                active
                    ? color.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.18),
            width: active ? 1.2 : 0.8,
          ),
        ),
        child: GoopText(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// P1/P2 page when that player holds nothing — label only, per spec.
class _EmptyPlayerNote extends StatelessWidget {
  final String label;
  const _EmptyPlayerNote({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GoopText(
        '$label has no items yet.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.4),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LEB simulated page
// ---------------------------------------------------------------------------

/// True when the synergy's effect text implies extra requirements under
/// Lich's Eye Bullets (conditionals, per-count scaling, replacements).
/// Heuristic — the JSON carries no structured requirement flag.
bool synergyMayHaveExtraRequirement(Synergy s) {
  final t = s.effect.toLowerCase();
  const keys = [
    'requires',
    'only if',
    'only when',
    'while ',
    ' per ',
    'each ',
    'every ',
    'after ',
    'once per',
    'at least',
    'instead',
    'replaces',
    'cannot ',
    ' out of ',
    'when ',
    'if ',
  ];
  return keys.any(t.contains);
}

class _LebPage extends StatelessWidget {
  final String currentName;
  const _LebPage({required this.currentName});

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();
    final synergies = p.getSynergiesFor(currentName);
    final lebIcon = p.itemByName("Lich's Eye Bullets")?.icon ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LebHeader(iconPath: lebIcon),
            const SizedBox(height: 10),
            if (synergies.isEmpty)
              _NoLebSynergies()
            else ...[
              for (final s in [...synergies]
                ..sort((a, b) => a.name.compareTo(b.name)))
                _GhostSynergyRow(synergy: s),
            ],
          ],
        ),
      ),
    );
  }
}

class _LebHeader extends StatelessWidget {
  final String iconPath;
  const _LebHeader({required this.iconPath});

  @override
  Widget build(BuildContext context) {
    final accent = Skeuo.inkIf(const Color(0xFFB388FF));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameIcon(
          assetPath: iconPath,
          fallback: Icons.auto_awesome,
          quality: 'S',
          size: 40,
          showRing: false,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: GoopText(
                      "LICH'S EYE BULLETS",
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        color: accent,
                      ),
                    ),
                  ),
                  _InfoButton(onTap: () => _showLebExplainer(context)),
                ],
              ),
              const SizedBox(height: 2),
              GoopText(
                'Simulated — this gun acts as if it has every synergy. '
                'Some synergies have extra requirements.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.3,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoButton extends StatelessWidget {
  final VoidCallback onTap;
  const _InfoButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(
          Icons.info_outline_rounded,
          size: 16,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// In-app explainer (Q11) — pulls the LEB item's own effect + wiki
/// notes so the rules text ships with the data, not hardcoded.
void _showLebExplainer(BuildContext context) {
  final p = context.read<RunProvider>();
  final leb = p.itemByName("Lich's Eye Bullets");
  final notes =
      leb?.wiki.notes.map((b) => b.plainText).where((t) => t.isNotEmpty) ??
      const <String>[];
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppTheme.flair.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder:
        (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  "LICH'S EYE BULLETS",
                  style: TextStyle(
                    fontSize: FontSizes.labelSmall,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: Skeuo.inkIf(const Color(0xFFB388FF)),
                  ),
                ),
                const SizedBox(height: 8),
                if (leb?.effect.isNotEmpty ?? false)
                  GoopText(
                    leb!.effect,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                for (final n in notes) ...[
                  const SizedBox(height: 8),
                  GoopText(
                    '• $n',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                GoopText(
                  'Rows marked EXTRA REQ may need additional items or '
                  'conditions that LEB does not simulate.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

/// Zero-synergy gun under LEB — header stays, honest note instead of
/// the generic empty state (Q3).
class _NoLebSynergies extends StatelessWidget {
  const _NoLebSynergies();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: GoopText(
        'This gun has no synergies — even Lich\'s Eye Bullets '
        'can\'t help it.',
        style: TextStyle(
          fontSize: 12.5,
          height: 1.4,
          fontStyle: FontStyle.italic,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

/// Ghost/dashed simulated row — visually distinct from real
/// COMPLETE/PARTIAL/LOCKED cards (Q6).
class _GhostSynergyRow extends StatelessWidget {
  final Synergy synergy;
  const _GhostSynergyRow({required this.synergy});

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();
    final accent = Skeuo.inkIf(const Color(0xFFB388FF));
    final extraReq = synergyMayHaveExtraRequirement(synergy);

    var iconPath = synergy.icon;
    if (iconPath.isEmpty && synergy.items.isNotEmpty) {
      final resolved = p.entityByName(synergy.items.first);
      iconPath = resolved.gun?.icon ?? resolved.item?.icon ?? '';
    }

    return Opacity(
      opacity: 0.85,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.all(Radii.md),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: accent.withValues(alpha: 0.4),
            radius: Radii.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameIcon(
                assetPath: iconPath,
                fallback: Icons.hub_outlined,
                quality: '',
                size: 40,
                showRing: false,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GoopText(
                            synergy.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (extraReq)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Tooltip(
                              message:
                                  'May have extra requirements under '
                                  "Lich's Eye Bullets",
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: GoopText(
                                  'EXTRA REQ',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                    color: Skeuo.inkIf(Colors.amberAccent),
                                  ),
                                ),
                              ),
                            ),
                      ),
                      _LebPill(),
                      ],
                    ),
                    if (synergy.effect.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      GoopText(
                        synergy.prettyEffect.isNotEmpty
                            ? synergy.prettyEffect
                            : synergy.effect,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LebPill extends StatelessWidget {
  const _LebPill();

  @override
  Widget build(BuildContext context) {
    final color = Skeuo.inkIf(const Color(0xFFB388FF));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: GoopText(
        'LEB',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Minimal dashed rounded-rect border for ghost rows.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final Radius radius;
  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius.x),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      const dash = 5.0;
      const gap = 4.0;
      while (dist < metric.length) {
        canvas.drawPath(
          metric.extractPath(dist, (dist + dash).clamp(0, metric.length)),
          paint,
        );
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
