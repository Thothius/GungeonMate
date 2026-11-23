import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/synergy_stats.dart';
import '../../theme/tokens.dart';
import '../game_icon.dart';
import '../stat_delta_chips.dart';

import '../state_widgets.dart';

/// Grouped synergy list — COMPLETE / PARTIAL / LOCKED against a given
/// owned set. Shared by the gun detail pager pages (ALL / P1 / P2) and
/// the item detail flat list, so every entity shows its FULL synergy
/// list instead of only the currently-active subset.
class EntitySynergiesView extends StatelessWidget {
  final List<SynergyStatus> statuses;
  final String currentName;

  /// Lowercased owned names for the view's own inventory slice — drives
  /// the missing-piece icon. The statuses' `active`/`missing` fields
  /// must already be computed against the same slice.
  final Set<String> ownedLower;

  /// When true, each row shows a P1 / P2 / P1+P2 / NONE owner pill
  /// (which players own at least one other piece of the synergy).
  final bool showOwnerPills;

  /// Optional override for the owners label — per-player pages pass a
  /// fixed label so rows don't imply combined ownership.
  final String? ownerLabelOverride;

  const EntitySynergiesView({
    super.key,
    required this.statuses,
    required this.currentName,
    required this.ownedLower,
    this.showOwnerPills = true,
    this.ownerLabelOverride,
  });

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) {
      return const _EmptySynergies();
    }
    final p = context.read<RunProvider>();
    final curGun = p.gunByName(currentName);
    List<StatDelta> deltasFor(SynergyStatus st) {
      final g = curGun;
      if (g == null) return const [];
      final others = <String>{};
      for (final piece in [...st.synergy.items, ...st.synergy.anyOf]) {
        final gn = p.gunByName(piece)?.name;
        if (gn != null && gn.toLowerCase() != currentName.toLowerCase()) {
          others.add(gn.toLowerCase());
        }
      }
      return deltasForSynergy(st.synergy.effect, g, currentName, others);
    }

    final mainNames =
        p.runState.main.allItemNames.map((n) => n.toLowerCase()).toSet();
    final coop = p.runState.coop;
    final coopNames =
        coop == null
            ? const <String>{}
            : coop.allItemNames.map((n) => n.toLowerCase()).toSet();

    final complete = <SynergyStatus>[];
    final partial = <SynergyStatus>[];
    final locked = <SynergyStatus>[];
    for (final st in statuses) {
      if (st.active) {
        complete.add(st);
      } else if (_hasAnyPiece(st, ownedLower, currentName)) {
        partial.add(st);
      } else {
        locked.add(st);
      }
    }

    String ownersOf(SynergyStatus st) {
      if (ownerLabelOverride != null) return ownerLabelOverride!;
      final s = st.synergy;
      var p1 = false, p2 = false;
      for (final piece in [...s.items, ...s.anyOf]) {
        final pl = piece.toLowerCase();
        if (pl == currentName.toLowerCase()) continue;
        if (mainNames.contains(pl)) p1 = true;
        if (coopNames.contains(pl)) p2 = true;
      }
      if (!p1 && !p2) return 'NONE';
      return coop == null
          ? 'P1'
          : (p1 && p2
              ? 'P1+P2'
              : p2
              ? 'P2'
              : 'P1');
    }

    Widget rowsFor(
      List<SynergyStatus> group, {
      String? owners,
      bool locked = false,
    }) {
      return Column(
        children: [
          for (final st in group)
            _SynergyRow(
              status: st,
              owners: owners ?? ownersOf(st),
              missing: _firstMissing(st, ownedLower, currentName),
              p: p,
              showOwnerPill: showOwnerPills,
              locked: locked,
              statDeltas: deltasFor(st),
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (complete.isNotEmpty) ...[
            _GroupHeader(
              label: 'COMPLETE',
              color: Colors.greenAccent,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(height: 6),
            rowsFor(complete),
          ],
          if (partial.isNotEmpty) ...[
            if (complete.isNotEmpty) const SizedBox(height: 14),
            _GroupHeader(
              label: 'PARTIAL',
              color: Colors.amberAccent,
              icon: Icons.pie_chart_outline_rounded,
            ),
            const SizedBox(height: 6),
            rowsFor(partial),
          ],
          if (locked.isNotEmpty) ...[
            if (complete.isNotEmpty || partial.isNotEmpty)
              const SizedBox(height: 14),
            _GroupHeader(
              label: 'LOCKED',
              color: Colors.white38,
              icon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 6),
            rowsFor(locked, locked: true),
          ],
        ],
      ),
    );
  }

  /// True when the player owns at least one OTHER piece of this
  /// synergy (the current entity doesn't count — they have it already).
  static bool _hasAnyPiece(
    SynergyStatus st,
    Set<String> owned,
    String currentName,
  ) {
    final cur = currentName.toLowerCase();
    for (final piece in [...st.synergy.items, ...st.synergy.anyOf]) {
      final pl = piece.toLowerCase();
      if (pl != cur && owned.contains(pl)) return true;
    }
    return false;
  }

  /// First unowned required piece — drives the "missing item" icon.
  static String _firstMissing(
    SynergyStatus st,
    Set<String> owned,
    String currentName,
  ) {
    final cur = currentName.toLowerCase();
    for (final piece in st.synergy.items) {
      final pl = piece.toLowerCase();
      if (pl != cur && !owned.contains(pl)) return piece;
    }
    for (final piece in st.synergy.anyOf) {
      final pl = piece.toLowerCase();
      if (pl != cur && !owned.contains(pl)) return piece;
    }
    return currentName;
  }
}

