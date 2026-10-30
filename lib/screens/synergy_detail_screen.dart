import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/synergy.dart';
import '../providers/run_provider.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import '../widgets/active_run/bottom_back_bar.dart';
import 'item_detail_screen.dart';

/// Synergy detail page — the "synergy graph" surface of the
/// Ammonomicon. Every required/optional item is a tappable chip that
/// deep-links into that item's detail screen; chips glow when the
/// current loadout owns them (matchesItems handles the special-case
/// synergies like Smart Bombs / Super Serum).
class SynergyDetailScreen extends StatelessWidget {
  final Synergy synergy;
  const SynergyDetailScreen({super.key, required this.synergy});

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final p = context.watch<RunProvider>();
    final owned = <String>{
      for (final g in p.runState.main.guns) g.name.toLowerCase(),
      for (final i in p.runState.main.items) i.name.toLowerCase(),
      for (final g in p.runState.coop?.guns ?? const []) g.name.toLowerCase(),
      for (final i in p.runState.coop?.items ?? const []) i.name.toLowerCase(),
    };
    final complete = synergy.matchesOwnedSet(owned);

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: const BottomBackBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  GoopText(
                    synergy.name,
                    style: TextStyle(
                        fontSize: 22 * sf,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (complete ? Colors.lightGreenAccent : Colors.amber)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: (complete
                                  ? Colors.lightGreenAccent
                                  : Colors.amber)
                              .withValues(alpha: 0.5)),
                    ),
                    child: GoopText(
                      complete ? 'ACTIVE IN LOADOUT' : 'NOT COMPLETE',
                      style: TextStyle(
                          fontSize: 10 * sf,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: complete
                              ? Colors.lightGreenAccent
                              : Colors.amber),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (synergy.items.isNotEmpty) ...[
                    _sectionLabel('REQUIRES', sf),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final n in synergy.items)
                          _ItemChip(name: n, owned: owned, required: true, sf: sf),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (synergy.anyOf.isNotEmpty) ...[
                    _sectionLabel('ANY OF', sf),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final n in synergy.anyOf)
                          _ItemChip(
                              name: n, owned: owned, required: false, sf: sf),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  _sectionLabel('EFFECT', sf),
                  const SizedBox(height: 8),
                  GoopText(
                    synergy.prettyEffect.isNotEmpty
                        ? synergy.prettyEffect
                        : '—',
                    style: TextStyle(
                        fontSize: 14 * sf,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.85)),
                  ),
                  const SizedBox(height: 16),
                  GoopText(
                    'Tap an item to open its Ammonomicon entry.',
                    style: TextStyle(
                        fontSize: 11 * sf,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.35)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String t, double sf) => GoopText(
        t,
        style: TextStyle(
            fontSize: 11 * sf,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.5)),
      );
}

/// A required/optional item chip — owned items glow green.
class _ItemChip extends StatelessWidget {
  final String name;
  final Set<String> owned;
  final bool required;
  final double sf;
  const _ItemChip(
      {required this.name,
      required this.owned,
      required this.required,
      required this.sf});

  @override
  Widget build(BuildContext context) {
    final isOwned = owned.contains(name.toLowerCase());
    final c = isOwned ? Colors.lightGreenAccent : Colors.white;
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        final p = context.read<RunProvider>();
        final gun = p.allGuns
            .where((g) => g.name.toLowerCase() == name.toLowerCase())
            .firstOrNull;
        final item = p.allItems
            .where((i) => i.name.toLowerCase() == name.toLowerCase())
            .firstOrNull;
        final dest = gun != null
            ? ItemDetailScreen(gun: gun)
            : item != null
                ? ItemDetailScreen(item: item)
                : null;
        if (dest != null) Navigator.push(context, fastRoute(dest));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: (isOwned ? Colors.lightGreenAccent : Colors.white)
              .withValues(alpha: isOwned ? 0.14 : 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isOwned
                  ? Colors.lightGreenAccent.withValues(alpha: 0.55)
                  : (required
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.15)),
              width: isOwned ? 1.4 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwned)
              const Icon(Icons.check_circle_rounded,
                  size: 13, color: Colors.lightGreenAccent),
            if (isOwned) const SizedBox(width: 5),
            GoopText(
              name,
              style: TextStyle(
                  fontSize: 12 * sf,
                  fontWeight: FontWeight.w700,
                  color: c.withValues(alpha: isOwned ? 1.0 : 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
