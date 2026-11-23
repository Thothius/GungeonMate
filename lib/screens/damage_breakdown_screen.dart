import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gun.dart';
import '../models/player.dart';
import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/effect_tagger.dart';
import '../services/goop_talk_engine.dart';
import '../theme/tokens.dart';
import '../widgets/game_icon.dart';
import '../utils/asset_paths.dart';
import '../utils/responsive.dart';

/// Damage overview for one player slot — every gun's live DPS (form-
/// aware via [RunProvider.gunDps]) plus the parsed damage modifiers
/// pulled from guns, items and passives by [EffectTagger]. Reached from
/// the DPS dash capsule on the run header.
class DamageBreakdownScreen extends StatelessWidget {
  final PlayerSlot slot;
  const DamageBreakdownScreen({super.key, required this.slot});

  Player? _player(RunProvider p) =>
      slot == PlayerSlot.main ? p.runState.main : p.runState.coop;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final player = _player(p);
    final f = AppTheme.flair;
    final sf = Responsive.factor(context);

    if (player == null) {
      return Scaffold(
        backgroundColor: f.scaffold,
        appBar: AppBar(title: const GoopText('Damage Breakdown')),
        body: const Center(child: GoopText('No player')),
      );
    }

    // Guns sorted by live DPS, descending — top gun first.
    final guns = List<Gun>.of(player.guns)
      ..sort((a, b) => p.gunDps(b).compareTo(p.gunDps(a)));
    final dpsOf = {for (final g in guns) g.name: p.gunDps(g)};
    final topDps = guns.isEmpty ? 0.0 : dpsOf[guns.first.name]!;
    final totalDps = dpsOf.values.fold<double>(0, (a, b) => a + b);

    // Damage-category effect occurrences, grouped by source name so the
    // overview reads as "what's adding/affecting what".
    final scan = EffectTagger.scan(guns: player.guns, items: player.items);
    final damageTags =
        scan.keys.where((t) => t.category == EffectCategory.damage).toList()
          ..sort((a, b) => a.label.compareTo(b.label));

    String fmt(double v) => v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

    return Scaffold(
      backgroundColor: f.scaffold,
      appBar: AppBar(
        backgroundColor: f.card,
        title: GoopText(
          'DAMAGE BREAKDOWN',
          style: TextStyle(
            fontSize: FontSizes.bodyMedium * sf,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            // ── Summary strip ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: f.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: f.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  _summary('TOP GUN', fmt(topDps), const Color(0xFF69F0AE), sf),
                  _vDivider(),
                  _summary('ARMORY DPS', fmt(totalDps), Colors.white70, sf),
                  _vDivider(),
                  _summary('GUNS', '${guns.length}', Colors.white70, sf),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Armory ─────────────────────────────────────────────
            _sectionHeader('ARMORY', Icons.gps_fixed, guns.length),
            if (guns.isEmpty)
              _emptyNote('No guns yet — grab one from a chest or shop.')
            else
              for (var i = 0; i < guns.length; i++)
                _gunRow(context, guns[i], dpsOf[guns[i].name]!, i == 0, f, sf),
            const SizedBox(height: 14),

            // ── Damage modifiers ───────────────────────────────────
            _sectionHeader(
              'DAMAGE MODIFIERS',
              Icons.flash_on,
              damageTags.fold<int>(
                0,
                (n, t) => n + (scan[t]?.length ?? 0),
              ),
            ),
            if (damageTags.isEmpty)
              _emptyNote(
                'No damage-modifying effects detected in this loadout.',
              )
            else
              for (final tag in damageTags) ...[
                _modifierCard(context, tag, scan[tag]!, f, sf),
                const SizedBox(height: 6),
              ],
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(
    width: 1,
    height: 26,
    margin: const EdgeInsets.symmetric(horizontal: 10),
    color: Colors.white.withValues(alpha: 0.10),
  );

  Widget _summary(String label, String value, Color color, double sf) =>
      Expanded(
    child: Column(
      children: [
        GoopText(
          value,
          style: TextStyle(
            fontSize: 18 * sf,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1.1,
          ),
        ),
        GoopText(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white38,
            letterSpacing: 0.8,
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeader(String title, IconData icon, int count) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
    child: Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.flair.primary),
        const SizedBox(width: 6),
        GoopText(
          title,
          style: TextStyle(
            fontSize: FontSizes.labelSmall,
            fontWeight: FontWeight.w900,
            color: AppTheme.flair.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 6),
        GoopText(
          '$count',
          style: const TextStyle(fontSize: 10, color: Colors.white38),
        ),
      ],
    ),
  );

  Widget _emptyNote(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(10),
    ),
    child: GoopText(
      text,
      style: const TextStyle(fontSize: 12, color: Colors.white38),
    ),
  );

  Widget _gunRow(
    BuildContext context,
    Gun g,
    double dps,
    bool isTop,
    ThemeFlair f,
    double sf,
  ) {
    final path = g.icon.isNotEmpty ? g.icon : localGunIcon(g.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isTop
                  ? const Color(0xFF69F0AE).withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          GameIcon(
            assetPath: path,
            fallback: Icons.gps_fixed,
            quality: g.quality,
            size: 40,
            semanticLabel: '${g.name}, quality ${g.quality}',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: GoopText(
                        g.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13 * sf,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (isTop) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.emoji_events,
                        size: 13,
                        color: Color(0xFFFFD740),
                      ),
                    ],
                  ],
                ),
                GoopText(
                  [
                    if (g.type.isNotEmpty) g.type,
                    if (g.quality.isNotEmpty) g.quality,
                    if (g.damage.isNotEmpty) 'DMG ${g.damage}',
                    if (g.fireRate.isNotEmpty) '${g.fireRate}/s',
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GoopText(
            dps >= 100 ? dps.toStringAsFixed(0) : dps.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 16 * sf,
              fontWeight: FontWeight.w900,
              color: isTop ? const Color(0xFF69F0AE) : Colors.white70,
            ),
          ),
          const GoopText(
            ' DPS',
            style: TextStyle(fontSize: 9, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _modifierCard(
    BuildContext context,
    EffectTag tag,
    List<EffectOccurrence> occs,
    ThemeFlair f,
    double sf,
  ) {
    final color = tag.category.color;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: f.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tag.icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: GoopText(
                  tag.label,
                  style: TextStyle(
                    fontSize: 12 * sf,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              if (occs.length > 1)
                GoopText(
                  '×${occs.length}',
                  style: const TextStyle(fontSize: 10, color: Colors.white38),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (final o in occs)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    o.sourceIsGun ? Icons.gps_fixed : Icons.extension,
                    size: 11,
                    color: Colors.white30,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: o.sourceName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white70,
                            ),
                          ),
                          if (o.excerpt.isNotEmpty)
                            TextSpan(
                              text: ' — ${o.excerpt}',
                              style: const TextStyle(color: Colors.white38),
                            ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 10, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