class _EmptySynergies extends StatelessWidget {
  const _EmptySynergies();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: EmptyState(
        icon: Icons.hub_outlined,
        message: 'No synergies to show.',
        flavor: 'This gun keeps to itself.',
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _GroupHeader({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        GoopText(
          label,
          style: TextStyle(
            fontSize: FontSizes.labelSmall,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
            color: color.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _SynergyRow extends StatefulWidget {
  final SynergyStatus status;
  final String owners;
  final String? missing;
  final RunProvider p;
  final bool showOwnerPill;

  /// LOCKED group rows render neutral — amber is reserved for
  /// PARTIAL progress so locked doesn't read as "almost there".
  final bool locked;

  /// Parsed stat deltas for the current gun (empty for items / no mods).
  final List<StatDelta> statDeltas;
  const _SynergyRow({
    required this.status,
    required this.owners,
    required this.missing,
    required this.p,
    this.showOwnerPill = true,
    this.locked = false,
    this.statDeltas = const [],
  });

  @override
  State<_SynergyRow> createState() => _SynergyRowState();
}

class _SynergyRowState extends State<_SynergyRow> {
  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    final s = status.synergy;
    final p = widget.p;
    final missing = widget.missing;
    // Icon: the missing piece for partials/locked, the synergy's own icon
    // (or first piece) for completes.
    var iconPath = s.icon;
    var iconName = missing ?? '';
    if (missing != null) {
      final resolved = p.entityByName(missing);
      iconPath = resolved.gun?.icon ?? resolved.item?.icon ?? iconPath;
      iconName = missing;
    } else if (iconPath.isEmpty && s.items.isNotEmpty) {
      final resolved = p.entityByName(s.items.first);
      iconPath = resolved.gun?.icon ?? resolved.item?.icon ?? '';
    }

    final meta = p.synergyMeta(s.name);
    final accent =
        widget.locked
            ? Colors.white38
            : status.active
            ? Colors.greenAccent
            : Colors.amberAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: iconName.isNotEmpty ? iconName : s.name,
            child: GameIcon(
              assetPath: iconPath,
              fallback: Icons.hub_outlined,
              quality: '',
              size: 40,
              showRing: false,
            ),
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
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (widget.showOwnerPill) _OwnerPill(label: widget.owners),
                  ],
                ),
                if (s.effect.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  GoopText(
                    s.prettyEffect.isNotEmpty ? s.prettyEffect : s.effect,
                    style: TextStyle(
                      fontSize: FontSizes.labelMedium,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
                if (widget.statDeltas.isNotEmpty ||
                    (meta?.qb.isNotEmpty ?? false) ||
                    (meta?.fx.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 6),
                  if (widget.statDeltas.isNotEmpty)
                    StatDeltaChips(deltas: widget.statDeltas),
                  if ((meta?.qb.isNotEmpty ?? false) ||
                      (meta?.fx.isNotEmpty ?? false))
                    Padding(
                      padding: EdgeInsets.only(
                        top: widget.statDeltas.isNotEmpty ? 4 : 0,
                      ),
                      child: SynergyMetaChips(meta: meta),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerPill extends StatelessWidget {
  final String label;
  const _OwnerPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final color =
        label == 'NONE'
            ? Colors.white38
            : label.contains('+')
            ? Colors.cyanAccent
            : label == 'P2'
            ? Colors.orangeAccent
            : Colors.lightGreenAccent;
    return Container(
      padding: ChipStyle.paddingMicro,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ChipStyle.radiusMicro),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: GoopText(
        label,
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
