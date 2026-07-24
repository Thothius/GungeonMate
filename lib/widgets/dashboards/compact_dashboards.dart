import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/player.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';

// =============================================================================
// New compact dashboards for Shellegun, Chamber Gun, Platinum Bullets, Iron Coin
// =============================================================================

class ShellegunDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const ShellegunDashboard({super.key, required this.slot});

  @override
  State<ShellegunDashboard> createState() => ShellegunDashboardState();
}

class ShellegunDashboardState extends State<ShellegunDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final mode = p.shellegunMode;

    const modes = ['Pistol (Manual)', 'Pistol (Auto)', 'Beam'];
    const descriptions = [
      'Semi-auto energy pistol. Moderate fire rate, high accuracy.',
      'Fully automatic. Increased fire rate, same damage per shot.',
      'Continuous energy beam. Highest DPS, consumes ammo rapidly.',
    ];
    const dpsValues = [18.0, 27.5, 42.0];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1218),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyan.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    const Icon(Icons.shield_moon_rounded, color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'SHELLEGUN',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.cyanAccent, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    GoopText(
                      'DPS: ${dpsValues[mode - 1].toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.cyanAccent),
                    ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _modeBtn('Manual', mode == 1, () => p.setShellegunMode(1)),
                  _modeBtn('Auto', mode == 2, () => p.setShellegunMode(2)),
                  _modeBtn('Beam', mode == 3, () => p.setShellegunMode(3)),
                ],
              ),
              const SizedBox(height: 10),
              GoopText(
                modes[mode - 1],
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              GoopText(
                descriptions[mode - 1],
                style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7), height: 1.3),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeBtn(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: () { Haptics.light(); onTap(); },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.cyan.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? Colors.cyanAccent : Colors.white12),
        ),
        child: GoopText(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.cyanAccent : Colors.white60)),
      ),
    );
  }
}

class ChamberGunDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const ChamberGunDashboard({super.key, required this.slot});

  @override
  State<ChamberGunDashboard> createState() => ChamberGunDashboardState();
}

class ChamberGunDashboardState extends State<ChamberGunDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  static const _floors = [
    'Keep of the Lead Lord', 'Oubliette', 'Gungeon Proper', 'Abbey of the True Gun',
    'Black Powder Mine', "Rat's Lair", 'The Hollow', 'R&G Dept', 'The Forge', 'Bullet Hell',
  ];
  static const _dps = [15.0, 18.5, 22.0, 26.0, 30.0, 34.0, 38.5, 43.0, 48.0, 55.0];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final floor = p.chamberGunFloor;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF120E08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    const Icon(Icons.apartment_rounded, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'CHAMBER GUN',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.amberAccent, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    GoopText(
                      'DPS: ${_dps[floor].toStringAsFixed(1)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.amberAccent),
                    ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 8),
              GoopText(
                'FLOOR ${floor + 1}: ${_floors[floor]}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              // Floor selector — horizontal scrollable row
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 10,
                  separatorBuilder: (_, __) => const SizedBox(width: 4),
                  itemBuilder: (context, i) {
                    final active = i == floor;
                    return InkWell(
                      onTap: () { Haptics.light(); p.setChamberGunFloor(i); },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? Colors.amber.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: active ? Colors.amberAccent : Colors.white12),
                        ),
                        child: GoopText(
                          '${i + 1}',
                          style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.amberAccent : Colors.white54),
                        ),
                      ),
                    );
                  },
                ),
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PlatinumBulletsDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const PlatinumBulletsDashboard({super.key, required this.slot});

  @override
  State<PlatinumBulletsDashboard> createState() => PlatinumBulletsDashboardState();
}

