import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../theme/tokens.dart';
import '../game_icon.dart';
import '../state_widgets.dart';
import '../skeuo/skeuo_tokens.dart';

/// SYNERGIES section for gun detail. Two modes driven by the global
/// `VisualPrefs.showLichEyeBulletsSynergies` toggle:
///
/// * **Lich's Eye Bullets (default):** every synergy the gun participates
///   in is listed as a simulated/active row — the "what if LEB is owned"
///   view requested for all weapons.
/// * **Actual:** synergies grouped COMPLETE → PARTIAL → LOCKED against the
///   real inventory. Every synergy is listed (no active/partial filter),
///   so each gun always has the full list.
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
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        if (prefs.showLichEyeBulletsSynergies) {
          return _LichEyeBulletsView(
            statuses: statuses,
            currentName: currentName,
          );
        }
        return _ActualSynergiesView(
          statuses: statuses,
          currentName: currentName,
        );
      },
    );
  }
}

/// Lich's Eye Bullets simulated view — flat list of every synergy the
/// gun participates in, styled as active/simulated regardless of the
/// real inventory.
class _LichEyeBulletsView extends StatelessWidget {
  final List<SynergyStatus> statuses;
  final String currentName;
  const _LichEyeBulletsView({
    required this.statuses,
    required this.currentName,
  });

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) {
      return const _EmptySynergies();
    }
    final p = context.read<RunProvider>();
    final sorted = [...statuses]
      ..sort((a, b) => a.synergy.name.compareTo(b.synergy.name));
    final lebIcon = p.itemByName("Lich's Eye Bullets")?.icon ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LebHeader(iconPath: lebIcon),
          const SizedBox(height: 10),
          for (final st in sorted)
            _SynergyRow(
              status: st,
              owners: 'LEB',
              missing: null,
              p: p,
              simulated: true,
            ),
        ],
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
              GoopText(
                "LICH'S EYE BULLETS",
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: accent,
                ),
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

/// Actual inventory view — COMPLETE / PARTIAL / LOCKED groups covering
/// every synergy the gun participates in.
class _ActualSynergiesView extends StatelessWidget {
  final List<SynergyStatus> statuses;
  final String currentName;
  const _ActualSynergiesView({
    required this.statuses,
    required this.currentName,
  });

  @override
  Widget build(BuildContext context) {
    if (statuses.isEmpty) {
      return const _EmptySynergies();
    }
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
    final locked = <SynergyStatus>[];
    for (final st in statuses) {
      if (st.active) {
        complete.add(st);
      } else if (_hasAnyPiece(st, owned, currentName)) {
        partial.add(st);
      } else {
        locked.add(st);
      }
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
            const SizedBox(height: 6),
            for (final st in complete)
              _SynergyRow(
                status: st,
                owners: ownersOf(st),
                missing: null,
                p: p,
              ),
          ],
          if (partial.isNotEmpty) ...[
            if (complete.isNotEmpty) const SizedBox(height: 14),
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
          if (locked.isNotEmpty) ...[
            if (complete.isNotEmpty || partial.isNotEmpty)
              const SizedBox(height: 14),
            _GroupHeader(
              label: 'LOCKED',
              color: Colors.white38,
              icon: Icons.lock_outline_rounded,
            ),
            const SizedBox(height: 6),
            for (final st in locked)
              _SynergyRow(
                status: st,
                owners: 'NONE',
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

class _SynergyRow extends StatelessWidget {
  final SynergyStatus status;
  final String owners;
  final String? missing;
  final RunProvider p;
  final bool simulated;
  const _SynergyRow({
    required this.status,
    required this.owners,
    required this.missing,
    required this.p,
    this.simulated = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.synergy;
    // Icon: the missing piece for partials/locked, the synergy's own icon
    // (or first piece) for completes and LEB-simulated rows.
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
        simulated
            ? Skeuo.inkIf(const Color(0xFFB388FF))
            : status.active
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
                    _OwnerPill(label: owners),
                  ],
                ),
                if (s.effect.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  GoopText(
                    s.prettyEffect.isNotEmpty ? s.prettyEffect : s.effect,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.65),
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
        label == 'LEB'
            ? Skeuo.inkIf(const Color(0xFFB388FF))
            : label == 'NONE'
            ? Colors.white38
            : label.contains('+')
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
