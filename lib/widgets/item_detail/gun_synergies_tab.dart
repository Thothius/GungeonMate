import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/gun.dart';
import '../../models/synergy.dart';
import '../../providers/run_provider.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/synergy_stats.dart';
import '../../services/haptics.dart';
import '../../theme/tokens.dart';
import '../game_icon.dart';
import '../stat_delta_chips.dart';
import '../skeuo/skeuo_tokens.dart';
import 'entity_synergies_view.dart';
import 'leb_view_scope.dart';

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

  /// Which persisted LEB toggle the ON/OFF chip flips — browse-local
  /// for details pushed from Browse, global everywhere else.
  final LebPrefSource lebSource;

  /// Show the LEB ON/OFF chip. Hidden on owner-scoped run surfaces
  /// where simulation is force-disabled and a toggle would lie.
  final bool showLebToggle;
  const GunSynergiesTab({
    super.key,
    required this.currentName,
    required this.lebView,
    this.lebSource = LebPrefSource.global,
    this.showLebToggle = true,
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

  @override
  void didUpdateWidget(GunSynergiesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-enabling LEB re-arms the one-shot auto-jump so the simulated
    // page lands selected again instead of staying on ALL.
    if (!oldWidget.lebView && widget.lebView) _didInitLeb = false;
  }

  List<SynergyStatus> _statusesFor(
    RunProvider p,
    Set<String> ownedLower, {
    bool perPlayerActive = false,
  }) {
    final coop = p.runState.coop;
    return p
        .getSynergiesFor(widget.currentName)
        .map(
          (s) => SynergyStatus(
            synergy: s,
            missing: s.missingFor(ownedLower),
            // The game evaluates synergies strictly per player — a
            // combined-inventory "active" would mark split pieces as
            // complete when neither player actually has the synergy.
            active: perPlayerActive
                ? (s.matchesOwnedSet(p.ownedNamesLowerMain) ||
                      (coop != null &&
                          s.matchesOwnedSet(p.ownedNamesLowerCoop)))
                : s.matchesOwnedSet(ownedLower),
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

    Widget? flatBody;
    // Solo + no LEB → nothing to page between; render the flat list.
    if (pages.length == 1) {
      flatBody = EntitySynergiesView(
        statuses: _statusesFor(p, p.ownedNamesLowerCombined),
        currentName: widget.currentName,
        ownedLower: p.ownedNamesLowerCombined,
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
        _SynergyHeaderRow(
          pages: pages,
          selected: _page.clamp(0, pages.length - 1),
          onSelect: (i) {
            Haptics.selection();
            _pageCtrl.animateToPage(
              i,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
            );
          },
          showChips: pages.length > 1,
          showLebToggle: widget.showLebToggle,
          lebOn: widget.lebView,
          lebSource: widget.lebSource,
        ),
        if (flatBody != null)
          flatBody
        else
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
                ? p.ownedNamesLowerMain
                : (p.runState.coop == null
                      ? const <String>{}
                      : p.ownedNamesLowerCoop);
        if (owned.isEmpty) {
          return _EmptyPlayerNote(label: key);
        }
        return _scrollable(
          EntitySynergiesView(
            statuses: _statusesFor(p, owned),
            currentName: widget.currentName,
            ownedLower: owned,
          ),
        );
      default:
        return _scrollable(
          EntitySynergiesView(
            statuses: _statusesFor(
              p,
              p.ownedNamesLowerCombined,
              perPlayerActive: hasCoop,
            ),
            currentName: widget.currentName,
            ownedLower: p.ownedNamesLowerCombined,
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
    // Outer padding lives on _SynergyHeaderRow — this is just the chips.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < pages.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          _chip(pages[i], i == selected, () => onSelect(i)),
        ],
      ],
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    final leb = label == 'LEB';
    final color =
        leb
            ? const Color(0xFFB388FF)
            : (active ? Colors.white : Colors.white54);
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
          fontSize: FontSizes.labelMedium,
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

/// Synergies the game hard-excludes from Lich's Eye Bullets simulation
/// (`IgnoreLichEyeBullets` / documented non-simulated cases on the official
/// wiki). Verified: Rubenstein's Monster is flagged so the Gunslinger
/// can't instantly fuse a floor-1 RUBE-ADY into the S-tier fusion weapon;
/// The Submachinist is a dual-wield synergy (both guns must be held —
/// LEB can't simulate that); Detective Mode still requires the Badge for
/// the policeman chest-reveal. Add names as further exceptions are
/// confirmed. Note: 3+-component synergies aren't excluded — LEB counts
/// as ONE component there (e.g. Resourceful Indeed needs Elimentaler +
/// 2 of the 3 rat items), which the simulated view approximates.
const kLebExcludedSynergies = {
  'Rubenstein\'s Monster',
  'The Submachinist',
  'Detective Mode',
};

/// True when the game won't simulate this synergy under Lich's Eye
/// Bullets. Beyond the named [kLebExcludedSynergies], EVERY pure
/// dual-wield synergy is non-simulated (the gun can't actually
/// dual-wield) — except Trigger Twins, whose non-wield bonuses the
/// game still grants per the official wiki.
bool isLebExcludedSynergy(Synergy s) {
  if (kLebExcludedSynergies.contains(s.name)) return true;
  return s.name != 'Trigger Twins' && s.effect.toLowerCase().contains('dual-wield');
}

/// Requirement slots a synergy consumes — one per AND-group, else
/// required items plus the anyOf pool's K-of-N pick count (LEB counts
/// as a single pick, so a 2-of-3 pool is 2 slots).
int lebSlotsNeeded(Synergy s) {
  if (s.groups.isNotEmpty) return s.groups.length;
  return s.items.length + (s.anyOf.isEmpty ? 0 : s.requiredAnyOfCount);
}

/// True when LEB alone can't satisfy the synergy: per the official
/// rules LEB counts as ONE component, so 3+-piece synergies still
/// need real items alongside it (Resourceful Indeed needs Elimentaler
/// + 2 of the 3 rat items; Behold! needs 5 real pieces, etc.).
bool lebNeedsRealPieces(Synergy s) => lebSlotsNeeded(s) >= 3;

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

class _LebPage extends StatefulWidget {
  final String currentName;
  const _LebPage({required this.currentName});

  @override
  State<_LebPage> createState() => _LebPageState();
}

class _LebPageState extends State<_LebPage>
    with SingleTickerProviderStateMixin {
  // One ticker for the whole page — per-row controllers meant N
  // simultaneous repaints for N synergies.
  late final AnimationController _march = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _march.dispose();
    super.dispose();
  }

  List<StatDelta> _lebDeltas(RunProvider p, Gun? curGun, Synergy s) {
    final g = curGun;
    if (g == null) return const [];
    final others = <String>{};
    for (final piece in [...s.items, ...s.anyOf]) {
      final gn = p.gunByName(piece)?.name;
      if (gn != null && gn.toLowerCase() != widget.currentName.toLowerCase()) {
        others.add(gn.toLowerCase());
      }
    }
    return deltasForSynergy(s.effect, g, widget.currentName, others);
  }

  @override
  Widget build(BuildContext context) {
    final currentName = widget.currentName;
    final p = context.read<RunProvider>();
    final allSynergies = p.getSynergiesFor(currentName);
    final synergies = <Synergy>[];
    final needsPieces = <Synergy>[];
    final blocked = <Synergy>[];
    for (final s in allSynergies) {
      if (isLebExcludedSynergy(s)) {
        blocked.add(s);
      } else if (lebNeedsRealPieces(s)) {
        needsPieces.add(s);
      } else {
        synergies.add(s);
      }
    }
    final lebIcon = p.itemByName("Lich's Eye Bullets")?.icon ?? '';
    final curGun = p.gunByName(currentName);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LebHeader(iconPath: lebIcon),
            const SizedBox(height: 10),
            if (synergies.isEmpty && needsPieces.isEmpty)
              _NoLebSynergies()
            else ...[
              for (final s in [...synergies]
                ..sort((a, b) => a.name.compareTo(b.name)))
                _GhostSynergyRow(
                  synergy: s,
                  march: _march,
                  statDeltas: _lebDeltas(p, curGun, s),
                  meta: p.synergyMeta(s.name),
                ),
              if (needsPieces.isNotEmpty)
                _LebNeedsPiecesNote(
                  entries: {
                    for (final s in needsPieces)
                      s.name: lebSlotsNeeded(s) - 1,
                  },
                ),
              if (blocked.isNotEmpty)
                _LebBlockedNote(
                  names: [for (final s in blocked) s.name],
                ),
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
                      fontSize: FontSizes.labelMedium,
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

/// Footnote under the LEB list naming synergies the game excludes
/// from simulation (IgnoreLichEyeBullets) so users know the ghost
/// list isn't claiming them.
class _LebBlockedNote extends StatelessWidget {
  final List<String> names;
  const _LebBlockedNote({required this.names});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: GoopText(
        "LEB can't simulate: ${names.join(', ')} "
        '(excluded by the game).',
        style: TextStyle(
          fontSize: 11.5,
          height: 1.4,
          fontStyle: FontStyle.italic,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Footnote for 3+-component synergies: LEB counts as only ONE piece,
/// so these still need real items alongside it. [entries] maps synergy
/// name → how many real pieces it still requires.
class _LebNeedsPiecesNote extends StatelessWidget {
  final Map<String, int> entries;
  const _LebNeedsPiecesNote({required this.entries});

  @override
  Widget build(BuildContext context) {
    final list =
        entries.entries.map((e) => '${e.key} (+${e.value})').join(', ');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: GoopText(
        'LEB counts as one piece — still needs real items: $list.',
        style: TextStyle(
          fontSize: 11.5,
          height: 1.4,
          fontStyle: FontStyle.italic,
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Ghost/dashed simulated row — visually distinct from real
/// COMPLETE/PARTIAL/LOCKED cards (Q6). The dashed outline marches
/// continuously so simulated panels are obvious at a glance.
class _GhostSynergyRow extends StatelessWidget {
  final Synergy synergy;
  final Animation<double> march;
  final List<StatDelta> statDeltas;
  final SynergyMeta? meta;
  const _GhostSynergyRow({
    required this.synergy,
    required this.march,
    this.statDeltas = const [],
    this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final synergy = this.synergy;
    final accent = Skeuo.inkIf(const Color(0xFFB388FF));
    final extraReq = synergyMayHaveExtraRequirement(synergy);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final p = context.read<RunProvider>();

    return Opacity(
      opacity: 0.85,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.all(Radii.md),
        ),
        child:
            still
                ? CustomPaint(
                  painter: _DashedBorderPainter(
                    color: accent.withValues(alpha: 0.4),
                    radius: Radii.md,
                  ),
                  child: _ghostRowBody(synergy, p, extraReq),
                )
                : AnimatedBuilder(
                  animation: march,
                  // Hoist the body — only the dashed border repaints per
                  // tick instead of rebuilding icon + text every frame.
                  child: _ghostRowBody(synergy, p, extraReq),
                  builder:
                      (_, child) => CustomPaint(
                        painter: _DashedBorderPainter(
                          color: accent.withValues(alpha: 0.4),
                          radius: Radii.md,
                          t: march.value,
                        ),
                        child: child,
                      ),
                ),
      ),
    );
  }

  Widget _ghostRowBody(Synergy synergy, RunProvider p, bool extraReq) {
    var iconPath = synergy.icon;
    if (iconPath.isEmpty && synergy.items.isNotEmpty) {
      final resolved = p.entityByName(synergy.items.first);
      iconPath = resolved.gun?.icon ?? resolved.item?.icon ?? '';
    }
    return Row(
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
                  const _LebPill(),
                ],
              ),
              if (synergy.effect.isNotEmpty) ...[
                const SizedBox(height: 4),
                GoopText(
                  synergy.prettyEffect.isNotEmpty
                      ? synergy.prettyEffect
                      : synergy.effect,
                  style: TextStyle(
                    fontSize: FontSizes.labelMedium,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
              if (statDeltas.isNotEmpty ||
                  (meta?.qb.isNotEmpty ?? false) ||
                  (meta?.fx.isNotEmpty ?? false)) ...[
                const SizedBox(height: 6),
                if (statDeltas.isNotEmpty) StatDeltaChips(deltas: statDeltas),
                if ((meta?.qb.isNotEmpty ?? false) ||
                    (meta?.fx.isNotEmpty ?? false))
                  Padding(
                    padding: EdgeInsets.only(
                      top: statDeltas.isNotEmpty ? 4 : 0,
                    ),
                    child: SynergyMetaChips(meta: meta),
                  ),
              ],
            ],
          ),
        ),
      ],
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
          fontSize: FontSizes.labelSmall,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Minimal dashed rounded-rect border for ghost rows. [t] (0..1)
/// marches the dashes along the path — the LEB "this is simulated"
/// tell.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final Radius radius;
  final double t;
  _DashedBorderPainter({required this.color, required this.radius, this.t = 0});

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
    const dash = 5.0;
    const gap = 4.0;
    final period = dash + gap;
    final shift = (t.clamp(0.0, 1.0) * period) % period;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length + period) {
        final start = dist - shift;
        final end = start + dash;
        if (end > 0 && start < metric.length) {
          final s = start < 0 ? 0.0 : start;
          final e = end > metric.length ? metric.length : end;
          if (e > s) canvas.drawPath(metric.extractPath(s, e), paint);
        }
        dist += period;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius || old.t != t;
}

/// Header row above the synergy pager — page chips on the left
/// (scrollable so ALL/P1/P2/LEB + the LEB toggle never overflow on
/// narrow screens), LEB ON/OFF pill pinned right.
class _SynergyHeaderRow extends StatelessWidget {
  final List<String> pages;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool showChips;
  final bool showLebToggle;
  final bool lebOn;
  final LebPrefSource lebSource;
  const _SynergyHeaderRow({
    required this.pages,
    required this.selected,
    required this.onSelect,
    required this.showChips,
    required this.showLebToggle,
    required this.lebOn,
    required this.lebSource,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Row(
        children: [
          if (showChips)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _PageChips(
                  pages: pages,
                  selected: selected,
                  onSelect: onSelect,
                ),
              ),
            )
          else
            const Spacer(),
          if (showLebToggle) _LebTogglePill(on: lebOn, source: lebSource),
        ],
      ),
    );
  }
}

/// Compact LEB state pill — reflects the live pref and flips it on tap
/// so the simulated view can be toggled from any gun detail without
/// hunting through Settings or Browse.
class _LebTogglePill extends StatelessWidget {
  final bool on;
  final LebPrefSource source;
  const _LebTogglePill({required this.on, required this.source});

  static const _purple = Color(0xFFB388FF);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          on
              ? "Lich's Eye Bullets simulation is ON — tap to disable"
              : "Lich's Eye Bullets simulation is OFF — tap to enable",
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.selection();
          if (source == LebPrefSource.browse) {
            VisualPrefs.setBrowseShowLichEyeBullets(!on);
          } else {
            VisualPrefs.setShowLichEyeBulletsSynergies(!on);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: on ? _purple.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  on
                      ? _purple.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.2),
              width: on ? 1.2 : 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 11,
                color: on ? _purple : Colors.white38,
              ),
              const SizedBox(width: 4),
              GoopText(
                'LEB ${on ? 'ON' : 'OFF'}',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: on ? _purple : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