class PlatinumBulletsDashboardState extends State<PlatinumBulletsDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final seconds = p.platinumBulletsSeconds;

    // Wiki: Fire rate doubles every 250s, maxes at 3x after 375s.
    // Damage doubles every 500s, maxes at 3x after 750s.
    final fireRateMult = seconds >= 375 ? 3.0 : 1.0 + (seconds / 375.0) * 2.0;
    final dmgMult = seconds >= 750 ? 3.0 : 1.0 + (seconds / 750.0) * 2.0;
    String tierLabel(double mult) {
      if (mult >= 3.0) return 'MAX';
      if (mult >= 2.0) return 'T2';
      if (mult > 1.0) return 'T1';
      return 'BASE';
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF100E18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, color: Colors.purpleAccent, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'PLATINUM BULLETS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.purpleAccent, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    GoopText(
                      '${seconds}s fired',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.purpleAccent),
                    ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 10),
              // Damage multiplier row
              _buildMultRow('DMG', dmgMult, seconds, 750, Colors.redAccent, tierLabel(dmgMult)),
              const SizedBox(height: 8),
              // Fire rate multiplier row
              _buildMultRow('RATE', fireRateMult, seconds, 375, Colors.orangeAccent, tierLabel(fireRateMult)),
              const SizedBox(height: 10),
              GoopText(
                'Damage & fire rate scale with firing time. Max 3x each. Tap +30s after each fight.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: seconds > 0 ? () { Haptics.light(); p.setPlatinumBulletsSeconds((seconds - 30).clamp(0, 999)); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.purpleAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  GoopText('${seconds}s', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    onPressed: () { Haptics.light(); p.setPlatinumBulletsSeconds((seconds + 30).clamp(0, 999)); },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.purpleAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () { Haptics.selection(); p.setPlatinumBulletsSeconds(0); },
                    child: const GoopText('Reset', style: TextStyle(fontSize: 10, color: Colors.redAccent)),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultRow(String label, double mult, int seconds, int maxSeconds, Color color, String tier) {
    final progress = (seconds / maxSeconds).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: GoopText(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: GoopText(
            '${mult.toStringAsFixed(1)}x',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 32,
          child: GoopText(
            tier,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6)),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class IronCoinDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const IronCoinDashboard({super.key, required this.slot});

  @override
  State<IronCoinDashboard> createState() => IronCoinDashboardState();
}

class IronCoinDashboardState extends State<IronCoinDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final uses = p.ironCoinUses;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF181210),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.brown.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    const Icon(Icons.paid_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'IRON COIN',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.amber, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    GoopText(
                      '$uses/3 uses',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: uses > 0 ? Colors.amber : Colors.white30),
                    ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 10),
              // Coin icons row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 3; i++)
                    Icon(
                      Icons.paid_rounded,
                      size: 32,
                      color: i < uses ? Colors.amber : Colors.white.withValues(alpha: 0.1),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              GoopText(
                "Flip to reveal/destroy a chest's contents. 3 uses per run. Use wisely on high-tier chests.",
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: uses < 3 ? () { Haptics.light(); p.setIronCoinUses(uses + 1); } : null,
                    icon: const Icon(Icons.add_circle_outline, color: Colors.amber, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  IconButton(
                    onPressed: uses > 0 ? () { Haptics.light(); p.setIronCoinUses(uses - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.amber, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// New dashboards: Spice, Metronome, Sprun, Boxing Glove, Cigarettes
// =============================================================================

class SpiceDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const SpiceDashboard({super.key, required this.slot});

  @override
  State<SpiceDashboard> createState() => SpiceDashboardState();
}

class SpiceDashboardState extends State<SpiceDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final count = p.spiceUsageCount;

    final damageBonus = count <= 2
        ? 0
        : count == 3
            ? 20
            : 20 + (count - 3) * 15;
    final curseTotal = count == 0
        ? 0.0
        : count == 1
            ? 0.5
            : 0.5 + (count - 1);
    final heartChange = count <= 2 ? count : 4 - count;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF180E0E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    const Icon(Icons.spa, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'SPICE',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    GoopText(
                      '+$damageBonus% DMG',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.redAccent),
                    ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statChip('Uses', '$count'),
                  _statChip('Curse', '+${curseTotal.toStringAsFixed(1)}'),
                  _statChip('Hearts', heartChange == 0 ? '0' : heartChange > 0 ? '+$heartChange' : '$heartChange'),
                  _statChip('Dmg', '+$damageBonus%'),
                ],
              ),
              const SizedBox(height: 10),
              GoopText(
                count == 0
                    ? 'No Spice used. 1st use: +1 Heart, +20% Speed, -25% Spread, +0.5 Curse.'
                    : count == 1
                        ? '1 use done. 2nd use: +1 Heart, -10% Enemy Bullet Speed, +20% Fire Rate, +1 Curse.'
                    : count == 2
                        ? '2 uses done. 3rd use: -1 Heart, +20% Damage, -5% Enemy Bullet Speed, +1 Curse.'
                    : count < 5
                        ? 'Escalating bonuses. Each use: -1 Heart, +15% Damage, +10% Spread, +1 Curse.'
                        : 'Diminishing returns: +15% Dmg, +1.0 Curse per additional use.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: count > 0 ? () { Haptics.light(); p.setSpiceUsageCount(count - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  Text('$count', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  IconButton(
                    onPressed: () { Haptics.light(); p.setSpiceUsageCount(count + 1); },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.redAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        GoopText(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
        GoopText(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
      ],
    );
  }
}

class MetronomeDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const MetronomeDashboard({super.key, required this.slot});

  @override
  State<MetronomeDashboard> createState() => MetronomeDashboardState();
}

class MetronomeDashboardState extends State<MetronomeDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final kills = p.metronomeKills;
    final damageBonus = (kills * 2).clamp(0, 150);
    final progress = kills / 75.0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1218),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    const Icon(Icons.speed, color: Colors.tealAccent, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'METRONOME',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.tealAccent, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    GoopText(
                      '+$damageBonus% DMG',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.tealAccent),
                    ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation(Colors.tealAccent.withValues(alpha: 0.8)),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GoopText(
                    '$kills / 75 kills',
                    style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  GoopText(
                    kills >= 75 ? 'MAX STACK' : '${75 - kills} to max',
                    style: TextStyle(fontSize: 10, color: Colors.tealAccent.withValues(alpha: 0.6)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GoopText(
                '+2% damage per kill. Resets if you take damage or swap guns. Max +150% at 75 kills.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: kills > 0 ? () { Haptics.light(); p.setMetronomeKills(kills - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.tealAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  Text('$kills', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.tealAccent)),
                  IconButton(
                    onPressed: kills < 75 ? () { Haptics.light(); p.setMetronomeKills(kills + 1); } : null,
                    icon: const Icon(Icons.add_circle_outline, color: Colors.tealAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () { Haptics.selection(); p.setMetronomeKills(0); },
                    child: const GoopText('Reset', style: TextStyle(fontSize: 10, color: Colors.redAccent)),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SprunDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const SprunDashboard({super.key, required this.slot});

  @override
  State<SprunDashboard> createState() => SprunDashboardState();
}

class SprunDashboardState extends State<SprunDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  static const _triggers = [
    'Activating a Map Blank',
    'Taking damage to Armor / Losing a half-heart',
    'Throwing an empty weapon at a wall',
    'Falling down an elevator shaft or trap pit',
    'Lighting yourself on fire or stepping into a poison pool',
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final idx = p.sprunTriggerIndex;
    final isWindgunnerActive = p.windgunnerCountdown > 0;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1018),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    Icon(Icons.radar, color: Colors.cyanAccent.shade200, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'SPRUN',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.cyanAccent, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    if (isWindgunnerActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.cyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                        ),
                        child: GoopText(
                          'WINDGUNNER ${p.windgunnerCountdown}s',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                        ),
                      )
                    else
                      GoopText(
                        idx >= 0 ? 'REVEALED' : 'UNKNOWN',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.cyanAccent.withValues(alpha: 0.6)),
                      ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 10),
              if (idx >= 0)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.cyan.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on, color: Colors.cyanAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GoopText(
                          _triggers[idx],
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.cyanAccent),
                        ),
                      ),
                    ],
                  ),
                )
              else
                GoopText(
                  'Trigger unknown. Tap "Reveal" to discover this run\'s Windgunner activation condition.',
                  style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), height: 1.3),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Haptics.selection();
                      final randomIdx = DateTime.now().millisecondsSinceEpoch % _triggers.length;
                      p.setSprunTriggerIndex(randomIdx);
                    },
                    child: const GoopText('Reveal Trigger', style: TextStyle(fontSize: 11, color: Colors.cyanAccent)),
                  ),
                  if (idx >= 0) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () { Haptics.light(); p.setSprunTriggerIndex(-1); },
                      child: const GoopText('Hide', style: TextStyle(fontSize: 11, color: Colors.white38)),
                    ),
                  ],
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BoxingGloveDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const BoxingGloveDashboard({super.key, required this.slot});

  @override
  State<BoxingGloveDashboard> createState() => BoxingGloveDashboardState();
}

