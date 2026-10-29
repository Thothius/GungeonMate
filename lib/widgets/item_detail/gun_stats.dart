import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gun.dart';
import '../../providers/run_provider.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../theme/tokens.dart';
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

  /// Resolves the group's accent color: theme override if set, else
  /// semantic defaults (Combat=red, Handling=cyan, Meta=amber).
  Color _groupColor() {
    final f = AppTheme.flair;
    switch (label.toLowerCase()) {
      case 'combat':
        return f.statGroupCombat ?? const Color(0xFFFF5252);
      case 'handling':
        return f.statGroupHandling ?? const Color(0xFF40C4FF);
      case 'meta':
        return f.statGroupMeta ?? const Color(0xFFFFD54F);
      default:
        return f.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _groupColor();
    final flair = AppTheme.flair;
    final useFilledPill = flair.chipFilled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: Insets.sm),
          child:
              useFilledPill
                  ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.all(Radii.sm),
                      border: Border.all(
                        color: color.withValues(alpha: 0.5),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18, color: color),
                        const SizedBox(width: 7),
                        GoopText(
                          label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  )
                  : Row(
                    children: [
                      Container(
                        width: 3,
                        height: 18,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 7),
                      GoopText(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: color,
                        ),
                      ),
                    ],
                  ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children:
              stats
                  .map(
                    (e) => StatPill(
                      label: e.key,
                      value: e.value,
                      groupColor: color,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? groupColor;
  const StatPill({
    super.key,
    required this.label,
    required this.value,
    this.groupColor,
  });

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
    final accentColor =
        isCharge
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
        color:
            filled
                ? (accentColor?.withValues(alpha: 0.08) ??
                    Colors.white.withValues(alpha: 0.06))
                : null,
        borderRadius: BorderRadius.circular(flair.chipRadius),
        border:
            filled
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
          if (isCharge) ...[
            Icon(Icons.electric_bolt, size: 12, color: Colors.lightBlueAccent),
            const SizedBox(width: 3),
          ],
          if (isDuration) ...[
            Icon(
              Icons.timer_outlined,
              size: 12,
              color: Colors.greenAccent.shade200,
            ),
            const SizedBox(width: 3),
          ],
          GoopText(
            '$label  ',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color:
                  accentColor?.withValues(alpha: 0.85) ??
                  groupColor?.withValues(alpha: 0.75) ??
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          if (chestRank != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: (chestColor ?? Colors.white24).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: (chestColor ?? Colors.white24).withValues(alpha: 0.7),
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
    final lvl = context
        .select<RunProvider, int>((p) => p.gunderfuryLevel)
        .clamp(1, 60);
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
      statsDesc =
          'Damage: 4.5 • Reload: 1.5s • Capacity: 450 • Spread: 10° (Auto)';
      currentXp = 8000 + (((lvl - 20) / 10) * 13000).round();
    } else if (lvl < 40) {
      formName = 'Defender Form';
      description =
          'Shoots larger, high-velocity energy spheres with increased punch.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 5°';
      currentXp = 21000 + (((lvl - 30) / 10) * 16500).round();
    } else if (lvl < 50) {
      formName = 'Vindicator Form';
      description =
          'Fires faster with elevated accuracy and tighter groupings.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 3°';
      currentXp = 37500 + (((lvl - 40) / 10) * 17500).round();
    } else if (lvl < 60) {
      formName = 'Laser Rifle';
      description = 'Fires sustained continuous rapid energy laser pulses.';
      statsDesc = 'Damage: 6.5 • Reload: 1.1s • Capacity: 550 • Spread: 2°';
      currentXp = 55000 + (((lvl - 50) / 10) * 20000).round();
    } else {
      formName = 'Awakened Gunderfury';
      description =
          'Legendary form of the Blessed Gunseeker. Rapidly shoots twin light beams with absolute 0° spread, bouncing, and piercing!';
      statsDesc =
          'Damage: 10.0 • Reload: 0.6s • Capacity: 650 • Spread: 0° (Perfect accuracy, Piercing, Bouncing)';
      currentXp = 75000;
    }

    final double xpProgress = (currentXp / 75000).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: Insets.md),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(
          color: Colors.purpleAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
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
              const SizedBox(width: Insets.sm),
              Expanded(
                child: GoopText(
                  'GUNDERFURY LEVEL TRACKER',
                  style: TextStyle(
                    fontSize: FontSizes.labelMedium,
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
                    tooltip: 'Decrease Gunderfury level',
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      size: 22,
                      color: Colors.white70,
                    ),
                    onPressed:
                        lvl > 1 ? () => p.setGunderfuryLevel(lvl - 1) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$lvl',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Increase Gunderfury level',
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 22,
                      color: Colors.white70,
                    ),
                    onPressed:
                        lvl < 60 ? () => p.setGunderfuryLevel(lvl + 1) : null,
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
              height: Insets.xxl,
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
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  color: Colors.white54,
                  letterSpacing: 0.5,
                ),
              ),
              GoopText(
                lvl == 60
                    ? 'MAX LEVEL'
                    : '${currentXp.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} / 75,000 XP',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.bold,
                  color:
                      lvl == 60
                          ? Colors.amberAccent
                          : Colors.purpleAccent.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: xpProgress,
              minHeight: 6,
              backgroundColor: Colors.purple.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                lvl == 60 ? Colors.amber : Colors.purpleAccent,
              ),
            ),
          ),
          const SizedBox(height: Insets.md),
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
                padding: const EdgeInsets.all(Insets.xs),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.all(Radii.sm),
                  border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.3),
                    width: 1.2,
                  ),
                ),
                child: Image.asset(
                  'assets/images/guns/gunderfury.webp',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  cacheWidth: 88,
                  cacheHeight: 88,
                ),
              ),
              const SizedBox(width: Insets.md),
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
          const SizedBox(height: Insets.sm),
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
    final form = context.select<RunProvider, int>((p) => p.tripleGunForm);
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
      formDesc =
          'Fires continuous energy beam blasts. Incredibly high damage and rapid rate of fire.';
    }

    return Container(
      padding: const EdgeInsets.all(Insets.md),
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
              Icon(
                Icons.alt_route,
                color: Colors.blueAccent.shade100,
                size: 20,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: GoopText(
                  'Triple Gun Active Form',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
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
          const SizedBox(height: Insets.sm),
          GoopText(
            formName,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Insets.xs),
          GoopText(
            formDesc,
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvolverInfo(BuildContext context, RunProvider p) {
    final activeStage = context.select<RunProvider, int>((p) => p.evolverForm);
    final totalKills = context.select<RunProvider, int>((p) => p.evolverKills);

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
        dps: '23.0 DPS',
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
        border: Border.all(
          color: Colors.greenAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
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
              Icon(
                Icons.science_outlined,
                color: Colors.greenAccent.shade200,
                size: 22,
              ),
              const SizedBox(width: Insets.sm),
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
                        fontSize: FontSizes.labelSmall,
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
                  borderRadius: BorderRadius.all(Radii.sm),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Decrease Evolver kills',
                      icon: const Icon(
                        Icons.remove,
                        size: 16,
                        color: Colors.greenAccent,
                      ),
                      onPressed:
                          totalKills > 0
                              ? () => p.setEvolverKills(totalKills - 1)
                              : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Insets.xs,
                      ),
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
                      tooltip: 'Increase Evolver kills',
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.greenAccent,
                      ),
                      onPressed:
                          totalKills < 25
                              ? () => p.setEvolverKills(totalKills + 1)
                              : null,
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
                final color =
                    isActive
                        ? spec.color
                        : (isUnlocked ? Colors.green.shade700 : Colors.white12);

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
                            color:
                                isUnlocked && activeStage > spec.id
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
                                color:
                                    isActive ? Colors.black45 : Colors.black26,
                                border: Border.all(
                                  color: color,
                                  width: isActive ? 2.5 : 1.2,
                                ),
                                boxShadow:
                                    isActive
                                        ? [
                                          BoxShadow(
                                            color: spec.color.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Icon(
                                isActive
                                    ? spec.icon
                                    : (isUnlocked
                                        ? spec.icon
                                        : Icons.lock_outline),
                                size: isActive ? 22 : 18,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: Insets.xs),
                            GoopText(
                              spec.name,
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
                                fontWeight:
                                    isActive
                                        ? FontWeight.w900
                                        : FontWeight.bold,
                                color: isActive ? spec.color : Colors.white60,
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
          const SizedBox(height: Insets.md),
          const GoopText(
            'UNIQUE ENEMY TYPES SLAIN CHECKLIST',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w900,
              color: Colors.greenAccent,
              letterSpacing: 0.5,
            ),
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
                    color:
                        isChecked
                            ? (isThresholdNode
                                ? Colors.green.shade800
                                : Colors.green.withValues(alpha: 0.35))
                            : Colors.black38,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          isChecked
                              ? Colors.greenAccent
                              : (isThresholdNode
                                  ? Colors.greenAccent.withValues(alpha: 0.3)
                                  : Colors.white12),
                      width: isThresholdNode ? 1.5 : 1.0,
                    ),
                  ),
                  child: Center(
                    child:
                        isChecked
                            ? Icon(
                              isThresholdNode ? Icons.star : Icons.check,
                              size: 13,
                              color: Colors.greenAccent,
                            )
                            : Text(
                              '$killNum',
                              style: TextStyle(
                                fontSize: FontSizes.labelSmall,
                                fontWeight: FontWeight.bold,
                                color:
                                    isThresholdNode
                                        ? Colors.greenAccent.withValues(
                                          alpha: 0.4,
                                        )
                                        : Colors.white54,
                              ),
                            ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: Insets.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: Insets.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: currentSpec.color.withValues(alpha: 0.3),
                width: 1.0,
              ),
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
                    const SizedBox(width: Insets.sm),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 3),
                GoopText(
                  'Formula: ${activeStage == 6 ? "Ultimate Form Unlocked!" : "Requires ${(activeStage * 5) - totalKills} more unique kills to force-evolve."}',
                  style: const TextStyle(fontSize: 10.5, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShellegunInfo(BuildContext context, RunProvider p) {
    final mode = context.select<RunProvider, int>((p) => p.shellegunMode);
    const modeNames = ['Pistol (Manual)', 'Pistol (Auto)', 'Beam'];
    const modeDescs = [
      'Fires manually-controlled shells. Highest single-shot DPS.',
      'Fires automatically. Moderate fire rate, lower per-shot damage.',
      'Continuous beam. Low DPS but piercing and consistent.',
    ];
    const modeDps = [33.1, 24.0, 13.3];

    return Container(
      padding: const EdgeInsets.all(Insets.md),
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
              const SizedBox(width: Insets.sm),
              Expanded(
                child: GoopText(
                  'Shellegun Firing Mode',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
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
          const SizedBox(height: Insets.sm),
          GoopText(
            'Form $mode: ${modeNames[mode - 1]} — ${modeDps[mode - 1]} DPS',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Insets.xs),
          GoopText(
            modeDescs[mode - 1],
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChamberGunInfo(BuildContext context, RunProvider p) {
    final floor = context.select<RunProvider, int>((p) => p.chamberGunFloor);
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
    const floorDps = [
      15.9,
      30.3,
      25.1,
      80.0,
      300.0,
      20.0,
      68.0,
      100.0,
      70.0,
      180.0,
    ];

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.deepOrangeAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.layers,
                color: Colors.deepOrangeAccent.shade100,
                size: 20,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: GoopText(
                  'Chamber Gun — Active Floor',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrangeAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
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
          const SizedBox(height: Insets.sm),
          GoopText(
            '${floorNames[floor]} — ${floorDps[floor]} DPS',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: Insets.xs),
          GoopText(
            'Chamber Gun transforms based on the current floor. Select your floor to see accurate DPS.',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
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
      padding: const EdgeInsets.all(Insets.md),
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
              Icon(
                Icons.sports_baseball,
                color: Colors.limeAccent.shade100,
                size: 20,
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: GoopText(
                  'Casey — Melee & Reflect',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Colors.limeAccent.shade100,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          GoopText(
            '100 base damage per swing. Reflects enemy bullets back at them for massive damage. DPS shown (50) reflects only melee — actual combat value is far higher with bullet reflection.',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
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
    final p = context.read<RunProvider>();
    final gunderfuryLevel = context.select<RunProvider, int>(
      (p) => p.gunderfuryLevel,
    );
    final gunderfuryInfo =
        gun.name.toLowerCase() == 'gunderfury'
            ? _buildGunderfuryInfo(context, p)
            : null;
    final tripleGunInfo =
        gun.name.toLowerCase() == 'triple gun'
            ? _buildTripleGunInfo(context, p)
            : null;
    final evolverInfo =
        gun.name.toLowerCase() == 'evolver'
            ? _buildEvolverInfo(context, p)
            : null;
    final shellegunInfo =
        gun.name.toLowerCase() == 'shellegun'
            ? _buildShellegunInfo(context, p)
            : null;
    final chamberGunInfo =
        gun.name.toLowerCase() == 'chamber gun'
            ? _buildChamberGunInfo(context, p)
            : null;
    final caseyInfo =
        gun.name.toLowerCase() == 'casey' ? _buildCaseyInfo(context) : null;

    final String typeLower = gun.type.toLowerCase();
    if (typeLower.contains('charged') || typeLower.contains('charge')) {
    } else if (typeLower.contains('beam')) {
    } else if (typeLower.contains('burst')) {
    } else if (typeLower.contains('automatic') || typeLower.contains('auto')) {
    } else {}

    // All form-stateful guns get their dynamic DPS — same params
    // _avgDpsFor uses, so the header stat matches run averages.
    final String dpsValue = () {
      final dyn = gun.getDynamicDps(
        gunderLevel: gunderfuryLevel,
        tripleForm: context.select<RunProvider, int>((p) => p.tripleGunForm),
        evolverStage: context.select<RunProvider, int>((p) => p.evolverForm),
        shellegunMode: context.select<RunProvider, int>((p) => p.shellegunMode),
        chamberGunFloor: context.select<RunProvider, int>(
          (p) => p.chamberGunFloor,
        ),
      );
      return dyn > 0
          ? dyn.toStringAsFixed(1)
          : (gun.dps.isEmpty ? '0.0' : gun.dps);
    }();

    // Hero row — the four stats that matter most (per redesign):
    // DPS panel + RANGE/SPREAD/FORCE uniform cards.
    final heroStats =
        <_StatSpec>[
          _StatSpec(
            label: 'Range',
            value: gun.range,
            icon: Icons.linear_scale,
            category: _StatCategory.handling,
          ),
          _StatSpec(
            label: 'Spread',
            value: gun.spread,
            icon: Icons.scatter_plot,
            category: _StatCategory.handling,
          ),
          _StatSpec(
            label: 'Force',
            value: gun.force,
            icon: Icons.waves,
            category: _StatCategory.handling,
          ),
        ].where((s) => s.value.isNotEmpty).toList();

    // Secondary grid — everything else, compact.
    final secondaryStats =
        <_StatSpec>[
          _StatSpec(
            label: 'Damage',
            value: gun.damage,
            icon: Icons.bolt,
            category: _StatCategory.combat,
          ),
          _StatSpec(
            label: 'Fire Rate',
            value: gun.fireRate,
            icon: Icons.speed,
            category: _StatCategory.combat,
          ),
          _StatSpec(
            label: 'Reload',
            value: gun.reloadTime,
            icon: Icons.refresh,
            category: _StatCategory.combat,
          ),
          _StatSpec(
            label: 'Shot Speed',
            value: gun.shotSpeed,
            icon: Icons.fast_forward,
            category: _StatCategory.handling,
          ),
          _StatSpec(
            label: 'Magazine',
            value: gun.magazineSize,
            icon: Icons.inventory_2_outlined,
            category: _StatCategory.combat,
          ),
          _StatSpec(
            label: 'Max Ammo',
            value: gun.ammoCapacity,
            icon: Icons.all_inclusive_outlined,
            category: _StatCategory.combat,
          ),
          _StatSpec(
            label: 'Class',
            value: gun.gunClass,
            icon: Icons.category_outlined,
            category: _StatCategory.meta,
          ),
          _StatSpec(
            label: 'Chest',
            value: gun.chestColorDisplay,
            icon: Icons.inventory_2_outlined,
            category: _StatCategory.meta,
          ),
          if (gun.curse > 0)
            _StatSpec(
              label: 'Curse',
              value: '+${gun.curse}',
              icon: Icons.mood_bad_outlined,
              category: _StatCategory.meta,
            ),
          if (gun.coolness > 0)
            _StatSpec(
              label: 'Cool',
              value: '+${gun.coolness}',
              icon: Icons.ac_unit,
              category: _StatCategory.meta,
            ),
        ].where((s) => s.value.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero row: DPS panel + RANGE/SPREAD/FORCE cards ──
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildDpsPanel(dpsValue)),
                const SizedBox(width: 8),
                for (final s in heroStats)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _PrimaryStatCard(spec: s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ── Special gun info panels (unchanged) ──
          if (gunderfuryInfo != null) ...[
            gunderfuryInfo,
            const SizedBox(height: 14),
          ],
          if (tripleGunInfo != null) ...[
            tripleGunInfo,
            const SizedBox(height: 14),
          ],
          if (evolverInfo != null) ...[evolverInfo, const SizedBox(height: 14)],
          if (shellegunInfo != null) ...[
            shellegunInfo,
            const SizedBox(height: 14),
          ],
          if (chamberGunInfo != null) ...[
            chamberGunInfo,
            const SizedBox(height: 14),
          ],
          if (caseyInfo != null) ...[caseyInfo, const SizedBox(height: 14)],

          // ── Row 3: secondary stats — compact responsive wrap ──
          if (secondaryStats.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  secondaryStats
                      .map((s) => _SecondaryStatChip(spec: s))
                      .toList(),
            ),
        ],
      ),
    );
  }

  /// DPS summary panel — large number, label, and icon. Visually balanced
  Widget _buildDpsPanel(String dpsValue) {
    final flair = AppTheme.flair;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: flair.scaffold.withValues(alpha: 0.6),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(
          color: flair.secondary.withValues(alpha: 0.3),
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
              Icon(Icons.flash_on, size: 14, color: flair.secondary),
              const SizedBox(width: Insets.xs),
              GoopText(
                'DPS',
                style: TextStyle(
                  fontSize: FontSizes.labelSmall,
                  fontWeight: FontWeight.w900,
                  color: flair.headlineStat,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          GoopText(
            dpsValue,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: flair.secondary,
              height: 1.0,
              shadows: [
                Shadow(
                  color: flair.secondary.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xs),
          GoopText(
            'Damage / sec',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat category — mirrors the old Combat/Handling/Meta grouping so the
/// color coding users knew is preserved without the heavy group headers.
enum _StatCategory { combat, handling, meta }

extension _StatCategoryColor on _StatCategory {
  /// Resolves the theme-tied category color, falling back to the canonical
  /// Combat=red, Handling=cyan, Meta=amber when a theme hasn't opted in.
  Color color(ThemeFlair flair) {
    switch (this) {
      case _StatCategory.combat:
        return flair.statGroupCombat ?? Colors.redAccent;
      case _StatCategory.handling:
        return flair.statGroupHandling ?? Colors.cyanAccent;
      case _StatCategory.meta:
        return flair.statGroupMeta ?? Colors.amberAccent;
    }
  }
}

/// Lightweight data holder for a single stat entry.
class _StatSpec {
  final String label;
  final String value;
  final IconData icon;
  final _StatCategory category;
  const _StatSpec({
    required this.label,
    required this.value,
    required this.icon,
    required this.category,
  });
}

/// Uniform vertical stat card for primary stats (Damage, Fire Rate, Range,
/// Force). Icon → value → label, all centered and consistently sized.
class _PrimaryStatCard extends StatelessWidget {
  final _StatSpec spec;
  const _PrimaryStatCard({required this.spec});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final catColor = spec.category.color(flair);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(color: catColor.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(spec.icon, size: 20, color: catColor),
          const SizedBox(height: 6),
          GoopText(
            spec.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: flair.headlineStat,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 3),
          GoopText(
            spec.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.5),
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact horizontal stat chip for secondary stats (Magazine, Max Ammo,
/// Reload, Shot Speed, Spread, Class). Icon + label + value in a row.
class _SecondaryStatChip extends StatelessWidget {
  final _StatSpec spec;
  const _SecondaryStatChip({required this.spec});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final catColor = spec.category.color(flair);
    final hasDigit = RegExp(r'\d').hasMatch(spec.value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: catColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: catColor.withValues(alpha: 0.22), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spec.icon, size: 11, color: catColor.withValues(alpha: 0.85)),
          const SizedBox(width: 4),
          GoopText(
            spec.label,
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 4),
          if (hasDigit)
            ThemedNumber(
              value: spec.value,
              baseSize: 11,
              colorOverride: flair.headlineStat,
              role: ThemedNumberRole.headline,
            )
          else
            GoopText(
              spec.value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: flair.headlineStat,
              ),
            ),
        ],
      ),
    );
  }
}
