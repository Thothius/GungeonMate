part of 'item_body.dart';

// Special-item info sections extracted from ItemBody (Phase 5d) —
// same library, abstract field requirements satisfied by ItemBody.

mixin _ItemBodySections on StatelessWidget {
  Item get item;
  PlayerSlot? get ownerSlot;

  String? _extractDuration() {
    final effect = item.effect;
    if (effect.isEmpty) return null;
    final m = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:seconds?|secs?|s)\b',
      caseSensitive: false,
    ).firstMatch(effect);
    if (m == null) return null;
    final raw = m.group(1) ?? '';
    if (raw.isEmpty) return null;
    final asString = '${raw}s';
    final rt = item.rechargeTime.toLowerCase();
    if (rt.contains('${raw}s') || rt.contains('$raw second')) return null;
    return asString;
  }

  Widget _buildJunkanInfo(BuildContext context) {
    final p = context.watch<RunProvider>();
    final slot = ownerSlot ?? PlayerSlot.main;
    final player =
        slot == PlayerSlot.coop
            ? (p.runState.coop ?? Player())
            : p.runState.main;
    final junkCount =
        player.items.where((i) => i.name.toLowerCase() == 'junk').length;
    final hasGoldJunk = player.items.any(
      (i) => i.name.toLowerCase() == 'gold junk',
    );

    String rankName = '';
    String description = '';
    String stats = '';

    if (hasGoldJunk) {
      rankName = 'MECHA JUNKAN (GOLD MECHSUIT)';
      description =
          'High-tech gold mechsuit! Jammed enemies struck by Mecha Junkan\'s machine gun become normal. Bypasses boss DPS cap.';
      stats =
          'Damage: 2.2/shot (Machine Gun) • 20.0 (Laser blade) • 8.0/rocket (Homing Rockets)';
    } else {
      switch (junkCount) {
        case 0:
          rankName = 'PEASANT';
          description = 'Junkan harmlessly pushes enemies around.';
          stats = 'Damage: 0.0 • Role: Companion • Speed: Steady';
          break;
        case 1:
          rankName = 'SQUIRE';
          description = 'Gains helmet. Headbutts enemies slowly.';
          stats = 'Damage: 3.0 • Attack: Headbutt • Armor: Helmet';
          break;
        case 2:
          rankName = 'HEDGE KNIGHT';
          description =
              'Gains shield. Attacks more frequently by shield-bashing enemies.';
          stats = 'Damage: 5.0 • Attack: Shield-bash • Armor: Shield';
          break;
        case 3:
          rankName = 'KNIGHT';
          description =
              'Gains sword. Attacks more frequently by slicing enemies.';
          stats = 'Damage: 7.0 • Attack: Sword-slice • Armor: Sword';
          break;
        case 4:
          rankName = 'KNIGHT LIEUTENANT';
          description =
              'Gains helmet adornment. Sword attacks are faster and deal more damage.';
          stats = 'Damage: 9.0 • Attack: Upgraded Slice • Armor: Plated';
          break;
        case 5:
          rankName = 'KNIGHT COMMANDER';
          description =
              'Gains cape. Spin-attacks multiple enemies simultaneously.';
          stats =
              'Damage: 10.0 × 2 (Double Spin) • Attack: Spin Attack • Armor: Cape';
          break;
        case 6:
          rankName = 'HOLY KNIGHT';
          description =
              'White color scheme. Occasionally Blanks. Sacrifices himself to revive the player at full health if they die.';
          stats =
              'Damage: 13.33 • Attack: Holy Slice • Ability: Blank + Sacrifice';
          break;
        default:
          rankName = 'ANGELIC KNIGHT (7+ JUNK)';
          description =
              'Gains angel armor & wings. Flying. Fires rapid pink projectiles. Loses Blanks and Sacrifice ability.';
          stats =
              'Damage: 10.0/shot • Attack: Ranged Pink Shots • Ability: Flying';
          break;
      }
    }

    final junkItem = p.itemByName('Junk');
    final goldJunkItem = p.itemByName('Gold Junk');

    final String imgPath =
        hasGoldJunk
            ? 'assets/images/junkan/gold.webp'
            : switch (junkCount) {
              0 => 'assets/images/junkan/1.webp',
              1 => 'assets/images/junkan/3.webp',
              2 => 'assets/images/junkan/4.webp',
              3 => 'assets/images/junkan/5.webp',
              4 => 'assets/images/junkan/6.webp',
              5 => 'assets/images/junkan/7.webp',
              6 => 'assets/images/junkan/8.webp',
              _ => 'assets/images/junkan/8.webp',
            };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Skeuo.inkIf(Colors.amber).withValues(alpha: 0.08),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(
          color: Skeuo.inkIf(Colors.amber).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Skeuo.inkIf(Colors.amber).withValues(alpha: 0.04),
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
              Icon(
                Icons.stars,
                color: Skeuo.inkIf(Colors.amber.shade300),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: GoopText(
                  'SER JUNKAN LEVEL TRACKER',
                  style: TextStyle(
                    fontSize: FontSizes.labelMedium,
                    fontWeight: FontWeight.w900,
                    color: Skeuo.inkIf(Colors.amber.shade300),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: Skeuo.collapse(Colors.white54),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  GoopText(
                    'Regular Junk:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Remove Junk',
                    icon: Icon(
                      Icons.remove_circle_outline,
                      size: 22,
                      color: Skeuo.collapse(Colors.white70),
                    ),
                    onPressed:
                        junkCount > 0 && junkItem != null
                            ? () => p.removeItem(junkItem, slot: slot)
                            : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Skeuo.collapse(Colors.black26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$junkCount',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Skeuo.inkIf(Colors.amber),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Add Junk',
                    icon: Icon(
                      Icons.add_circle_outline,
                      size: 22,
                      color: Skeuo.collapse(Colors.white70),
                    ),
                    onPressed:
                        junkItem != null
                            ? () => p.addItem(junkItem, slot: slot)
                            : null,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.precision_manufacturing_outlined,
                    color: Skeuo.inkIf(Colors.amber.shade200),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  GoopText(
                    'Has Gold Junk (Mech Suit):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Switch(
                value: hasGoldJunk,
                activeThumbColor: Skeuo.inkIf(Colors.amber),
                onChanged: (val) {
                  if (goldJunkItem == null) return;
                  if (val) {
                    p.addItem(goldJunkItem, slot: slot);
                  } else {
                    p.removeItem(goldJunkItem, slot: slot);
                  }
                },
              ),
            ],
          ),
          Divider(color: Skeuo.collapse(Colors.white12), height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(Insets.xs),
                decoration: BoxDecoration(
                  color: Skeuo.collapse(Colors.black38),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Skeuo.inkIf(Colors.amber).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    imgPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                    cacheWidth: 144,
                    cacheHeight: 144,
                    errorBuilder:
                        (_, _, _) => Icon(
                          Icons.shield,
                          color: Skeuo.inkIf(Colors.amber),
                          size: 32,
                        ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      'ACTIVE FORM: $rankName',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Skeuo.inkIf(Colors.amberAccent),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    GoopText(
                      stats,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Skeuo.collapse(Colors.white),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          GoopText(
            description,
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.75),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpiceInfo(BuildContext context) {
    final p = context.read<RunProvider>();
    final count = context.select<RunProvider, int>((p) => p.spiceUsageCount);

    String currentEffects = '';
    String nextEffects = '';

    if (count == 0) {
      currentEffects = 'No Spice used yet.';
      nextEffects =
          '1st Use: +1 Heart Container, +1 Coolness, +20% Shot Speed, -10% Spread, +0.5 Curse, changes pickup quote.';
    } else if (count == 1) {
      currentEffects =
          '1st Use Applied: +1 Heart Container, +1 Coolness, +20% Shot Speed, -10% Spread, +0.5 Curse.';
      nextEffects =
          '2nd Use: +1 Coolness, +20% Shot Speed, -10% Spread, +20% Damage, -1 Heart Container, +1.0 Curse.';
    } else if (count == 2) {
      currentEffects =
          '2nd Use Applied: +2 Coolness, +40% Shot Speed, -19% Spread, +20% Damage, +1.0 Curse total.';
      nextEffects =
          '3rd Use: +20% Damage, -10% Spread, -1 Heart Container, +1.0 Curse.';
    } else if (count == 3) {
      currentEffects =
          '3rd Use Applied: +2 Coolness, +40% Shot Speed, -27% Spread, +40% Damage, -1 Heart Container total, +2.0 Curse total.';
      nextEffects =
          '4th Use: +15% Damage, -10% Spread, -1 Heart Container, +1.0 Curse.';
    } else if (count == 4) {
      currentEffects =
          '4th Use Applied: +2 Coolness, +40% Shot Speed, -34% Spread, +55% Damage, -2 Heart Containers total, +3.0 Curse total.';
      nextEffects =
          '5th+ Use: +15% Damage, +1.0 Curse (no more spread or health penalties).';
    } else {
      final extraUses = count - 4;
      final damageBonus = 55 + (extraUses * 15);
      final curseTotal = 3.0 + extraUses;
      currentEffects =
          '$count Uses Applied: +2 Coolness, +40% Shot Speed, -34% Spread, +$damageBonus% Damage, -2 Heart Containers, +$curseTotal Curse total.';
      nextEffects = 'Subsequent Uses: +15% Damage, +1.0 Curse per use.';
    }

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Skeuo.inkIf(Colors.red).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Skeuo.inkIf(Colors.redAccent).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.spa,
                color: Skeuo.inkIf(Colors.redAccent.shade100),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: GoopText(
                  'Spice Addiction Tracker',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Skeuo.inkIf(Colors.redAccent.shade100),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove armor',
                icon: Icon(
                  Icons.remove_circle_outline,
                  size: 22,
                  color: Skeuo.collapse(Colors.white70),
                ),
                onPressed:
                    count > 0
                        ? () {
                          final double curseToSubtract =
                              (count == 1) ? 0.5 : 1.0;
                          final double coolnessToSubtract =
                              (count <= 2) ? 1.0 : 0.0;
                          p.setSpiceUsageCount(count - 1);
                          p.adjustCurse(-curseToSubtract);
                          if (coolnessToSubtract != 0) {
                            p.adjustCoolness(-coolnessToSubtract);
                          }
                        }
                        : null,
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Add armor',
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 22,
                  color: Skeuo.collapse(Colors.white70),
                ),
                onPressed: () {
                  final double curseToAdd = (count == 0) ? 0.5 : 1.0;
                  final double coolnessToAdd = (count < 2) ? 1.0 : 0.0;
                  p.setSpiceUsageCount(count + 1);
                  p.adjustCurse(curseToAdd);
                  if (coolnessToAdd != 0) {
                    p.adjustCoolness(coolnessToAdd);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: 6),
          GoopText(
            'CURRENT: $currentEffects',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w600,
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 4),
          GoopText(
            'NEXT: $nextEffects',
            style: TextStyle(
              fontSize: 11.5,
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.65),
              height: 1.3,
            ),
          ),
          SizedBox(height: 6),
          GoopText(
            'Note: Adjusting Spice count automatically syncs Curse to your active run (+0.5 for 1st use, +1.0 for each additional use).',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontStyle: FontStyle.italic,
              color: Skeuo.inkIf(
                Skeuo.inkIf(Colors.redAccent.shade100),
              ).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSprunInfo(BuildContext context) {
    final p = context.read<RunProvider>();
    final triggerIdx = context.select<RunProvider, int>(
      (p) => p.sprunTriggerIndex,
    );
    final windgunnerCountdown = context.select<RunProvider, int>(
      (p) => p.windgunnerCountdown,
    );
    final isWindgunnerActive = windgunnerCountdown > 0;

    final possibleTriggers = [
      'Activating a Map Blank',
      'Taking damage to Armor / Losing a half-heart',
      'Throwing an empty weapon at a wall',
      'Falling down an elevator shaft or trap pit',
      'Lighting yourself on fire or stepping into a poison pool',
    ];

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Skeuo.inkIf(Colors.cyan).withValues(alpha: 0.08),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(
          color: Skeuo.inkIf(Colors.cyanAccent).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radar_outlined,
                color: Skeuo.inkIf(Colors.cyanAccent.shade200),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: GoopText(
                  'SPRUN: ORB OBSERVATION DETECTOR',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Skeuo.inkIf(Colors.cyanAccent.shade200),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          if (triggerIdx == -1) ...[
            Container(
              padding: const EdgeInsets.all(Insets.md),
              decoration: BoxDecoration(
                color: Skeuo.collapse(Colors.black26),
                borderRadius: BorderRadius.all(Radii.sm),
                border: Border.all(
                  color: Skeuo.inkIf(Colors.cyanAccent).withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.blur_circular_outlined,
                    size: 36,
                    color: Skeuo.inkIf(Colors.cyanAccent),
                  ),
                  SizedBox(height: 8),
                  GoopText(
                    '🔮 ACTIVE SEED SYNERGY HIDDEN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Skeuo.collapse(Colors.white70),
                    ),
                  ),
                  SizedBox(height: 4),
                  GoopText(
                    'Each run pre-determines a randomized trigger to transform Sprun into the infinite-ammo Windgunner. Tap below to run active seed analysis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: FontSizes.labelSmall,
                      color: Skeuo.collapse(Colors.white54),
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Skeuo.inkIf(Colors.cyan.shade900),
                        foregroundColor: Skeuo.collapse(Colors.white),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radii.sm),
                        ),
                      ),
                      icon: const Icon(Icons.biotech_outlined, size: 16),
                      label: const GoopText(
                        'ANALYZE ACTIVE RUN SEED TRIGGER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      onPressed: () {
                        final randomIdx =
                            DateTime.now().millisecondsSinceEpoch %
                            possibleTriggers.length;
                        p.setSprunTriggerIndex(randomIdx);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            GoopText(
              'ACTIVE SEED ANALYSIS RESULTS:',
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w900,
                color: Skeuo.inkIf(Colors.cyanAccent),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Column(
              children: List.generate(possibleTriggers.length, (idx) {
                final isMatch = triggerIdx == idx;
                return Container(
                  margin: const EdgeInsets.only(bottom: 5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isMatch
                            ? Skeuo.inkIf(Colors.cyan).withValues(alpha: 0.18)
                            : Skeuo.collapse(Colors.black12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          isMatch
                              ? Skeuo.inkIf(
                                Skeuo.inkIf(Colors.cyanAccent),
                              ).withValues(alpha: 0.5)
                              : Skeuo.collapse(
                                Colors.white,
                              ).withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isMatch ? Icons.check_circle : Icons.circle_outlined,
                        size: 14,
                        color:
                            isMatch
                                ? Skeuo.inkIf(Colors.cyanAccent)
                                : Skeuo.collapse(Colors.white24),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: GoopText(
                          possibleTriggers[idx],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isMatch ? FontWeight.bold : FontWeight.normal,
                            color:
                                isMatch
                                    ? Skeuo.collapse(Colors.white)
                                    : Skeuo.collapse(Colors.white30),
                            decoration:
                                isMatch ? null : TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GoopText(
                  'Mystery seed decoded successfully.',
                  style: TextStyle(
                    fontSize: FontSizes.labelSmall,
                    color: Skeuo.inkIf(
                      Skeuo.inkIf(Colors.cyanAccent),
                    ).withValues(alpha: 0.5),
                  ),
                ),
                InkWell(
                  onTap: () => p.setSprunTriggerIndex(-1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: GoopText(
                      'RE-SET SEED',
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.bold,
                        color: Skeuo.inkIf(Colors.cyanAccent.shade100),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          Divider(color: Skeuo.collapse(Colors.white12), height: 16),
          Container(
            padding: const EdgeInsets.all(Insets.sm),
            decoration: BoxDecoration(
              color:
                  isWindgunnerActive
                      ? Skeuo.inkIf(Colors.cyan).withValues(alpha: 0.12)
                      : Skeuo.collapse(Colors.black12),
              borderRadius: BorderRadius.all(Radii.sm),
              border: Border.all(
                color:
                    isWindgunnerActive
                        ? Skeuo.inkIf(Colors.cyanAccent).withValues(alpha: 0.3)
                        : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        isWindgunnerActive
                            ? '⚡ WINDGUNNER MODE IS ACTIVE!'
                            : 'WINDGUNNER MODE OFF-LINE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color:
                              isWindgunnerActive
                                  ? Skeuo.inkIf(Colors.cyanAccent)
                                  : Skeuo.collapse(Colors.white54),
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 1.5),
                      GoopText(
                        isWindgunnerActive
                            ? 'Infinite Ammo, Flight, God-tier Burst! Count: ${windgunnerCountdown}s'
                            : 'Trigger criteria above to release power.',
                        style: TextStyle(
                          fontSize: FontSizes.labelSmall,
                          color:
                              isWindgunnerActive
                                  ? Skeuo.collapse(Colors.white70)
                                  : Skeuo.collapse(Colors.white38),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  activeThumbColor: Skeuo.inkIf(Colors.cyanAccent),
                  activeTrackColor: Skeuo.inkIf(Colors.cyan.shade900),
                  value: isWindgunnerActive,
                  onChanged: (val) {
                    if (val) {
                      p.startWindgunnerCountdown();
                    } else {
                      p.cancelWindgunnerCountdown();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaydayInfo(BuildContext context) {
    final p = context.watch<RunProvider>();
    final slot = ownerSlot ?? PlayerSlot.main;
    final player =
        slot == PlayerSlot.coop
            ? (p.runState.coop ?? Player())
            : p.runState.main;

    final hasMask = player.items.any(
      (i) => i.name.toLowerCase() == 'clown mask',
    );
    final hasDrill =
        player.guns.any((g) => g.name.toLowerCase() == 'drill') ||
        player.items.any((i) => i.name.toLowerCase() == 'drill');
    final hasBag = player.items.any((i) => i.name.toLowerCase() == 'loot bag');

    final int itemsCount =
        (hasMask ? 1 : 0) + (hasDrill ? 1 : 0) + (hasBag ? 1 : 0);

    /// Tap-to-toggle a heister: summons the companion by adding its
    /// backing Payday item to the player's inventory (or dismisses it
    /// by removing). Null callback when the item can't be resolved.
    VoidCallback? heisterToggle(String itemName, bool active) {
      final it = p.itemByName(itemName);
      if (it == null) return null;
      return () {
        Haptics.light();
        if (active) {
          p.removeItem(it, slot: slot);
        } else {
          p.addItem(it, slot: slot);
        }
      };
    }

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Skeuo.inkIf(Colors.blueAccent).withValues(alpha: 0.08),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(
          color: Skeuo.inkIf(Colors.blueAccent).withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups_outlined,
                color: Skeuo.inkIf(Colors.blueAccent.shade100),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      'THE PAYDAY CREW ASSEMBLY HUD',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Skeuo.inkIf(Colors.blueAccent),
                        letterSpacing: 0.8,
                      ),
                    ),
                    GoopText(
                      'Heister Count Exponential Matrix',
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        color: Skeuo.collapse(Colors.white38),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Skeuo.collapse(Colors.black45),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Skeuo.inkIf(
                      Skeuo.inkIf(Colors.blueAccent),
                    ).withValues(alpha: 0.3),
                  ),
                ),
                child: GoopText(
                  '$itemsCount/3 CO-OP',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'ArcadeClassic',
                    fontWeight: FontWeight.bold,
                    color: Skeuo.inkIf(Colors.blueAccent),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _buildHeisterSlot(
                name: 'Dallas',
                item: 'Clown Mask',
                active: hasMask,
                desc:
                    'Summoned • Periodically charges & stuns enemies with melee.',
                avatar: Icons.face_retouching_natural_outlined,
                onTap: heisterToggle('Clown Mask', hasMask),
              ),
              SizedBox(width: 8),
              _buildHeisterSlot(
                name: 'Wolf',
                item: 'Drill',
                active: hasDrill,
                desc:
                    'Summoned • Drops mini blanks to delete incoming projectile matrices.',
                avatar: Icons.build_outlined,
                onTap: heisterToggle('Drill', hasDrill),
              ),
              SizedBox(width: 8),
              _buildHeisterSlot(
                name: 'Chains',
                item: 'Loot Bag',
                active: hasBag,
                desc:
                    'Summoned • Automated shotgun scaling with floor difficulty tier.',
                avatar: Icons.monetization_on_outlined,
                onTap: heisterToggle('Loot Bag', hasBag),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Insets.sm),
            decoration: BoxDecoration(
              color: Skeuo.collapse(Colors.black38),
              borderRadius: BorderRadius.all(Radii.sm),
              border: Border.all(
                color: Skeuo.inkIf(Colors.blueAccent).withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  'SUMMON POWER PROFILE:',
                  style: TextStyle(
                    fontSize: FontSizes.labelSmall,
                    fontWeight: FontWeight.w900,
                    color: Skeuo.inkIf(Colors.blueAccent),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                if (itemsCount == 0)
                  GoopText(
                    'No heisters active. Hold Dallas (Clown Mask), Wolf (Drill), or Chains (Loot Bag) to activate.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Skeuo.collapse(Colors.white38),
                      height: 1.2,
                    ),
                  )
                else if (itemsCount == 1)
                  GoopText(
                    'Dallas Active: Melee charge stuns enemies.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Skeuo.collapse(Colors.white70),
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  )
                else if (itemsCount == 2)
                  GoopText(
                    'Dallas + Wolf Active: Added blank defense. Deletes projectiles.',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Skeuo.inkIf(Colors.cyanAccent),
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  )
                else
                  GoopText(
                    'Dallas + Wolf + Chains Active: FULL HEIST CREW ASSEMBLED! Automated shotgun scaling active. Infinite heister capabilities!',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Skeuo.inkIf(Colors.greenAccent),
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeisterSlot({
    required String name,
    required String item,
    required bool active,
    required String desc,
    required IconData avatar,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Tooltip(
        message:
            onTap != null
                ? (active
                    ? '$item — tap to dismiss'
                    : 'Tap to summon $item: $desc')
                : '$item: $desc',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(Insets.sm),
              height: 84,
              decoration: BoxDecoration(
                color:
                    active
                        ? Skeuo.inkIf(Colors.blueAccent).withValues(alpha: 0.18)
                        : Skeuo.collapse(Colors.black26),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      active
                          ? Skeuo.inkIf(Colors.blueAccent)
                          : Skeuo.collapse(
                            Colors.white,
                          ).withValues(alpha: 0.05),
                  width: active ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    avatar,
                    size: 24,
                    color:
                        active
                            ? Skeuo.inkIf(Colors.blueAccent.shade100)
                            : Skeuo.collapse(Colors.white24),
                  ),
                  SizedBox(height: 4),
                  GoopText(
                    name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: FontSizes.labelSmall,
                      fontWeight: FontWeight.w900,
                      color:
                          active
                              ? Skeuo.collapse(Colors.white)
                              : Skeuo.collapse(Colors.white24),
                    ),
                  ),
                  GoopText(
                    active ? 'SUMMONED' : 'LOCKED',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: FontSizes.labelSmall,
                      fontWeight: FontWeight.bold,
                      color:
                          active
                              ? Skeuo.inkIf(Colors.greenAccent)
                              : Skeuo.collapse(Colors.white24),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatinumBulletsInfo(BuildContext context) {
    final p = context.read<RunProvider>();
    final seconds = context.select<RunProvider, int>(
      (p) => p.platinumBulletsSeconds,
    );
    final dmgMult = seconds >= 750 ? 3.0 : 1.0 + (seconds / 750.0) * 2.0;
    final fireRateMult = seconds >= 375 ? 3.0 : 1.0 + (seconds / 375.0) * 2.0;

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Skeuo.inkIf(Colors.indigo).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Skeuo.inkIf(Colors.indigoAccent).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Skeuo.inkIf(Colors.indigoAccent.shade100),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: GoopText(
                  'Platinum Bullets — Firing Time',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Skeuo.inkIf(Colors.indigoAccent.shade100),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Decrease Platinum Bullets time',
                icon: Icon(
                  Icons.remove_circle_outline,
                  size: 22,
                  color: Skeuo.collapse(Colors.white70),
                ),
                onPressed:
                    seconds > 0
                        ? () => p.setPlatinumBulletsSeconds(
                          (seconds - 30).clamp(0, 999),
                        )
                        : null,
              ),
              GoopText(
                '${seconds}s',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Increase Platinum Bullets time',
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 22,
                  color: Skeuo.collapse(Colors.white70),
                ),
                onPressed:
                    () => p.setPlatinumBulletsSeconds(
                      (seconds + 30).clamp(0, 999),
                    ),
              ),
            ],
          ),
          SizedBox(height: 8),
          GoopText(
            '${dmgMult.toStringAsFixed(1)}x Damage  •  ${fireRateMult.toStringAsFixed(1)}x Fire Rate',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 4),
          GoopText(
            'Damage & fire rate scale with firing time. Damage maxes at 3x after 750s, fire rate at 3x after 375s. Starts partially powered on later floors.',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIronCoinInfo(BuildContext context) {
    final p = context.read<RunProvider>();
    final uses = context.select<RunProvider, int>((p) => p.ironCoinUses);

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Skeuo.inkIf(Colors.amber).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Skeuo.inkIf(Colors.amberAccent).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.monetization_on,
                color: Skeuo.inkIf(Colors.amberAccent.shade100),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: GoopText(
                  'Iron Coin — Charges',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Skeuo.inkIf(Colors.amberAccent.shade100),
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Decrease Iron Coin uses',
                icon: Icon(
                  Icons.remove_circle_outline,
                  size: 22,
                  color: Skeuo.collapse(Colors.white70),
                ),
                onPressed: uses > 0 ? () => p.setIronCoinUses(uses - 1) : null,
              ),
              GoopText(
                '$uses / 3',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Increase Iron Coin uses',
                icon: Icon(
                  Icons.add_circle_outline,
                  size: 22,
                  color: Skeuo.collapse(Colors.white70),
                ),
                onPressed: uses < 3 ? () => p.setIronCoinUses(uses + 1) : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              final spent = i >= uses;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  spent ? Icons.radio_button_unchecked : Icons.check_circle,
                  size: 18,
                  color:
                      spent
                          ? Skeuo.collapse(Colors.white24)
                          : Skeuo.inkIf(Colors.amberAccent),
                ),
              );
            }),
          ),
          SizedBox(height: 6),
          GoopText(
            'Kills all enemies in a random room on the current floor. 3 uses per run. Also grants a 10% discount at shops while held.',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKillThePastInfo(BuildContext context) {
    final p = context.watch<RunProvider>();
    final allItems = [...p.runState.main.items, ...?p.runState.coop?.items];
    final owned = allItems.map((i) => i.name.toLowerCase()).toSet();
    const ingredients = [
      'prime primer',
      'arcane gunpowder',
      'planar lead',
      'obsidian shell casing',
    ];
    final ownedCount = ingredients.where((n) => owned.contains(n)).length;

    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: Skeuo.inkIf(Colors.purple).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Skeuo.inkIf(Colors.purpleAccent).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.brightness_3,
                color: Skeuo.inkIf(Colors.purpleAccent.shade100),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: GoopText(
                  'Bullet to Kill the Past — $ownedCount/4',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.bold,
                    color: Skeuo.inkIf(Colors.purpleAccent.shade100),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children:
                ingredients.map((name) {
                  final has = owned.contains(name);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        has ? Icons.check_circle : Icons.circle_outlined,
                        size: 14,
                        color:
                            has
                                ? Skeuo.inkIf(Colors.purpleAccent)
                                : Skeuo.collapse(Colors.white24),
                      ),
                      SizedBox(width: 4),
                      GoopText(
                        name
                            .split(' ')
                            .map((w) => w[0].toUpperCase() + w.substring(1))
                            .join(' '),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: has ? FontWeight.bold : FontWeight.normal,
                          color:
                              has
                                  ? Skeuo.inkIf(Colors.purpleAccent)
                                  : Skeuo.collapse(Colors.white38),
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
          SizedBox(height: 6),
          GoopText(
            'Collect all 4 ingredients and take them to the Blacksmith to forge the Bullet that can Kill the Past.',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              color: Skeuo.collapse(Colors.white).withValues(alpha: 0.75),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