class BoxingGloveDashboardState extends State<BoxingGloveDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final stars = p.boxingGloveStars;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF181410),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    const Icon(Icons.sports_mma_rounded, color: Colors.orangeAccent, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'BOXING GLOVE',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.orangeAccent, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    GoopText(
                      stars == 3 ? 'SUPER PUNCH READY' : '$stars/3 stars',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: stars == 3 ? Colors.orangeAccent : Colors.white.withValues(alpha: 0.5)),
                    ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 10),
              // Star icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 3; i++)
                    Icon(
                      Icons.star_rounded,
                      size: 36,
                      color: i < stars
                          ? Colors.orangeAccent
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              GoopText(
                stars == 3
                    ? '3 stars! Charge the gun to consume stars and fire a high-damage super punch.'
                    : 'Gains a star per kill (up to 3). Chance to stun on hit. Increases curse by 1.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: stars > 0 ? () { Haptics.light(); p.setBoxingGloveStars(stars - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orangeAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  Text('$stars', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                  IconButton(
                    onPressed: stars < 3 ? () { Haptics.light(); p.setBoxingGloveStars(stars + 1); } : null,
                    icon: const Icon(Icons.add_circle_outline, color: Colors.orangeAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CigarettesDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const CigarettesDashboard({super.key, required this.slot});

  @override
  State<CigarettesDashboard> createState() => CigarettesDashboardState();
}

class CigarettesDashboardState extends State<CigarettesDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final uses = p.cigarettesUses;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF121418),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    const Icon(Icons.smoking_rooms, color: Colors.blueGrey, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'CIGARETTES',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    GoopText(
                      '+$uses Cool',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey),
                    ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statChip('Uses', '$uses'),
                  _statChip('Coolness', '+$uses'),
                  _statChip('Cost', '-$uses half-hearts'),
                ],
              ),
              const SizedBox(height: 10),
              GoopText(
                'Each use: -half a heart, +1 Coolness. Coolness decreases active item cooldowns and increases luck.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: uses > 0 ? () { Haptics.light(); p.setCigarettesUses(uses - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.blueGrey, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  Text('$uses', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  IconButton(
                    onPressed: () { Haptics.light(); p.setCigarettesUses(uses + 1); },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.blueGrey, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        GoopText(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
        GoopText(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
      ],
    );
  }
}

