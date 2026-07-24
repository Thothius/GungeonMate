import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gun.dart';
import '../../providers/run_provider.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../widgets/themed_number.dart';
import 'quick_jump_button.dart';

class EvolverStageSpec {
  final int id;
  final String name;
  final String dps;
  final String bullet;
  final IconData icon;
  final Color color;
  const EvolverStageSpec({
    required this.id,
    required this.name,
    required this.dps,
    required this.bullet,
    required this.icon,
    required this.color,
  });
}

class StatGroup extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<MapEntry<String, String>> stats;
  const StatGroup({
    super.key,
    required this.label,
    required this.icon,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              GoopText(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: stats
              .map((e) => StatPill(label: e.key, value: e.value))
              .toList(),
        ),
      ],
    );
  }
}

class StatPill extends StatelessWidget {
  final String label;
  final String value;
  const StatPill({super.key, required this.label, required this.value});

  static const Map<String, Color> _chestColors = {
    'red': Color(0xFFE53935),
    'blue': Color(0xFF1E88E5),
    'green': Color(0xFF43A047),
    'black': Color(0xFF222222),
    'brown': Color(0xFF8D6E63),
    'rainbow': Colors.pinkAccent,
  };

  static const Map<String, String> _chestRanks = {
    'brown': 'D',
    'blue': 'C',
    'green': 'B',
    'red': 'A',
    'black': 'S',
    'rainbow': '★',
  };

