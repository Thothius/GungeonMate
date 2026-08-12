import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/goop_talk_engine.dart';

/// Themed Codex page for The Drake (Serpent / Baby Dragun) — the secret
/// companion that unlocks the Advanced Dragun fight. Presents the Weird
/// Egg mechanic, the Resourceful Rat boss fight rewards, the feeding
/// process, the Advanced Dragun trigger, and trivia in a serpentine
/// emerald/gold themed layout.
class DrakeCodexScreen extends StatelessWidget {
  const DrakeCodexScreen({super.key});

  // Serpent's ancient dragon aesthetic — emerald/gold on near-black.
  static const Color _emerald = Color(0xFF00E676);
  static const Color _gold = Color(0xFFFFD54F);
  static const Color _void = Color(0xFF04140A);
  static const Color _panel = Color(0xFF0E2014);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _Header()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    icon: Icons.auto_stories,
                    title: 'Lore & Identity',
                    color: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'The Baby Dragun',
                    body:
                        'The Serpent — internally called "Baby Dragun" — is a secret NPC and companion. It is an ancient, serpentine creature that orbits the player once tamed. Despite its diminutive appearance, it is the key to unlocking the Advanced Dragun, the most powerful boss phase in the Gungeon. The Serpent has no Ammonomicon entry and does not appear in the player\'s inventory on the map screen — it is a truly hidden mechanic.',
                    accent: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'A Creature of Fire',
                    body:
                        'The Serpent is born from fire — either hatched from a Weird Egg dropped into burning goop, or found sleeping behind locked doors in the Resourceful Rat\'s Lair. It must be fed four items or guns before it will follow the player. Once awakened, it snakes around the player in a wave pattern, blocking enemy projectiles like a Guon Stone.',
                    accent: _emerald,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.egg,
                    title: 'The Weird Egg',
                    color: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Miracle of Gun',
                    body:
                        'The Weird Egg is a D-quality, single-use active item unlocked by entering the Resourceful Rat\'s Lair for the first time. It can be purchased from Professor Goopton\'s shop. The egg has three distinct uses, each leading to very different outcomes.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Use 1 — Full Heal',
                    body:
                        'Using the egg while the player has empty hearts restores them to full health. This is the simplest use, but wastes the egg\'s potential for rarer rewards.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Use 2 — Breaking for Loot',
                    body:
                        'Dropping the egg and shooting it breaks it open. If carried through enough floors, it yields a gun or item:\n'
                        '• 2 floors: hops slightly → C or B quality\n'
                        '• 4 floors: bounces → A or S quality\n'
                        'If not carried far enough, it spawns a harmless yolk creature instead. The yolk creature can be Jammed, in which case it deals contact damage.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Use 3 — Hatching the Serpent',
                    body:
                        'Dropping the egg into any source of fire goop causes it to crack after a few moments, revealing a Serpent within. There is a long delay before hatching — if enemies are active in the room, they may destroy the egg before it hatches. The hatched Serpent must still be fed four items before it joins the player, just like the one in the Rat\'s Lair.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Egg Trivia',
                    body:
                        'The Weird Egg is based on the spotted eggs from Pokémon, including the distance-to-hatch mechanic. Its name references several egg-related glitches from the series (Bad Egg, Odd Egg, Glitch Egg). The synergy "Phoenix Up" (with Phoenix) summons a phoenix companion. "Two Eggs Over Easy" (with The Scrambler) makes seeking sub-projectiles poison enemies.',
                    accent: _gold,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.pest_control,
                    title: 'The Resourceful Rat Boss',
                    color: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'The Lair',
                    body:
                        'The Resourceful Rat\'s Lair (shown as ??? on the map) is a secret chamber accessed through a hidden trapdoor in the Black Powder Mine. It requires 1 Key, 2 Blanks, and the Gnawed Key to enter. The trapdoor only appears after the Bullet That Can Kill The Past has been constructed. The lair has no shops, no chests, and no shrines — just a giant maze.',
                    accent: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'The Maze',
                    body:
                        'The maze consists of combat rooms with exits in all four cardinal directions. The player must take the correct exit six times in a row to reach the boss. The route is cluesd by the six Infuriating Notes in the Ammonomicon — each ends with a piece of cheese pointing in a direction. The route is fixed per installation and can be memorized. Wrong turns lead to an elevator out.',
                    accent: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'Phase 1 — The Rat Himself',
                    body:
                        'The Rat fights from atop a throne of stolen items. He attacks with mousetraps, cheese spirals, cheese wheels, kunai, and a bullet whip. Health: 1480. After defeat, he retreats down a hole — the player follows.',
                    accent: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'Phase 2 — The Mech',
                    body:
                        'The Rat pilots a stationary mech built from all the items and guns he has stolen. The mech has two destroyable weapon systems (drum clip and tailgun) that can be removed to eliminate specific attacks. Attacks include laser sweeps, magic circles, missiles, mouser spawns, jump slams, and more. Health: 3515.',
                    accent: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'Phase 3 — Punch-Out!!',
                    body:
                        'The final phase is a Punch-Out!! style boxing match. The Rat has three health bars of increasing difficulty. Punch him during openings (after dodges or parries) to deal damage. Parry his attacks by punching during yellow-flash windows to earn stars. Stars power super punches, which deal heavy damage and yield better rewards. The Rat can taunt (free star), punch, uppercut, combo, lunge, tail-whip, heal (parry the cheese!), use brass knuckles, pirouette, and toss ammo boxes. In co-op, the Cultist is tied up and cannot participate.',
                    accent: _emerald,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.inventory_2,
                    title: 'Rewards & Rat Keys',
                    color: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Punch-Out Drops',
                    body:
                        'Items and guns are beaten out of the Rat during the Punch-Out phase:\n'
                        '• C-quality item/gun at end of sub-phase 1\n'
                        '• B-quality item/gun at end of sub-phase 2\n'
                        '• A or S-quality item/gun at end of all three phases\n'
                        '• Common/D/C item after 5–8 punches at the start\n'
                        '• A-quality item/gun on first super punch\n'
                        '• 15% chance per punch to drop a Half Heart, Heart, Armor, or Glass Guon Stone (max 3 Guon Stones)',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Rat Keys — Six Keys, Seven Locks',
                    body:
                        'Up to six Rat Keys can be earned during the Punch-Out:\n'
                        '• 1 for punching the Rat for the first time\n'
                        '• 1 per phase finished with a super punch (up to 3)\n'
                        '• 1 for winning all three phases\n'
                        '• 1 bonus key if all three phases ended with a 3-star super punch\n'
                        'There are seven locks total (4 Rat Chests + 2 Serpent Room doors + 1 Forge elevator), so even perfect play requires Trusty Lockpicks or the Drill to open everything.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Reward Room',
                    body:
                        'After defeating the Rat, a hole opens in the boss room floor. The reward room contains eight golden pedestals: 2 Keys, a Glass Guon Stone, a Blank, a full heart, Armor, an Ammo box, and a Spread Ammo box. Four raised daises each hold a Rat Chest — the only Rat Chests in the game.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Rat Chest Contents',
                    body:
                        'Rat Chests always contain one of four special Rat items in random order:\n'
                        '• Elimentaler — leaves poison goop on dodge rolls\n'
                        '• Partially-Eaten Cheese — heals on dodge roll\n'
                        '• Resourceful Sack — collects bullets, fires explosive cheese\n'
                        '• Rat Boots — immune to goop damage\n'
                        'If you already own the item, the chest drops a random A-quality item/gun instead. Rat Chests can be Mimics! They cannot be opened by Shelleton Key or AKEY-47, but Trusty Lockpicks (50% break chance) and Drill work.',
                    accent: _gold,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.pets,
                    title: 'Acquiring the Serpent',
                    color: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'Method 1 — The Rat\'s Lair (Guaranteed)',
                    body:
                        'A secret room off the reward room contains the Serpent behind two locked doors requiring Rat Keys. Drop four items or guns near the Serpent to feed it. The Rat\'s corpse (if you defeated Phase 3) counts as one feeding item.\n\n'
                        'Pro tip: Passive items can be thrown through the second locked door, so you only need one Rat Key to feed the Serpent — unlock the first door, toss items through the gap.',
                    accent: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'Method 2 — The Weird Egg (RNG)',
                    body:
                        'Drop the Weird Egg into burning goop. After a delay, it hatches into a Serpent. This avoids the massive investment of the Rat\'s Lair (150 casings, 1 Key, 3 Blanks, and ammo) but requires finding the egg, which is RNG-dependent. The hatched Serpent must still be fed four items.',
                    accent: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'Feeding Tips',
                    body:
                        'The Serpent can be fed otherwise valueless items like Glass Guon Stones. It can also devour the Resourceful Rat\'s dead body from Phase 3 — this counts as one item. If you have both the Weird Egg and visit the Rat\'s Lair in the same run, you can acquire multiple Serpents. Clone also allows multiple Serpents.',
                    accent: _emerald,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.local_fire_department,
                    title: 'The Advanced Dragun',
                    color: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Betrayal',
                    body:
                        'Once the Serpent joins the player, it orbits them as a companion, blocking projectiles like a Guon Stone. But during the High Dragun boss fight, the Serpent betrays the player — it leaves their side and flies beside the Dragun, periodically spitting spreads of seven bullets at the player. This makes even the normal Dragun phases considerably harder.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Transformation',
                    body:
                        'After the first attack cycle of the High Dragun\'s second phase, if the Serpent is present, the Dragun crushes it and absorbs its power. This restores the Dragun\'s health and begins the Advanced Dragun phase — a secret third boss phase with 5200 HP and a massive arsenal of attacks.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Advanced Dragun Attacks',
                    body:
                        'The Advanced Dragun uses devastating attacks: fire bullet streams, dual pistols, grenade launchers, uzis with stationary bullet arcs, fireball zones that block shooting, a tracking eye that dims the room, five skulls that fire bullets, rockets with wave-pattern bullet rings, wall knives that fire kunai, and a screen-filling bullet hell pattern with safe zones.\n\n'
                        'Tip: Any blank effect (blank, armor shattering, Dark Marker) clears the first half of the screen-filling bullet pattern.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Advanced Dragun Notes',
                    body:
                        'Defeating the Advanced Dragun unlocks the "Advanced Slayer" achievement. Its head explodes instead of dropping a skull, making the Obsidian Shell Casing impossible to obtain on that run. The Advanced Dragun can be Jammed independently of the Dragun. Killing it counts for Dragun kill unlocks but NOT for Frifle and the Grey Mauser\'s final hunt. After defeating it, the Hero of Time statue in The Breach transforms.',
                    accent: _gold,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.lightbulb,
                    title: 'Notes & Trivia',
                    color: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'The Baby Hat',
                    body:
                        'In Exit the Gungeon, "The Baby" hat is based on the Serpent. This confirms the Serpent\'s identity as a baby version of the Dragun.',
                    accent: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'Multiple Serpents',
                    body:
                        'If you acquire multiple Serpents (via Weird Egg + Rat\'s Lair, or Clone), only one joins the High Dragun during the boss fight. The others disappear, reappearing when you enter a new chamber. Bringing two Serpents into the fight results in one vanishing for the rest of the floor, but it returns in Bullet Hell.',
                    accent: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'Bloodied Scarf Trick',
                    body:
                        'The Bloodied Scarf can teleport past the secret wall obscuring the Serpent Room, and even past the Rat locks — avoiding the need for keys entirely. However, if you feed the Bloodied Scarf to the Serpent after teleporting in, you cannot teleport back out, softlocking the run.',
                    accent: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'Resourceful Indeed',
                    body:
                        'Holding all four special Rat items (Elimentaler, Partially-Eaten Cheese, Resourceful Sack, and Rat Boots) grants the "Resourceful Indeed" synergy, which transforms the player into the Resourceful Rat. With this synergy, the Rat will never steal from you again.',
                    accent: _emerald,
                  ),
                  _InfoBlock(
                    heading: 'The Rat\'s Story',
                    body:
                        'The Resourceful Rat never sought the Gungeon for its treasures. Born in the hold of a trading vessel, he stole for his family\'s survival until a great tragedy befell his mischief. He escaped when the ship docked and wandered until finding the Gungeon. Stuck in its time loop, he made a nest and trained daily. He likely has the skill to reach the Gun, but found his true calling: being an ass to Gungeoneers. In his eyes, he has no regrets — for he is King.',
                    accent: _emerald,
                  ),
                  const SizedBox(height: 16),
                  const _WikiLink(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Header — serpentine emerald gradient with title
// =============================================================================

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return SizedBox(
      height: screenHeight * 0.22,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    DrakeCodexScreen._void,
                    DrakeCodexScreen._panel,
                    Colors.transparent,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GoopText(
                  'SECRET COMPANION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: DrakeCodexScreen._gold.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                GoopText(
                  'THE DRAKE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: DrakeCodexScreen._emerald,
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// =============================================================================
// Section title — icon + label with accent underline
// =============================================================================

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              GoopText(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Info block — optional heading + body text in a dark panel
// =============================================================================

class _InfoBlock extends StatelessWidget {
  final String? heading;
  final String body;
  final Color accent;

  const _InfoBlock({
    this.heading,
    required this.body,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: DrakeCodexScreen._panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null) ...[
            GoopText(
              heading!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: accent.withValues(alpha: 0.95),
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
          ],
          GoopText(
            body,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms, delay: 60.ms);
  }
}

// =============================================================================
// Wiki link — external reference
// =============================================================================

class _WikiLink extends StatelessWidget {
  const _WikiLink();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: DrakeCodexScreen._emerald,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: const Icon(Icons.open_in_new, size: 14),
        label: GoopText(
          'View on wiki.gg',
          style: TextStyle(
            fontSize: 12,
            color: DrakeCodexScreen._emerald.withValues(alpha: 0.9),
          ),
        ),
        onPressed: () async {
          final uri = Uri.parse(
              'https://enterthegungeon.wiki.gg/wiki/Serpent');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
    );
  }
}
