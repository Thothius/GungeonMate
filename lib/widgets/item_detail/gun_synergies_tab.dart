import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/goop_talk_engine.dart';
import '../../theme/tokens.dart';
import '../game_icon.dart';
import '../state_widgets.dart';
import '../skeuo/skeuo_tokens.dart';

/// SYNERGIES tab for gun detail — grouped COMPLETE (all pieces owned)
/// then PARTIAL (≥1 owned, ≥1 missing). Each row shows the missing
/// piece's icon, the synergy name, its effects, and an owner pill
/// (P1 / P2 / P1+P2) matching the browse synergies view.
class GunSynergiesTab extends StatelessWidget {
  final List<SynergyStatus> statuses;
  final String currentName;
  const GunSynergiesTab({
    super.key,
    required this.statuses,
    required this.currentName,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();
    final mainNames =
        p.runState.main.allItemNames.map((n) => n.toLowerCase()).toSet();
    final coop = p.runState.coop;
    final coopNames =
        coop == null
            ? const <String>{}
            : coop.allItemNames.map((n) => n.toLowerCase()).toSet();
    final owned = p.currentOwnedLower;

    final complete = <SynergyStatus>[];
    final partial = <SynergyStatus>[];
    for (final st in statuses) {
      if (st.active) {
        complete.add(st);
      } else if (_hasAnyPiece(st, owned, currentName)) {
        partial.add(st);
      }
    }

    if (complete.isEmpty && partial.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          icon: Icons.hub_outlined,
          message: 'No synergies to show.',
          flavor: 'This gun keeps to itself.',
        ),
      );
    }

    String ownersOf(SynergyStatus st) {
      final s = st.synergy;
      var p1 = false, p2 = false;
      for (final piece in [...s.items, ...s.anyOf]) {
        final pl = piece.toLowerCase();
        if (pl == currentName.toLowerCase()) continue;
        if (mainNames.contains(pl)) p1 = true;
        if (coopNames.contains(pl)) p2 = true;
      }
      return coop == null
          ? 'P1'
          : (p1 && p2
              ? 'P1+P2'
              : p2
              ? 'P2'
              : 'P1');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (complete.isNotEmpty) ...[
            _GroupHeader(
              label: 'COMPLETE',
              color: Skeuo.inkIf(Colors.greenAccent),
              icon: Icons.check_circle_rounded,
            ),
            SizedBox(height: 6),
            for (final st in complete)
              _SynergyRow(
                status: st,
                owners: ownersOf(st),
                missing: null,
                p: p,
              ),
          ],
          if (partial.isNotEmpty) ...[
            SizedBox(height: 14),
            _GroupHeader(
              label: 'PARTIAL',
              color: Skeuo.inkIf(Colors.amberAccent),
              icon: Icons.pie_chart_outline_rounded,
            ),
            const SizedBox(height: 6),
            for (final st in partial)
              _SynergyRow(
                status: st,
                owners: ownersOf(st),
                missing: _firstMissing(st, owned, currentName),
                p: p,
              ),
          ],
        ],
      ),
    );
  }

  /// True when the player owns at least one OTHER piece of this
  /// synergy (the current gun doesn't count — they have it already).
  static bool _hasAnyPiece(
    SynergyStatus st,
    final Set<String> owned,
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
    final Set<String> owned,
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

class _SynergyRow extends StatelessWidget {
  final SynergyStatus status;
  final String owners;
  final String? missing;
  final RunProvider p;
  const _SynergyRow({
    required this.status,
    required this.owners,
    required this.missing,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.synergy;
    // Icon: the missing piece for partials, the synergy's own icon
    // (or first piece) for completes.
    var iconPath = s.icon;
    var iconName = missing ?? '';
    if (missing != null) {
      final resolved = p.entityByName(missing!);
      iconPath = resolved.gun?.icon ?? resolved.item?.icon ?? iconPath;
      iconName = missing!;
    } else if (iconPath.isEmpty && s.items.isNotEmpty) {
      final resolved = p.entityByName(s.items.first);
      iconPath = resolved.gun?.icon ?? resolved.item?.icon ?? '';
    }

    final accent =
        status.active
            ? Skeuo.inkIf(Colors.greenAccent)
            : Skeuo.inkIf(Colors.amberAccent);

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
          SizedBox(width: 10),
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
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Skeuo.collapse(Colors.white),
                        ),
                      ),
                    ),
                    _OwnerPill(label: owners),
                  ],
                ),
                if (s.effect.isNotEmpty) ...[
                  SizedBox(height: 4),
                  GoopText(
                    s.effect,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Skeuo.collapse(
                        Colors.white,
                      ).withValues(alpha: 0.65),
                    ),
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
        label.contains('+')
            ? Skeuo.inkIf(Colors.cyanAccent)
            : label == 'P2'
            ? Skeuo.inkIf(Colors.orangeAccent)
            : Skeuo.inkIf(Colors.lightGreenAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: GoopText(
        label,
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