  @override
  Widget build(BuildContext context) {
    final isChest = label.toLowerCase() == 'chest';
    final isCharge = label.toLowerCase() == 'charge';
    final isDuration = label.toLowerCase() == 'duration';
    final chestColor = isChest ? _chestColors[value.toLowerCase()] : null;
    final chestRank = isChest ? _chestRanks[value.toLowerCase()] : null;
    final hasDigit = RegExp(r'\d').hasMatch(value);
    final flair = AppTheme.flair;
    final filled = flair.chipFilled;
    final accentColor = isCharge
        ? Colors.lightBlueAccent
        : isDuration
            ? Colors.greenAccent.shade200
            : null;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: filled ? 10 : 4,
        vertical: filled ? 6 : 2,
      ),
      decoration: BoxDecoration(
        color: filled
            ? (accentColor?.withValues(alpha: 0.08) ??
                Colors.white.withValues(alpha: 0.06))
            : null,
        borderRadius: BorderRadius.circular(flair.chipRadius),
        border: filled
            ? (accentColor != null
                ? Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                    width: 0.8,
                  )
                : null)
            : Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCharge) ...[Icon(Icons.electric_bolt, size: 12, color: Colors.lightBlueAccent), const SizedBox(width: 3)],
          if (isDuration) ...[Icon(Icons.timer_outlined, size: 12, color: Colors.greenAccent.shade200), const SizedBox(width: 3)],
          GoopText(
            '$label  ',
            style: TextStyle(
              fontSize: 12,
              color: accentColor?.withValues(alpha: 0.85) ??
                  Colors.white.withValues(alpha: 0.6),
            ),
          ),
          if (chestColor != null) ...[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: chestColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (hasDigit)
            ThemedNumber(
              value: value,
              baseSize: 13,
              colorOverride: Colors.white,
              role: ThemedNumberRole.headline,
            )
          else
            GoopText(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (chestRank != null) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: (chestColor ?? Colors.white24)
                    .withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: (chestColor ?? Colors.white24)
                      .withValues(alpha: 0.7),
                  width: 0.7,
                ),
              ),
              child: GoopText(
                chestRank,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GunStats extends StatelessWidget {
  final Gun gun;
  const GunStats({super.key, required this.gun});

  Widget _buildGunderfuryInfo(BuildContext context, RunProvider p) {
    final lvl = p.gunderfuryLevel.clamp(1, 60);
    String formName = '';
    String description = '';
    String statsDesc = '';
    int currentXp = 0;

    if (lvl < 20) {
      formName = 'Base Form';
      description = 'Fires wide shotgun-like energy blasts.';
      statsDesc = 'Damage: 4.5 • Reload: 1.5s • Capacity: 450 • Spread: 10°';
      currentXp = ((lvl / 20) * 8000).round();
    } else if (lvl < 30) {
      formName = 'Automatic Form';
      description = 'Increases fire rate and becomes fully automatic.';
      statsDesc = 'Damage: 4.5 • Reload: 1.5s • Capacity: 450 • Spread: 10° (Auto)';
      currentXp = 8000 + (((lvl - 20) / 10) * 13000).round();
    } else if (lvl < 40) {
      formName = 'Defender Form';
      description = 'Shoots larger, high-velocity energy spheres with increased punch.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 5°';
      currentXp = 21000 + (((lvl - 30) / 10) * 16500).round();
    } else if (lvl < 50) {
      formName = 'Vindicator Form';
      description = 'Fires faster with elevated accuracy and tighter groupings.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 3°';
      currentXp = 37500 + (((lvl - 40) / 10) * 17500).round();
    } else if (lvl < 60) {
      formName = 'Laser Rifle';
      description = 'Fires sustained continuous rapid energy laser pulses.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 2°';
      currentXp = 55000 + (((lvl - 50) / 10) * 20000).round();
    } else {
      formName = 'Awakened Gunderfury';
      description = 'Legendary form of the Blessed Gunseeker. Rapidly shoots twin light beams with absolute 0° spread, bouncing, and piercing!';
      statsDesc = 'Damage: 10.0 • Reload: 0.6s • Capacity: 650 • Spread: 0° (Perfect accuracy, Piercing, Bouncing)';
      currentXp = 75000;
    }

    final double xpProgress = (currentXp / 75000).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.04),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: Colors.purpleAccent.shade100, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: GoopText(
                  'GUNDERFURY LEVEL TRACKER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.purpleAccent.shade100,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline, size: 22, color: Colors.white70),
                    onPressed: lvl > 1 ? () => p.setGunderfuryLevel(lvl - 1) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$lvl',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.white70),
                    onPressed: lvl < 60 ? () => p.setGunderfuryLevel(lvl + 1) : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.purpleAccent,
              inactiveTrackColor: Colors.purple.withValues(alpha: 0.2),
              thumbColor: Colors.purpleAccent,
              overlayColor: Colors.purpleAccent.withValues(alpha: 0.2),
              valueIndicatorColor: Colors.purple,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: SizedBox(
              height: 32,
              child: Slider(
                value: lvl.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                onChanged: (val) {
                  p.setGunderfuryLevel(val.round());
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const GoopText(
                'EXPERIENCE GAUGE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
              GoopText(
                lvl == 60 ? 'MAX LEVEL' : '${currentXp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / 75,000 XP',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: lvl == 60 ? Colors.amberAccent : Colors.purpleAccent.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 6,
              backgroundColor: Colors.purple.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(lvl == 60 ? Colors.amber : Colors.purpleAccent),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              QuickJumpButton(
                label: 'Lvl 10',
                active: lvl == 10,
                onTap: () => p.setGunderfuryLevel(10),
              ),
              QuickJumpButton(
                label: 'Lvl 20',
                active: lvl == 20,
                onTap: () => p.setGunderfuryLevel(20),
              ),
              QuickJumpButton(
                label: 'Lvl 30',
                active: lvl == 30,
                onTap: () => p.setGunderfuryLevel(30),
              ),
              QuickJumpButton(
                label: 'Lvl 40',
                active: lvl == 40,
                onTap: () => p.setGunderfuryLevel(40),
              ),
              QuickJumpButton(
                label: 'Lvl 50',
                active: lvl == 50,
                onTap: () => p.setGunderfuryLevel(50),
              ),
              QuickJumpButton(
                label: 'Lvl 60',
                active: lvl == 60,
                onTap: () => p.setGunderfuryLevel(60),
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3), width: 1.2),
                ),
                child: Image.asset(
                  'assets/images/guns/gunderfury.webp',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      'ACTIVE FORM: ${formName.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.purpleAccent,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    GoopText(
                      statsDesc,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GoopText(
            description,
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripleGunInfo(BuildContext context, RunProvider p) {
    final form = p.tripleGunForm;
    String formName = '';
    String formDesc = '';
    if (form == 1) {
      formName = 'Form 1: Pistol (100%-33% Ammo)';
      formDesc = 'Fires rapid light shots. Very accurate. Bullet count: 1.';
    } else if (form == 2) {
      formName = 'Form 2: Shotgun (33%-11% Ammo)';
      formDesc = 'Fires a 3-bullet spread shot at closer range. High stagger.';
    } else {
      formName = 'Form 3: Laser Machine Gun (<11% Ammo)';
      formDesc = 'Fires continuous energy beam blasts. Incredibly high damage and rapid rate of fire.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route, color: Colors.blueAccent.shade100, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: GoopText(
                  'Triple Gun Active Form',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              QuickJumpButton(
                label: 'Form 1',
                active: form == 1,
                onTap: () => p.setTripleGunForm(1),
              ),
              QuickJumpButton(
                label: 'Form 2',
                active: form == 2,
                onTap: () => p.setTripleGunForm(2),
              ),
              QuickJumpButton(
                label: 'Form 3',
                active: form == 3,
                onTap: () => p.setTripleGunForm(3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GoopText(
            formName,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          GoopText(
            formDesc,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolverInfo(BuildContext context, RunProvider p) {
    final activeStage = p.evolverForm;
    final totalKills = p.evolverKills;

    final stages = const [
      EvolverStageSpec(
        id: 1,
        name: 'Amoeba',
        dps: '13.5 DPS',
        bullet: 'Base round shots',
        icon: Icons.bubble_chart_outlined,
        color: Colors.tealAccent,
      ),
      EvolverStageSpec(
        id: 2,
        name: 'Sponge',
        dps: '19.1 DPS',
        bullet: 'Soaks up shots',
        icon: Icons.layers_outlined,
        color: Colors.greenAccent,
      ),
      EvolverStageSpec(
        id: 3,
        name: 'Flatworm',
        dps: '25.8 DPS',
        bullet: 'Wide flattened shots',
        icon: Icons.gesture_outlined,
        color: Colors.limeAccent,
      ),
      EvolverStageSpec(
        id: 4,
        name: 'Snail',
        dps: '34.5 DPS',
        bullet: '3-spiked shell spread',
        icon: Icons.gps_fixed_outlined,
        color: Colors.amberAccent,
      ),
      EvolverStageSpec(
        id: 5,
        name: 'Frog',
        dps: '23.0 DPS/sec',
        bullet: 'Continuous tracking tongue',
        icon: Icons.pets_outlined,
        color: Colors.orangeAccent,
      ),
      EvolverStageSpec(
        id: 6,
        name: 'Dragon',
        dps: '93.8 DPS',
        bullet: 'Accelerating homing blue flames',
        icon: Icons.fireplace_outlined,
        color: Colors.redAccent,
      ),
    ];

    final currentSpec = stages[activeStage - 1];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.03),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined, color: Colors.greenAccent.shade200, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      'THE EVOLVER: METAMORPHOSIS ENGINE',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.greenAccent.shade200,
                        letterSpacing: 0.8,
                      ),
                    ),
                    GoopText(
                      'Biological Adaptations Slay Counter',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: Colors.greenAccent.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove, size: 16, color: Colors.greenAccent),
                      onPressed: totalKills > 0 ? () => p.setEvolverKills(totalKills - 1) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GoopText(
                        '$totalKills/25',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'ArcadeClassic',
                          fontWeight: FontWeight.bold,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 16, color: Colors.greenAccent),
                      onPressed: totalKills < 25 ? () => p.setEvolverKills(totalKills + 1) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stages.length, (i) {
                final spec = stages[i];
                final isUnlocked = activeStage >= spec.id;
                final isActive = activeStage == spec.id;
                final color = isActive ? spec.color : (isUnlocked ? Colors.green.shade700 : Colors.white12);

                return Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (i < stages.length - 1)
                        Positioned(
                          left: 24,
                          right: -24,
                          top: 24,
                          child: Container(
                            height: 2.5,
                            color: isUnlocked && activeStage > spec.id
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.white10,
                          ),
                        ),
                      GestureDetector(
                        onTap: () {
                          p.setEvolverKills((spec.id - 1) * 5);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive ? Colors.black45 : Colors.black26,
                                border: Border.all(
                                  color: color,
                                  width: isActive ? 2.5 : 1.2,
                                ),
                                boxShadow: isActive ? [
                                  BoxShadow(
                                    color: spec.color.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ] : null,
                              ),
                              child: Icon(
                                isActive ? spec.icon : (isUnlocked ? spec.icon : Icons.lock_outline),
                                size: isActive ? 22 : 18,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            GoopText(
                              spec.name,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
                                color: isActive ? spec.color : Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          const GoopText(
            'UNIQUE ENEMY TYPES SLAIN CHECKLIST',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.greenAccent, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5.5,
            runSpacing: 5.5,
            children: List.generate(25, (index) {
              final killNum = index + 1;
              final isChecked = totalKills >= killNum;
              final isThresholdNode = killNum % 5 == 0;

              return GestureDetector(
                onTap: () {
                  if (isChecked) {
                    p.setEvolverKills(killNum - 1);
                  } else {
                    p.setEvolverKills(killNum);
                  }
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isChecked 
                        ? (isThresholdNode ? Colors.green.shade800 : Colors.green.withValues(alpha: 0.35))
                        : Colors.black38,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isChecked 
                          ? Colors.greenAccent 
                          : (isThresholdNode ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.white12),
                      width: isThresholdNode ? 1.5 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: isChecked 
                        ? Icon(isThresholdNode ? Icons.star : Icons.check, size: 13, color: Colors.greenAccent)
                        : Text(
                            '$killNum',
                            style: TextStyle(
                              fontSize: 9, 
                              fontWeight: FontWeight.bold, 
                              color: isThresholdNode ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.white24
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: currentSpec.color.withValues(alpha: 0.3), width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentSpec.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GoopText(
                      'BIO-ANALYSIS: STAGE ${currentSpec.id} [${currentSpec.name.toUpperCase()}]',
                      style: TextStyle(
                        fontFamily: 'EnterTheGungeonBig',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: currentSpec.color,
                      ),
                    ),
                    const Spacer(),
                    GoopText(
                      currentSpec.dps,
                      style: TextStyle(
                        fontFamily: 'ArcadeClassic',
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: currentSpec.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GoopText(
                  'Projectiles: ${currentSpec.bullet}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                const SizedBox(height: 3),
                GoopText(
                  'Formula: ${activeStage == 6 ? "Ultimate Form Unlocked!" : "Requires ${(activeStage * 5) - totalKills} more unique kills to force-evolve."}',
                  style: const TextStyle(fontSize: 10.5, color: Colors.white38),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShellegunInfo(BuildContext context, RunProvider p) {
    final mode = p.shellegunMode;
    const modeNames = ['Pistol (Manual)', 'Pistol (Auto)', 'Beam'];
    const modeDescs = [
      'Fires manually-controlled shells. Highest single-shot DPS.',
      'Fires automatically. Moderate fire rate, lower per-shot damage.',
      'Continuous beam. Low DPS but piercing and consistent.',
    ];
    const modeDps = [33.1, 24.0, 13.3];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Colors.tealAccent.shade100, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: GoopText(
                  'Shellegun Firing Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              QuickJumpButton(
                label: 'Manual',
                active: mode == 1,
                onTap: () => p.setShellegunMode(1),
              ),
              QuickJumpButton(
                label: 'Auto',
                active: mode == 2,
                onTap: () => p.setShellegunMode(2),
              ),
              QuickJumpButton(
                label: 'Beam',
                active: mode == 3,
                onTap: () => p.setShellegunMode(3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GoopText(
            'Form $mode: ${modeNames[mode - 1]} — ${modeDps[mode - 1]} DPS',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          GoopText(
            modeDescs[mode - 1],
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChamberGunInfo(BuildContext context, RunProvider p) {
    final floor = p.chamberGunFloor;
    const floorNames = [
      'Keep of the Lead Lord',
      'Oubliette',
      'Gungeon Proper',
      'Abbey of the True Gun',
      'Black Powder Mine',
      "Resourceful Rat's Lair",
      'The Hollow',
      'R&G Dept.',
      'The Forge',
      'Bullet Hell',
    ];
    const floorDps = [15.9, 30.3, 25.1, 80.0, 300.0, 20.0, 68.0, 100.0, 70.0, 180.0];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepOrangeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers, color: Colors.deepOrangeAccent.shade100, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: GoopText(
                  'Chamber Gun — Active Floor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrangeAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(floorNames.length, (i) {
              return QuickJumpButton(
                label: floorNames[i].split(' ').first,
                active: floor == i,
                onTap: () => p.setChamberGunFloor(i),
              );
            }),
          ),
          const SizedBox(height: 8),
          GoopText(
            '${floorNames[floor]} — ${floorDps[floor]} DPS',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          GoopText(
            'Chamber Gun transforms based on the current floor. Select your floor to see accurate DPS.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseyInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.lime.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.limeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_baseball, color: Colors.limeAccent.shade100, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: GoopText(
                  'Casey — Melee & Reflect',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.limeAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GoopText(
            '100 base damage per swing. Reflects enemy bullets back at them for massive damage. DPS shown (50) reflects only melee — actual combat value is far higher with bullet reflection.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final combat = <MapEntry<String, String>>[
      MapEntry('Damage', gun.damage),
      MapEntry('Fire rate', gun.fireRate),
      MapEntry('Magazine', gun.magazineSize),
      MapEntry('Max ammo', gun.ammoCapacity),
      MapEntry('Reload', gun.reloadTime),
    ].where((e) => e.value.isNotEmpty).toList();
    final handling = <MapEntry<String, String>>[
      MapEntry('Range', gun.range),
      MapEntry('Shot speed', gun.shotSpeed),
      MapEntry('Force', gun.force),
      MapEntry('Spread', gun.spread),
    ].where((e) => e.value.isNotEmpty).toList();
    final meta = <MapEntry<String, String>>[
      MapEntry('Class', gun.gunClass),
    ].where((e) => e.value.isNotEmpty).toList();

    final p = context.watch<RunProvider>();
    final gunderfuryInfo = gun.name.toLowerCase() == 'gunderfury'
        ? _buildGunderfuryInfo(context, p)
        : null;
    final tripleGunInfo = gun.name.toLowerCase() == 'triple gun'
        ? _buildTripleGunInfo(context, p)
        : null;
    final evolverInfo = gun.name.toLowerCase() == 'evolver'
        ? _buildEvolverInfo(context, p)
        : null;
    final shellegunInfo = gun.name.toLowerCase() == 'shellegun'
        ? _buildShellegunInfo(context, p)
        : null;
    final chamberGunInfo = gun.name.toLowerCase() == 'chamber gun'
        ? _buildChamberGunInfo(context, p)
        : null;
    final caseyInfo = gun.name.toLowerCase() == 'casey'
        ? _buildCaseyInfo(context)
        : null;

    final String animationAsset;
    final bool isGunderfury = gun.name.toLowerCase() == 'gunderfury';
    final String displayType = isGunderfury ? '???' : gun.type;
    final String typeLower = gun.type.toLowerCase();
    if (typeLower.contains('charged') || typeLower.contains('charge')) {
      animationAsset = 'assets/animations/gun_types/Chargeweapon_demo.gif';
    } else if (typeLower.contains('beam')) {
      animationAsset = 'assets/animations/gun_types/Beamweapon_demo.gif';
    } else if (typeLower.contains('burst')) {
      animationAsset = 'assets/animations/gun_types/Burstweapon_demo.gif';
    } else if (typeLower.contains('automatic') || typeLower.contains('auto')) {
      animationAsset = 'assets/animations/gun_types/Automaticweapon_demo.gif';
    } else {
      animationAsset = 'assets/animations/gun_types/Semiautomaticweapon_demo.gif';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      height: 142,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.flair.scaffold.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.flair.primary.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bolt, size: 14, color: AppTheme.flair.primary),
                              const SizedBox(width: 4),
                              Flexible(
                                child: GoopText(
                                  displayType.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.flair.headlineStat,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              animationAsset,
                              height: 80,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.none,
                              errorBuilder: (_, __, ___) => Container(
                                height: 80,
                                alignment: Alignment.center,
                                child: GoopText(
                                  displayType,
                                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 142,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.flair.scaffold.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.flair.primary.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flash_on, size: 14, color: AppTheme.flair.secondary),
                              const SizedBox(width: 4),
                              GoopText(
                                'GUN DPS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.flair.headlineStat,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GoopText(
                            isGunderfury
                                ? gun.getDynamicDps(gunderLevel: p.gunderfuryLevel).toStringAsFixed(1)
                                : (gun.dpsValue > 0 ? gun.dpsValue.toStringAsFixed(1) : (gun.dps.isEmpty ? '0.0' : gun.dps)),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.flair.secondary,
                              height: 1.0,
                              shadows: [
                                Shadow(
                                  color: AppTheme.flair.secondary.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          GoopText(
                            'Damage Per Second',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (gunderfuryInfo != null) ...[
                gunderfuryInfo,
                const SizedBox(height: 14),
              ],
              if (tripleGunInfo != null) ...[
                tripleGunInfo,
                const SizedBox(height: 14),
              ],
              if (evolverInfo != null) ...[
                evolverInfo,
                const SizedBox(height: 14),
              ],
              if (shellegunInfo != null) ...[
                shellegunInfo,
                const SizedBox(height: 14),
              ],
              if (chamberGunInfo != null) ...[
                chamberGunInfo,
                const SizedBox(height: 14),
              ],
              if (caseyInfo != null) ...[
                caseyInfo,
                const SizedBox(height: 14),
              ],
              if (gun.notes.isNotEmpty) ...[
                GoopText(
                  gun.notes,
                  style: const TextStyle(fontSize: 14.5, height: 1.35),
                ),
                const Divider(height: 26),
              ],
              if (combat.isNotEmpty)
                StatGroup(
                  label: 'Combat',
                  icon: Icons.local_fire_department,
                  stats: combat,
                ),
              if (handling.isNotEmpty) ...[
                if (combat.isNotEmpty) const SizedBox(height: 14),
                StatGroup(
                  label: 'Handling',
                  icon: Icons.tune,
                  stats: handling,
                ),
              ],
              if (meta.isNotEmpty) ...[
                if (combat.isNotEmpty || handling.isNotEmpty)
                  const SizedBox(height: 14),
                StatGroup(
                  label: 'Meta',
                  icon: Icons.info_outline,
                  stats: meta,
                ),
              ],
            ],
          ),
    );
  }
}