// =============================================================================
// Polaris Dashboard — 3-level kill tracker with damage penalty
// =============================================================================

class PolarisDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const PolarisDashboard({super.key, required this.slot});

  @override
  State<PolarisDashboard> createState() => PolarisDashboardState();
}

class PolarisDashboardState extends State<PolarisDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final kills = p.polarisKills;
    final hits = p.polarisDamageHits;

    // Effective level: base from kills, minus damage hits
    final baseLevel = kills >= 31 ? 3 : kills >= 11 ? 2 : 1;
    final effectiveLevel = (baseLevel - hits).clamp(1, 3);

    final dmgPerShot = effectiveLevel == 3 ? 25 : effectiveLevel == 2 ? '5x2' : 5;
    final dps = effectiveLevel == 3 ? 89.6 : effectiveLevel == 2 ? 35.8 : 17.9;
    final nextThreshold = effectiveLevel == 1 ? 11 : effectiveLevel == 2 ? 31 : null;
    final progressToNext = nextThreshold == null
        ? 1.0
        : (kills - (effectiveLevel == 2 ? 11 : 0)) / (nextThreshold - (effectiveLevel == 2 ? 11 : 0));

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1218),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'POLARIS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.amberAccent, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                      ),
                      child: GoopText(
                        'LV $effectiveLevel',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.amberAccent),
                      ),
                    ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 10),
              // Level progress bar
              if (nextThreshold != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progressToNext.clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(Colors.amberAccent),
                  ),
                ),
                const SizedBox(height: 4),
                GoopText(
                  '$kills / $nextThreshold kills to Lv ${effectiveLevel + 1}',
                  style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ] else
                GoopText('MAX LEVEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amberAccent.withValues(alpha: 0.8))),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statChip('DMG', '$dmgPerShot'),
                  _statChip('DPS', dps.toStringAsFixed(1)),
                  _statChip('Hits', '$hits'),
                ],
              ),
              const SizedBox(height: 10),
              GoopText(
                effectiveLevel == 3
                    ? 'L3: 25 damage per shot. Homing with Star Friends synergy.'
                    : effectiveLevel == 2
                        ? 'L2: Fires 2 bullets (5 dmg each). Double chance-based effect triggers.'
                        : 'L1: 5 damage per shot. Kill enemies to level up.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: kills > 0 ? () { Haptics.light(); p.setPolarisKills(kills - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.amberAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  GoopText('$kills kills', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    onPressed: () { Haptics.light(); p.setPolarisKills(kills + 1); },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.amberAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: hits > 0 ? () { Haptics.light(); p.setPolarisDamageHits(hits - 1); } : null,
                    icon: const Icon(Icons.remove, color: Colors.redAccent, size: 22),
                    tooltip: 'Reduce damage hits',
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  GoopText('-$hits', style: TextStyle(fontSize: 12, color: Colors.redAccent.withValues(alpha: 0.8))),
                  IconButton(
                    onPressed: () { Haptics.light(); p.setPolarisDamageHits(hits + 1); },
                    icon: const Icon(Icons.add, color: Colors.redAccent, size: 22),
                    tooltip: 'Took damage (level drop)',
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        GoopText(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
        GoopText(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
      ],
    );
  }
}

