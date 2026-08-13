import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/goop_talk_engine.dart';
import '../utils/responsive.dart';

/// Themed Codex page for the Resourceful Rat — the omnipresent thief,
/// shortcut merchant, and secret boss of the Gungeon. Covers stealing
/// mechanics, the shortcut gun shop, the boss fight, Rat Keys, the four
/// Rat items, the Resourceful Indeed synergy, and the Rat's backstory.
class RatCodexScreen extends StatelessWidget {
  const RatCodexScreen({super.key});

  // The Rat's grimy kleptomaniac aesthetic — amber/rust on near-black brown.
  static const Color _rust = Color(0xFFD84315);
  static const Color _amber = Color(0xFFFFB300);
  static const Color _void = Color(0xFF120E08);
  static const Color _panel = Color(0xFF1E1810);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
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
                    color: _amber,
                  ),
                  _InfoBlock(
                    heading: 'The High King of the Gungeon',
                    body:
                        'The Resourceful Rat is an antagonist and occasional ally encountered throughout the Gungeon. He is a bipedal rat characterized by his kleptomania and tendency to annoy Gungeoneers, though it is implied he shares the same distaste for the Gungeon. He is known by many titles — R.R., High King of the Gungeon, The Handsomest King, High Lord Gungeon, and The Richest Rat. He is omnipresent: he appears in nearly every chamber to steal from the player, runs the shortcut elevator shop, and can be fought as a secret boss in his own lair.',
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'A Rat With No Regrets',
                    body:
                        'The Rat never sought the Gungeon for its treasures. Born in the hold of a trading vessel, he stole for his family\'s survival until a great tragedy befell his mischief. He escaped when the ship docked and wandered until finding the Gungeon. Stuck in its time loop, he made a nest and trained daily. He likely has the skill to reach the Gun That Can Kill The Past, but found his true calling: being an ass to Gungeoneers. In his eyes, he has no regrets — for he is King.',
                    accent: _amber,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.back_hand,
                    title: 'The Thief',
                    color: _rust,
                  ),
                  _InfoBlock(
                    heading: 'What He Steals',
                    body:
                        'The Rat steals armor, ammo, items, and guns left on the floor if the player leaves the room without picking them up. After stealing, he leaves a note thanking the player before calling them a random insult.\n\n'
                        'Safe from theft:\n'
                        '• Health (hearts)\n'
                        '• Blanks\n'
                        '• Keys\n'
                        '• Hegemony Credits\n'
                        '• Glass Guon Stones\n'
                        '• Master Rounds',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'The 2-Room Adjacency Trick',
                    body:
                        'If you leave a room with a stealable item and quickly return before it\'s taken, the Rat appears but vanishes upon noticing you — leaving the item behind. He won\'t try again unless you\'re at least 2 rooms away. Rooms connected by corridors count as adjacent regardless of corridor length.\n\n'
                        'Practical use: clear surrounding rooms before picking up ammo drops, so you can refill the gun with the fewest remaining rounds.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'Shooting the Rat',
                    body:
                        'You can shoot the Rat while he\'s stealing. He\'ll call you a "Jerk!" and teleport away. This is not required to dissuade him — he\'ll flee on his own if you re-enter quickly. Shooting him is purely cathartic.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'Items That Stop Theft',
                    body:
                        'Three ways to permanently end the Rat\'s thievery:\n'
                        '• Kill him in Phase 3 of his boss fight — he never steals from you again for the rest of the run.\n'
                        '• Hold the Resourceful Indeed synergy (all 4 Rat items) — you become the Rat, so he won\'t steal from himself.\n'
                        '• The Ring of the Resourceful Rat doesn\'t stop theft, but turns it into a trade: once per floor, when he steals a gun or item, he drops another of the same type and quality. Unused trades carry over to the next floor.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'The Bullet That Can Kill The Past',
                    body:
                        'The Rat WILL steal the Bullet That Can Kill The Past if left on the floor. However, if you have the Ring of the Resourceful Rat with trades remaining, he drops an S-tier passive item after stealing it — a silver lining to a devastating loss.',
                    accent: _rust,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.elevator,
                    title: 'Shortcut Merchant',
                    color: _amber,
                  ),
                  _InfoBlock(
                    heading: 'The Bello Mask',
                    body:
                        'If you take a shortcut to the second chamber or beyond, the Rat appears in the elevator room wearing a mask resembling Bello the shopkeeper. He offers a selection of three free guns. The selection doesn\'t change until you complete a floor after taking an elevator.',
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'Gun Quality by Chamber',
                    body:
                        'The quality and quantity of free guns scales with how deep you start:\n'
                        '• Chamber 2 (Gungeon Proper): D-quality, 1 gun\n'
                        '• Chamber 3 (Black Powder Mine): C-quality, 1 gun\n'
                        '• Chamber 4 (Hollow): B-quality, 2 guns\n'
                        '• Chamber 5 (Forge): B-quality, 3 guns',
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'Stealing From the Rat',
                    body:
                        'You can steal from the Rat despite his offerings being free. Stealing gives 1 Curse, contributes to unlocking the Shelleton Key (10 total steals), and prevents you from taking any more of the free guns on offer. The Rat can offer Blasphemy even to The Bullet — picking it up won\'t duplicate it.',
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'Refreshing the Selection',
                    body:
                        'Starting a run from a shortcutted chamber and defeating a boss changes the selection for ALL shortcutted chambers. Starting fresh from the Keep of the Lead Lord and defeating a boss in Gungeon Proper does NOT change the Rat\'s selection. Unlocking new guns may also force a selection change on subsequent visits.',
                    accent: _amber,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.pest_control,
                    title: 'The Boss Fight',
                    color: _rust,
                  ),
                  _InfoBlock(
                    heading: 'The Lair',
                    body:
                        'The Resourceful Rat\'s Lair (shown as ??? on the map) is a secret chamber accessed through a hidden trapdoor in the Black Powder Mine. Entry costs: 1 Key, 2 Blanks, and the Gnawed Key. The trapdoor only appears after the Bullet That Can Kill The Past has been constructed. The lair has no shops, no chests, and no shrines — just a giant maze.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'The Maze',
                    body:
                        'The maze consists of combat rooms with exits in all four cardinal directions. You must take the correct exit six times in a row to reach the boss. The route is clued by the six Infuriating Notes in the Ammonomicon — each ends with a piece of cheese pointing in a direction. The route is fixed per installation and can be memorized. Wrong turns lead to an elevator out.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'Phase 1 — The Rat Himself',
                    body:
                        'The Rat fights from atop a throne of stolen items. He attacks with mousetraps, cheese spirals, cheese wheels, kunai, and a bullet whip. Health: 1480. After defeat, he retreats down a hole — the player follows.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'Phase 2 — The Mech',
                    body:
                        'The Rat pilots a stationary mech built from all the items and guns he has stolen. The mech has two destroyable weapon systems (drum clip and tailgun) that can be removed to eliminate specific attacks. Attacks include laser sweeps, magic circles, missiles, mouser spawns, jump slams, and more. Health: 3515.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'Phase 3 — Punch-Out!!',
                    body:
                        'The final phase is a Punch-Out!! style boxing match. The Rat has three health bars of increasing difficulty. Punch him during openings (after dodges or parries) to deal damage. Parry his attacks by punching during yellow-flash windows to earn stars. Stars power super punches, which deal heavy damage and yield better rewards.\n\n'
                        'The Rat can taunt (free star), punch, uppercut, combo, lunge, tail-whip, heal (parry the cheese!), use brass knuckles, pirouette, and toss ammo boxes. In co-op, the Cultist is tied up and cannot participate.',
                    accent: _rust,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.key,
                    title: 'Rewards & Rat Keys',
                    color: _amber,
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
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'Rat Keys — Six Keys, Seven Locks',
                    body:
                        'Up to six Rat Keys can be earned during the Punch-Out:\n'
                        '• 1 for punching the Rat for the first time\n'
                        '• 1 per phase finished with a super punch (up to 3)\n'
                        '• 1 for winning all three phases\n'
                        '• 1 bonus key if all three phases ended with a 3-star super punch\n\n'
                        'There are seven locks total (4 Rat Chests + 2 Serpent Room doors + 1 Forge elevator), so even perfect play requires Trusty Lockpicks or the Drill to open everything.',
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'The Reward Room',
                    body:
                        'After defeating the Rat, a hole opens in the boss room floor. The reward room contains eight golden pedestals: 2 Keys, a Glass Guon Stone, a Blank, a full heart, Armor, an Ammo box, and a Spread Ammo box. Four raised daises each hold a Rat Chest — the only Rat Chests in the game.',
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'Rat Chest Contents',
                    body:
                        'Rat Chests always contain one of four special Rat items in random order:\n'
                        '• Elimentaler — leaves poison goop on dodge rolls\n'
                        '• Partially-Eaten Cheese — heals on dodge roll\n'
                        '• Resourceful Sack — collects bullets, fires explosive cheese\n'
                        '• Rat Boots — immune to goop damage\n\n'
                        'If you already own the item, the chest drops a random A-quality item/gun instead. Rat Chests can be Mimics! They cannot be opened by Shelleton Key or AKEY-47, but Trusty Lockpicks (50% break chance) and Drill work.',
                    accent: _amber,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.inventory_2,
                    title: 'The Four Rat Items',
                    color: _rust,
                  ),
                  _InfoBlock(
                    heading: 'Elimentaler',
                    body:
                        'A passive item that leaves a puddle of poison goop whenever you dodge roll. The goop damages enemies that walk through it. Part of the Resourceful Indeed synergy set. Unlocked by reaching the Resourceful Rat\'s Lair.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'Partially-Eaten Cheese',
                    body:
                        'A passive item that heals half a heart whenever you dodge roll. This makes dodge rolling both offensive and restorative. Part of the Resourceful Indeed synergy set. Found only in Rat Chests.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'Resourceful Sack',
                    body:
                        'A passive item that collects bullets that hit you, storing them in the sack. When full, dodge rolling fires all stored bullets as explosive cheese. Effectively turns enemy fire into ammunition. Part of the Resourceful Indeed synergy set.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'Rat Boots',
                    body:
                        'A passive item that makes you immune to all goop damage (fire, poison, ice, oil). You still slide on goop but take no damage. Part of the Resourceful Indeed synergy set.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'Resourceful Indeed Synergy',
                    body:
                        'Holding all four Rat items simultaneously grants the "Resourceful Indeed" synergy, which transforms you into the Resourceful Rat. While transformed:\n'
                        '• The Rat will never steal from you again\n'
                        '• You gain the Rat\'s appearance\n'
                        '• Dodge rolls leave poison goop AND heal you\n'
                        '• Collected bullets fire as explosive cheese\n'
                        '• You are immune to all goop damage\n\n'
                        'This is one of the most powerful synergies in the game, combining offense, defense, and healing into one package.',
                    accent: _rust,
                  ),
                  _InfoBlock(
                    heading: 'Ring of the Resourceful Rat',
                    body:
                        'Unlocked by defeating the Rat\'s first two phases. Once per floor, when the Rat steals a gun or item, he drops another of the same type and quality. Unused trades carry over to the next floor. If he steals the Bullet That Can Kill The Past with trades remaining, he drops an S-tier passive item.',
                    accent: _rust,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.lightbulb,
                    title: 'Notes & Trivia',
                    color: _amber,
                  ),
                  _InfoBlock(
                    heading: 'Shortcut Necessity',
                    body:
                        'Shortcuts are essential for progressing through the game without starting from Chamber 1 every time. The Rat\'s free gun offerings help offset the loss of early-floor loot accumulation, making shortcut runs viable for practicing past fights or farming specific chamber unlocks.',
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'The Rat in Exit the Gungeon',
                    body:
                        'In Exit the Gungeon, the Rat doesn\'t steal items (since you can\'t drop them). He appears in the side area of the Shop, offering a Rat Key — used to free Daisuke from his cell.',
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'Unused Store Tab',
                    body:
                        'An unused "store" tab exists for the Resourceful Rat in the assets of the International Mobile Version of ETG. This is unique — the Rat is the only character given a store tab who is not a Gungeoneer.',
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'Key Art Appearances',
                    body:
                        'The Rat appears in key art for both the Advanced Gungeons & Draguns and A Farewell to Arms updates. A carved figurehead of the Rat appears above a doorway in AG&D key art, wearing a headdress of Bullet Kin. He also stars in the animated release trailer for AG&D and appears on the 2022 special edition vinyl soundtrack sleeve.',
                    accent: _amber,
                  ),
                  const SizedBox(height: 16),
                  const _WikiLink(),
                ],
              ),
            ),
          ),
        ],
    );
  }
}

// =============================================================================
// Header — rat thief aesthetic with hero image
// =============================================================================

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          child: Image.asset(
            'assets/images/codex/Rat_header.png',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: RatCodexScreen._void,
              child: Center(
                child: Icon(Icons.pest_control,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    RatCodexScreen._void.withValues(alpha: 0.4),
                    RatCodexScreen._void.withValues(alpha: 0.95),
                  ],
                ),
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
                'OMNIPRESENT THIEF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: RatCodexScreen._amber.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
              GoopText(
                'THE RESOURCEFUL RAT',
                style: TextStyle(
                  fontSize: 28 * sf,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: RatCodexScreen._rust,
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
        color: RatCodexScreen._panel,
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
          foregroundColor: RatCodexScreen._amber,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: const Icon(Icons.open_in_new, size: 14),
        label: GoopText(
          'View on wiki.gg',
          style: TextStyle(
            fontSize: 12,
            color: RatCodexScreen._amber.withValues(alpha: 0.9),
          ),
        ),
        onPressed: () async {
          final uri = Uri.parse(
              'https://enterthegungeon.wiki.gg/wiki/Resourceful_Rat');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
    );
  }
}
