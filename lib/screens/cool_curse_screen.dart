import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/run_provider.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../theme/tokens.dart';
import '../utils/responsive.dart';
import '../widgets/skeuo/skeuo_tokens.dart';

/// Cool & Curse fullscreen — opened by tapping the COOL or CURSE stat
/// in the Paradox player panel, or by long-pressing either capsule in
/// the solo [GungeoneerHeader].
///
/// Layout: dual top panels (COOLNESS left / CURSE right) with live
/// values + quick ± buttons → effects list with current values →
/// down-arrow hints → scroll into the explainer section (mechanics
/// distilled from the EtG wiki pages on Coolness and Curse).
class CoolCurseScreen extends StatelessWidget {
  const CoolCurseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final p = context.watch<RunProvider>();
    final cool = p.runState.totalCoolness;
    final curse = p.runState.totalCurse;

    // Live metric values — same formulas EtG uses.
    final fuseSkipPct = math.min(cool * 2.5, 10);
    final chestResetPct = math.min(cool * 5, 50);
    final rewardPct = math.max(0.0, 1 + cool - curse);
    final jamChance = curse >= 10 ? 100.0 : curse * 4;
    final bossJamChance = curse >= 10 ? 100.0 : curse * 2;

    // Semantic stat colors — collapse to ink under Neo-Skeuo; title
    // follows the theme accent like every other pushed screen.
    final coolColor = Skeuo.inkIf(StatColors.cool);
    final curseColor = Skeuo.inkIf(StatColors.curse);
    final jammedColor = Skeuo.inkIf(const Color(0xFFFF5252));
    final titleColor = Skeuo.inkIf(AppTheme.flair.primary);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: GoopText(
          'COOL & CURSE',
          style: TextStyle(
            fontSize: FontSizes.titleSmall * sf,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: titleColor,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(14 * sf),
              child: Row(
                children: [
                  Expanded(
                    child: _MeterPanel(
                      title: 'COOLNESS',
                      value: cool,
                      color: coolColor,
                      sf: sf,
                      onDelta: (d) {
                        p.adjustCoolness(d);
                        Haptics.light();
                      },
                      // Reset clears the manual base only — `cool`
                      // here is the item-inclusive total, and
                      // subtracting it would poison the hidden base.
                      onReset: p.resetCoolness,
                    ),
                  ),
                  SizedBox(width: 12 * sf),
                  Expanded(
                    child: _MeterPanel(
                      title: 'CURSE',
                      value: curse,
                      color: curseColor,
                      sf: sf,
                      onDelta: (d) {
                        p.adjustCurse(d);
                        Haptics.light();
                      },
                      onReset: p.resetCurse,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Live effects list
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14 * sf),
              child: _EffectsCard(
                sf: sf,
                rows: [
                  _EffectRow(
                    'Chest fuse auto-defuse',
                    '${fuseSkipPct.toStringAsFixed(1)}%',
                    'Chance a mimicked/unmimicked chest resets its fuse. +2.5% per Cool, caps at 10% (4 Cool).',
                    coolColor,
                  ),
                  _EffectRow(
                    'Active-item cooldown',
                    '−${chestResetPct.toStringAsFixed(0)}% time',
                    'Coolness shortens recharge on cooldown-based items (Cigarettes etc.). +5% per Cool, caps at 50%.',
                    coolColor,
                  ),
                  _EffectRow(
                    'Extra room reward',
                    '${rewardPct.toStringAsFixed(1)}% ',
                    'Chance a cleared room drops an extra pickup. +1% per Cool, −1% per Curse.',
                    coolColor,
                  ),
                  _EffectRow(
                    'Jammed enemy chance',
                    '${jamChance.toStringAsFixed(0)}%',
                    'Curse jamms normal enemies — faster, harder, more damage. ~4% per Curse point.',
                    curseColor,
                  ),
                  _EffectRow(
                    'Jammed boss chance',
                    '${bossJamChance.toStringAsFixed(0)}%',
                    'Bosses can also jam (except past bosses). ~2% per Curse point.',
                    curseColor,
                  ),
                  if (curse >= 10)
                    _EffectRow(
                      'LORD OF THE JAMMED',
                      'ACTIVE',
                      'At 10 Curse an unkillable reaper hunts you until the run ends. Stay under 10.',
                      jammedColor,
                    ),
                ],
              ),
            ),
          ),
          // Down-arrow hint
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14 * sf),
              child: Column(
                children: [
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 28 * sf,
                    color: Skeuo.collapse(Colors.white.withValues(alpha: 0.35)),
                  ),
                  GoopText(
                    'scroll for the full picture',
                    style: TextStyle(
                      fontSize: 10.5 * sf,
                      fontStyle: FontStyle.italic,
                      color: Skeuo.collapse(
                        Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Explainer section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(14 * sf, 0, 14 * sf, 24 * sf),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoBlock(
                    title: 'COOLNESS',
                    color: coolColor,
                    sf: sf,
                    body:
                        'Coolness is a hidden counter of how "cool" you are — '
                        'gained mostly by picking up items marked cool, '
                        'smoking Cigarettes, or being around charming friends.\n\n'
                        '• Each point adds +2.5% fuse-defuse (cap 10% at 4), '
                        '+5% active-item cooldown reduction (cap 50% at 10), '
                        'and +1% extra room-reward chance.\n'
                        '• Coolness also raises Mimic chance — mimics are '
                        'stronger with a beefier version at 6+ Cool.\n'
                        '• It partially offsets Curse in the room-reward roll.\n'
                        '• Some guns scale with Coolness (e.g. The Line, '
                        'Han Solo\'s Blaster types).',
                  ),
                  SizedBox(height: 14 * sf),
                  _InfoBlock(
                    title: 'CURSE',
                    color: curseColor,
                    sf: sf,
                    body:
                        'Curse is the dark twin — gained from cursed items '
                        '(usually marked with a skull), shrine deals, and '
                        'certain guns.\n\n'
                        '• Raises jam chance: jammed enemies move faster, '
                        'shoot more, take less damage. Bosses can jam too.\n'
                        '• Jam chance scales ~4% per point vs normal enemies '
                        'and ~2% per point vs bosses — both reach 100% at '
                        '10+ Curse.\n'
                        '• Reduces extra room-reward chance (−1% per point).\n'
                        '• 10+ Curse summons the LORD OF THE JAMMED — an '
                        'unkillable pursuer that ends runs. You can\'t dodge '
                        'it, only out-pace it.\n'
                        '• Cursed items often have upside — the tradeoff is '
                        'the meter.\n'
                        '• Some items need Curse to be worth it (e.g. '
                        'Yellow Chamber, Jammed synergy pieces).',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeterPanel extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final double sf;
  final void Function(double) onDelta;
  final VoidCallback onReset;
  const _MeterPanel({
    required this.title,
    required this.value,
    required this.color,
    required this.sf,
    required this.onDelta,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * sf),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        children: [
          GoopText(
            title,
            style: TextStyle(
              fontSize: 10 * sf,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          GoopText(
            value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 36 * sf,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          SizedBox(height: 12 * sf),
          Row(
            children: [
              _DeltaBtn(
                label: '−1',
                dense: true,
                onTap: () => onDelta(-1),
                color: color,
                sf: sf,
              ),
              SizedBox(width: 6 * sf),
              _DeltaBtn(
                label: '−.5',
                dense: true,
                onTap: () => onDelta(-0.5),
                color: color,
                sf: sf,
              ),
              SizedBox(width: 6 * sf),
              _DeltaBtn(
                label: '+.5',
                dense: true,
                onTap: () => onDelta(0.5),
                color: color,
                sf: sf,
              ),
              SizedBox(width: 6 * sf),
              _DeltaBtn(
                label: '+1',
                dense: true,
                onTap: () => onDelta(1),
                color: color,
                sf: sf,
              ),
            ],
          ),
          SizedBox(height: 10 * sf),
          Semantics(
            button: true,
            label: 'Reset ${title.toLowerCase()} manual stat to zero',
            child: Tooltip(
              message: 'Reset manual stat to zero',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  onReset();
                  Haptics.medium();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4 * sf),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restart_alt_rounded,
                        size: 15 * sf,
                        color: Skeuo.collapse(
                          Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      SizedBox(width: 4 * sf),
                      GoopText(
                        'RESET',
                        style: TextStyle(
                          fontSize: 10 * sf,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Skeuo.collapse(
                            Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final double sf;
  final bool dense;
  const _DeltaBtn({
    required this.label,
    required this.onTap,
    required this.color,
    required this.sf,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label:
            '${label.replaceAll('.', '')} ${label.startsWith('-') ? 'decrease' : 'increase'}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 2 * sf : 14 * sf,
              vertical: dense ? 6 * sf : 6 * sf,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: GoopText(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (dense ? 12 : 14) * sf,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EffectRow {
  final String name;
  final String value;
  final String desc;
  final Color color;
  const _EffectRow(this.name, this.value, this.desc, this.color);
}

class _EffectsCard extends StatelessWidget {
  final double sf;
  final List<_EffectRow> rows;
  const _EffectsCard({required this.sf, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Skeuo.collapse(Colors.white.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Skeuo.collapse(Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: Skeuo.collapse(Colors.white.withValues(alpha: 0.06)),
              ),
            Padding(
              padding: EdgeInsets.all(12 * sf),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GoopText(
                          rows[i].name,
                          style: TextStyle(
                            fontSize: 12.5 * sf,
                            fontWeight: FontWeight.w800,
                            color: Skeuo.collapse(
                              Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        GoopText(
                          rows[i].desc,
                          style: TextStyle(
                            fontSize: 10.5 * sf,
                            height: 1.35,
                            color: Skeuo.collapse(
                              Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10 * sf),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * sf,
                      vertical: 4 * sf,
                    ),
                    decoration: BoxDecoration(
                      color: rows[i].color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: rows[i].color.withValues(alpha: 0.5),
                      ),
                    ),
                    child: GoopText(
                      rows[i].value,
                      style: TextStyle(
                        fontSize: 11 * sf,
                        fontWeight: FontWeight.w900,
                        color: rows[i].color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String title;
  final Color color;
  final String body;
  final double sf;
  const _InfoBlock({
    required this.title,
    required this.color,
    required this.body,
    required this.sf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * sf),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoopText(
            title,
            style: TextStyle(
              fontSize: 11 * sf,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: color.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: 8 * sf),
          GoopText(
            body,
            style: TextStyle(
              fontSize: 12 * sf,
              height: 1.5,
              color: Skeuo.collapse(Colors.white.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