// =============================================================================
// Gunther Dashboard — 3-stage friendship tracker
// =============================================================================

class GuntherDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const GuntherDashboard({super.key, required this.slot});

  @override
  State<GuntherDashboard> createState() => GuntherDashboardState();
}

class GuntherDashboardState extends State<GuntherDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final friendship = p.guntherFriendship;

    final stage = friendship >= 6 ? 3 : friendship >= 3 ? 2 : 1;
    final dmg = stage == 3 ? 12 : stage == 2 ? 9 : 6;
    final dps = stage == 3 ? 69.2 : stage == 2 ? 51.9 : 34.6;
    final trait = stage == 3 ? 'Homing' : stage == 2 ? 'Bounces 2x' : 'Piercing';
    final nextFriendship = stage == 1 ? 3 : stage == 2 ? 6 : null;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0E18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.35), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    const Icon(Icons.chat_bubble, color: Colors.purpleAccent, size: 18),
                    const SizedBox(width: 8),
                    const GoopText(
                      'GUNTHER',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.purpleAccent, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
                      ),
                      child: GoopText(
                        'STAGE $stage',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.purpleAccent),
                      ),
                    ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 10),
              // Friendship progress
              if (nextFriendship != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (friendship / nextFriendship).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(Colors.purpleAccent),
                  ),
                ),
                const SizedBox(height: 4),
                GoopText(
                  '$friendship / $nextFriendship friendship to Stage ${stage + 1}',
                  style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ] else
                GoopText('MAX STAGE — Sentient & Homing', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purpleAccent.withValues(alpha: 0.8))),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statChip('DMG', '$dmg'),
                  _statChip('DPS', dps.toStringAsFixed(1)),
                  _statChip('Trait', trait),
                ],
              ),
              const SizedBox(height: 10),
              GoopText(
                stage == 3
                    ? 'L3: 12 dmg, homing bullets. Fully sentient — talks frequently.'
                    : stage == 2
                        ? 'L2: 9 dmg, bullets bounce twice. Growing personality.'
                        : 'L1: 6 dmg, piercing bullets. Clear rooms to gain friendship.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: friendship > 0 ? () { Haptics.light(); p.setGuntherFriendship(friendship - 1); } : null,
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.purpleAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                  Text('$friendship', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    onPressed: () { Haptics.light(); p.setGuntherFriendship(friendship + 1); },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.purpleAccent, size: 24),
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        GoopText(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.4))),
        GoopText(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
      ],
    );
  }
}

// =============================================================================
// Gun Soul Dashboard — death/respawn toggle
// =============================================================================

class GunSoulDashboard extends StatefulWidget {
  final PlayerSlot slot;
  const GunSoulDashboard({super.key, required this.slot});

  @override
  State<GunSoulDashboard> createState() => GunSoulDashboardState();
}

class GunSoulDashboardState extends State<GunSoulDashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final p = context.watch<RunProvider>();
    final activated = p.gunSoulActivated;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF180E0E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activated ? Colors.orange.withValues(alpha: 0.5) : Colors.deepOrange.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                  children: [
                    Icon(
                      activated ? Icons.local_fire_department : Icons.shield,
                      color: activated ? Colors.orangeAccent : Colors.deepOrangeAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const GoopText(
                      'GUN SOUL',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.deepOrangeAccent, letterSpacing: 0.8),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: activated ? Colors.orange.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: activated ? Colors.orange.withValues(alpha: 0.5) : Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: GoopText(
                        activated ? 'SOUL LOST' : 'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: activated ? Colors.orangeAccent : Colors.greenAccent,
                        ),
                      ),
                    ),
                    
                  ],
                ),
                ),
              ),
              if (!_collapsed) ...[
              const SizedBox(height: 10),
              GoopText(
                activated
                    ? 'You died and respawned at floor start. Gun Soul is removed from your inventory. Reach the location of your death and interact with your soul to reclaim it — dying now will end the run.'
                    : 'Grants +1 heart container. Upon death, respawns you at the start of the current floor with all items and guns retained. Enemies respawn.',
                style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.6), height: 1.3),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () { Haptics.selection(); p.setGunSoulActivated(!activated); },
                    icon: Icon(
                      activated ? Icons.refresh : Icons.warning_amber,
                      size: 16,
                      color: activated ? Colors.greenAccent : Colors.orangeAccent,
                    ),
                    label: GoopText(
                      activated ? 'Soul Reclaimed' : 'Died — Respawned',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: activated ? Colors.greenAccent : Colors.orangeAccent,
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}