import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/gungeoneer.dart';
import '../../models/player.dart';
import '../../models/synergy.dart';
import '../../services/haptics.dart';
import '../../services/app_theme.dart';
import '../../services/damage_calculator.dart';
import '../../services/multiplayer_session.dart';
import '../../models/multiplayer_messages.dart';
import '../../utils/asset_paths.dart';
import '../../services/goop_talk_engine.dart';

/// Compact tab button for the Summary page in the MP header.
// TODO(BUG-037): Summary tab removed from MP header in v1.9.0. This class
// is now dormant — not referenced anywhere. Re-evaluate before re-introducing.
// ignore: unused_element
class SummaryTab extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const SummaryTab({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          decoration: BoxDecoration(
            color: active
                ? primary.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? primary.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.06),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.summarize_rounded,
                size: 14,
                color: active
                    ? primary
                    : Colors.white.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: GoopText(
                  'SUMMARY',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                    color: active
                        ? primary
                        : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Multiplayer Summary page — swipe right from P2 to reach it.
/// Shows both gungeoneers as animated GIFs with usernames, a compact
/// stats grid, and a collapsible synergy overview with visual icon pairs.
// TODO(BUG-037): Summary page removed from MP PageView in v1.9.0. This class
// is now dormant — not referenced anywhere. Re-evaluate before re-introducing.
// ignore: unused_element
class MpSummaryPage extends StatefulWidget {
  const MpSummaryPage({super.key});

  @override
  State<MpSummaryPage> createState() => MpSummaryPageState();
}

class MpSummaryPageState extends State<MpSummaryPage> {
  bool _synergyExpanded = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final session = context.watch<MultiplayerSession>();
    final state = p.runState;
    final main = state.main;
    final coop = state.coop ?? Player();

    final iAmMain = session.myRole == MpRole.main;
    final p1Nick = iAmMain ? session.myNickname : (session.peerNickname ?? 'P1');
    final p2Nick = !iAmMain ? session.myNickname : (session.peerNickname ?? 'P2');

    final p1Guns = main.guns;
    final p1Items = main.items;
    final p2Guns = coop.guns;
    final p2Items = coop.items;

    final p1MaxDps = p1Guns.isEmpty
        ? 0.0
        : p1Guns.map((g) => g.dpsValue).fold<double>(0, (a, b) => a > b ? a : b);
    final p2MaxDps = p2Guns.isEmpty
        ? 0.0
        : p2Guns.map((g) => g.dpsValue).fold<double>(0, (a, b) => a > b ? a : b);
    final teamMaxDps = math.max(p1MaxDps, p2MaxDps);

    final p1DmgMult = DamageCalculator.multiplier(guns: p1Guns, items: p1Items);
    final p2DmgMult = DamageCalculator.multiplier(guns: p2Guns, items: p2Items);

    final p1ActiveSyns = p.getActiveSynergiesForSlot(PlayerSlot.main);
    final p2ActiveSyns = p.getActiveSynergiesForSlot(PlayerSlot.coop);
    final allCombinedSyns = p.getActiveSynergiesCombined();

    final combinedNames = state.allItemNames.map((n) => n.toLowerCase()).toSet();
    final possibleSyns = p.allSynergies.where((s) {
      final hasAny = s.items.any((i) => combinedNames.contains(i.toLowerCase())) ||
          s.anyOf.any((i) => combinedNames.contains(i.toLowerCase()));
      return hasAny;
    }).toList();

    final activeSynNames = allCombinedSyns.map((s) => s.name.toLowerCase()).toSet();

    final activeSyns = <Synergy>[];
    final partialSyns = <Synergy>[];
    final lockedSyns = <Synergy>[];
    for (final syn in possibleSyns) {
      if (activeSynNames.contains(syn.name.toLowerCase())) {
        activeSyns.add(syn);
      } else {
        final missing = syn.missingFor(combinedNames);
        final totalNeeded = syn.items.length + (syn.anyOf.isNotEmpty ? 1 : 0);
        if (missing.length < totalNeeded) {
          partialSyns.add(syn);
        } else {
          lockedSyns.add(syn);
        }
      }
    }

    // Next-pickup hint: which single missing item would activate the most partials
    String? nextPickupHint;
    if (partialSyns.isNotEmpty) {
      final candidateCounts = <String, int>{};
      for (final syn in partialSyns) {
        for (final m in syn.missingFor(combinedNames)) {
          if (!m.startsWith('any of:')) {
            candidateCounts[m] = (candidateCounts[m] ?? 0) + 1;
          }
        }
      }
      if (candidateCounts.isNotEmpty) {
        final best = candidateCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
        nextPickupHint = 'Next pickup: ${best.key} (+${best.value} synergy${best.value > 1 ? 's' : ''})';
      }
    }

    return SafeArea(
      top: false,
      child: CustomScrollView(
        slivers: [
          // ΓöÇΓöÇ Gungeoneer portraits row ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: GungeoneerPortrait(
                      character: main.character,
                      nickname: p1Nick,
                      slotLabel: 'P1',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GungeoneerPortrait(
                      character: coop.character,
                      nickname: p2Nick,
                      slotLabel: 'P2',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ΓöÇΓöÇ Compact stats grid ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.flair.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    // Team DPS headline
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flash_on, size: 14, color: Colors.amberAccent.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        GoopText(
                          'TEAM MAX DPS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GoopText(
                          teamMaxDps.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.amberAccent,
                            shadows: [Shadow(color: Colors.amberAccent.withValues(alpha: 0.3), blurRadius: 8)],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row 1: Guns | Items | Active Syns
                    Row(
                      children: [
                        Expanded(child: _statChip('Guns', '${p1Guns.length}', '${p2Guns.length}', Icons.gps_fixed)),
                        Expanded(child: _statChip('Items', '${p1Items.length}', '${p2Items.length}', Icons.inventory_2_rounded)),
                        Expanded(child: _statChip('Syns', '${p1ActiveSyns.length}', '${p2ActiveSyns.length}', Icons.auto_awesome)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Row 2: Max DPS | DMG Bonus | Cool/Curse
                    Row(
                      children: [
                        Expanded(child: _statChip('DPS', p1MaxDps.toStringAsFixed(0), p2MaxDps.toStringAsFixed(0), Icons.flash_on)),
                        Expanded(child: _statChip('DMG', '${((p1DmgMult - 1) * 100).toStringAsFixed(0)}%', '${((p2DmgMult - 1) * 100).toStringAsFixed(0)}%', Icons.trending_up)),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.ac_unit, size: 10, color: Colors.cyanAccent.withValues(alpha: 0.6)),
                                  const SizedBox(width: 3),
                                  GoopText('+${state.totalCoolness.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.cyanAccent)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_fire_department, size: 10, color: Colors.redAccent.withValues(alpha: 0.6)),
                                  const SizedBox(width: 3),
                                  GoopText('+${state.totalCurse.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.redAccent)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ΓöÇΓöÇ Disconnection banner (if peer dropped) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
          if (!session.isConnected)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.25), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 14, color: Colors.orangeAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GoopText(
                          'Peer data may be stale — showing last known loadout.',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orangeAccent.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ΓöÇΓöÇ Synergy overview panel (collapsible) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.flair.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.20),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tappable header — tap to expand/collapse
                    InkWell(
                      onTap: () {
                        Haptics.selection();
                        setState(() => _synergyExpanded = !_synergyExpanded);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 16, color: Colors.amberAccent),
                            const SizedBox(width: 8),
                            GoopText(
                              'SYNERGY OVERVIEW',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: Colors.amberAccent,
                              ),
                            ),
                            const Spacer(),
                            GoopText(
                              '${allCombinedSyns.length} active',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.greenAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _synergyExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Next-pickup hint (always visible when partials exist)
                    if (nextPickupHint != null && !_synergyExpanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 12, color: Colors.amber.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: GoopText(
                                nextPickupHint,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Expanded content
                    if (_synergyExpanded) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (nextPickupHint != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.15), width: 1),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline, size: 14, color: Colors.amberAccent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GoopText(
                                        nextPickupHint,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amberAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (possibleSyns.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: GoopText(
                                    'No synergies available from current loadout.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              if (activeSyns.isNotEmpty) ...[
                                SynergyGroupHeader(
                                  label: 'ACTIVE',
                                  count: activeSyns.length,
                                  color: Colors.greenAccent,
                                ),
                                for (final syn in activeSyns)
                                  SynergySummaryRow(
                                    synergy: syn,
                                    isActive: true,
                                    ownedLower: combinedNames,
                                    provider: p,
                                  ),
                              ],
                              if (partialSyns.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SynergyGroupHeader(
                                  label: 'PARTIAL',
                                  count: partialSyns.length,
                                  color: Colors.amberAccent,
                                ),
                                for (final syn in partialSyns)
                                  SynergySummaryRow(
                                    synergy: syn,
                                    isActive: false,
                                    ownedLower: combinedNames,
                                    provider: p,
                                  ),
                              ],
                              if (lockedSyns.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SynergyGroupHeader(
                                  label: 'LOCKED',
                                  count: lockedSyns.length,
                                  color: Colors.white24,
                                ),
                                for (final syn in lockedSyns)
                                  SynergySummaryRow(
                                    synergy: syn,
                                    isActive: false,
                                    ownedLower: combinedNames,
                                    provider: p,
                                  ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  /// Compact stat chip showing P1 vs P2 values with a label.
  Widget _statChip(String label, String p1Val, String p2Val, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GoopText(
              p1Val,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 6),
            Icon(icon, size: 10, color: Colors.white.withValues(alpha: 0.3)),
            const SizedBox(width: 6),
            GoopText(
              p2Val,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.purpleAccent),
            ),
          ],
        ),
        const SizedBox(height: 2),
        GoopText(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }
}

/// Animated gungeoneer portrait with nickname below.
class GungeoneerPortrait extends StatelessWidget {
  final Gungeoneer? character;
  final String nickname;
  final String slotLabel;
  const GungeoneerPortrait({super.key, 
    required this.character,
    required this.nickname,
    required this.slotLabel,
  });

  @override
  Widget build(BuildContext context) {
    final charName = character?.name ?? 'Unknown';
    final gifPath = gungeoneerGifPath(charName);
    final accent = slotLabel == 'P1'
        ? Colors.cyanAccent
        : Colors.purpleAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slot label badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1),
          ),
          child: GoopText(
            slotLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: accent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Animated GIF portrait
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Image.asset(
              gifPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                character?.icon ?? '',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person,
                  size: 48,
                  color: accent.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Character name
        GoopText(
          charName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        // Nickname
        GoopText(
          nickname,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: accent,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// _StatComparisonRow removed — replaced by compact _statChip grid in MpSummaryPageState.

/// One row in the synergy overview panel — visual icon pairs.
/// Owned items show full-color with a glow; missing items are greyed out.
class SynergySummaryRow extends StatelessWidget {
  final Synergy synergy;
  final bool isActive;
  final Set<String> ownedLower;
  final RunProvider provider;
  const SynergySummaryRow({super.key, 
    required this.synergy,
    required this.isActive,
    required this.ownedLower,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final missing = synergy.missingFor(ownedLower);
    final totalNeeded = synergy.items.length + (synergy.anyOf.isNotEmpty ? 1 : 0);
    final isPartial = !isActive && missing.length < totalNeeded;

    final statusColor = isActive
        ? Colors.greenAccent
        : isPartial
            ? Colors.amberAccent
            : Colors.white24;

    // Build the list of all items involved in this synergy (required + anyOf)
    final allItems = <String>[...synergy.items, ...synergy.anyOf];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.green.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: statusColor.withValues(alpha: isActive ? 0.25 : 0.08),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            // Status dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 4)]
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            // Synergy name
            GoopText(
              synergy.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 10),
            // Visual icon pairs
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < allItems.length; i++) ...[
                      if (i > 0) ...[
                        // Connecting line between items
                        Container(
                          width: 14,
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : isPartial
                                    ? Colors.amberAccent.withValues(alpha: 0.3)
                                    : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                      SynergyItemIcon(
                        itemName: allItems[i],
                        isOwned: ownedLower.contains(allItems[i].toLowerCase()),
                        isActive: isActive,
                        provider: provider,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Status badge
            GoopText(
              isActive ? 'ACTIVE' : isPartial ? 'PARTIAL' : 'LOCKED',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single item icon inside a synergy row — lit if owned, greyed if missing.
class SynergyItemIcon extends StatelessWidget {
  final String itemName;
  final bool isOwned;
  final bool isActive;
  final RunProvider provider;
  const SynergyItemIcon({super.key, 
    required this.itemName,
    required this.isOwned,
    required this.isActive,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final gun = provider.gunByName(itemName);
    final item = provider.itemByName(itemName);
    final iconPath = gun?.icon ?? item?.icon ?? '';

    final ringColor = isActive
        ? Colors.greenAccent.withValues(alpha: 0.6)
        : isOwned
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.08);

    return Opacity(
      opacity: isOwned ? 1.0 : 0.35,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ringColor, width: 1.8),
          boxShadow: isOwned && isActive
              ? [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.15), blurRadius: 4)]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _buildImage(iconPath),
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.isEmpty) return _fallbackIcon();
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => _fallbackIcon(),
      );
    }
    return Image.asset(
      path,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, __, ___) => _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      color: const Color(0xFF0D1117),
      child: Center(
        child: GoopText(
          itemName.isNotEmpty ? itemName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

/// Section header for grouped synergies (ACTIVE / PARTIAL / LOCKED).
class SynergyGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const SynergyGroupHeader({super.key, 
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          GoopText(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          GoopText(
            '($count)',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sponge translation toggle with pulsing amber glow when active.
/// Only visible when Goopian language is enabled.
class SpongeButton extends StatefulWidget {
  const SpongeButton({super.key});

  @override
  State<SpongeButton> createState() => SpongeButtonState();
}

class SpongeButtonState extends State<SpongeButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _glow;

  @override
  void dispose() {
    _glow?.dispose();
    super.dispose();
  }

  void _ensureGlow(bool active) {
    if (active && _glow == null) {
      _glow = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    } else if (!active && _glow != null) {
      _glow!.dispose();
      _glow = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VisualPrefs.notifier,
      builder: (context, _) {
        final prefs = VisualPrefs.notifier.value;
        final isSponge = prefs.spongeActive;
        final isGoopian = prefs.isGoopianLanguage;
        if (!isGoopian) return const SizedBox.shrink();

        _ensureGlow(isSponge);

        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: IconButton(
            onPressed: () {
              VisualPrefs.setSpongeActive(!isSponge);
              if (isSponge) {
                Haptics.light();
              } else {
                Haptics.success();
              }
            },
            icon: _glow != null
                ? AnimatedBuilder(
                    animation: _glow!,
                    builder: (_, child) {
                      final t = _glow!.value;
                      return Text(
                        '≡ƒº╜',
                        style: TextStyle(
                          fontSize: 20,
                          shadows: [
                            Shadow(
                              color: Colors.amberAccent
                                  .withValues(alpha: 0.4 + 0.5 * t),
                              blurRadius: 6 + 12 * t,
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : const Text(
                    '≡ƒº╜',
                    style: TextStyle(fontSize: 20),
                  ),
            tooltip: isSponge
                ? 'Sponge: English translation active'
                : 'Sponge: Alien language active',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        );
      },
    );
  }
}