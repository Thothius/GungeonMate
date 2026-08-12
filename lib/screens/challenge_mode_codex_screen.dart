import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/goop_talk_engine.dart';

/// Themed Codex page for Challenge Mode — Daisuke's gameplay modifier system.
/// Lists all 20 room modifiers and 4 boss-specific modifiers with mechanics,
/// exclusivity rules, and trivia. Opened from a dedicated tile in the Codex.
class ChallengeModeCodexScreen extends StatelessWidget {
  const ChallengeModeCodexScreen({super.key});

  // Challenge Mode's arcade/dice aesthetic — purple/amber neon on near-black.
  static const Color _dice = Color(0xFFAB47BC);
  static const Color _diceDim = Color(0xFF6A1B9A);
  static const Color _amber = Color(0xFFFFD54F);
  static const Color _void = Color(0xFF0A0A12);
  static const Color _panel = Color(0xFF14101E);

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
                    title: 'What is Challenge Mode?',
                    color: _dice,
                  ),
                  _InfoBlock(
                    body:
                        'Challenge Mode is a special gamemode activated by speaking to Daisuke in the Breach and spending 6 Hegemony Credits. Daisuke is found in the upper right corner of the Breach, in the same room as the Sorceress, after being rescued from a Cell in the Gungeon.',
                    accent: _dice,
                  ),
                  _InfoBlock(
                    heading: 'How It Works',
                    body:
                        'While active, each combat room in the Gungeon is affected by 1-3 randomly chosen gameplay modifiers. The number of modifiers per room increases the deeper you venture. When entering a new room, time briefly slows so you can read the modifiers before combat begins.',
                    accent: _dice,
                  ),
                  _InfoBlock(
                    heading: 'Double Challenge Mode',
                    body:
                        'Defeating the High Dragun with Challenge Mode enabled unlocks Double Challenge Mode — a harder version with twice the number of modifiers per room. Speak to Daisuke again after activating Challenge Mode and pay a second fee. No associated unlocks.',
                    accent: _dice,
                  ),
                  _InfoBlock(
                    heading: 'Cost Reduction',
                    body:
                        'After 30 failed attempts at Challenge Mode, Daisuke lowers the cost to 1 Hegemony Credit. This also unlocks Chaos Bullets if not already unlocked.',
                    accent: _dice,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.casino,
                    title: 'Room Modifiers',
                    color: _amber,
                  ),
                  _InfoBlock(
                    body:
                        'These modifiers can affect any combat room throughout the Gungeon. Every room will have at least one. Some modifiers are mutually exclusive and will never appear together.',
                    accent: _amber,
                  ),
                  // ── All 20 room modifiers ──
                  _ModifierCard(
                    name: 'Adrenaline Rush',
                    icon: Icons.speed,
                    color: _amber,
                    body:
                        'Increases game speed by 2.5% additively each time you dodge roll, up to 150% game speed. In boss rooms, only 1% per roll, maxing at 130%. Speed resets when the room is cleared.',
                  ),
                  _ModifierCard(
                    name: 'Blobulin Rancher',
                    icon: Icons.bug_report,
                    color: _dice,
                    body:
                        'Player projectiles destroyed on walls/obstacles spawn hostile Blobulins. Piercing projectiles that passed through an enemy first are exempt. If combined with Don\'t Blink, you can farm jammed Blobulins for money (risky without contact damage immunity).',
                    exclusiveWith: 'Ghost of the Shell',
                  ),
                  _ModifierCard(
                    name: 'Cursed Ceramics',
                    icon: Icons.local_drink,
                    color: _dice,
                    body:
                        'Spawns cursed pots randomly around the room. Standing near a pot builds your curse meter, increasing Curse by 1 and destroying the pot when fully filled. If combined with Pot Shots, the cursed pots fire bullets on destruction.',
                    exclusiveWith: 'Zone Control',
                  ),
                  _ModifierCard(
                    name: 'Dark Was The Night',
                    icon: Icons.nights_stay,
                    color: _dice,
                    body:
                        'Darkens the room and adds a cone of light to your vision. Certain enemies or objects have glowing parts that stand out in the darkness.',
                  ),
                  _ModifierCard(
                    name: 'Don\'t Blink',
                    icon: Icons.flashlight_on,
                    color: _dice,
                    body:
                        'Darkens the room with a flashlight cone. Enemies within the cone are stunned and unjammed; enemies outside the cone are jammed. Can unjam normally-always-jammed enemies like the giant Spent from Gummies.',
                  ),
                  _ModifierCard(
                    name: 'Explosive Pyre',
                    icon: Icons.whatshot,
                    color: _amber,
                    body:
                        'Enemies explode when killed. Bosses, Blobulins, Poisbulins, and Ammoconda\'s ball turrets are unaffected. Effectively nullifies Ghost of the Shell if both are active (explosions kill the spawned Hollowpoints immediately).',
                  ),
                  _ModifierCard(
                    name: 'Final Attack',
                    icon: Icons.local_fire_department,
                    color: _amber,
                    body:
                        'Enemies release bullets in all directions upon death. Enemies that already release bullets on death (like Shotgun Kin) don\'t add extra. Bosses are unaffected. Bullet patterns vary per enemy and may adopt their regular projectile effects.',
                  ),
                  _ModifierCard(
                    name: 'Ghost of the Shell',
                    icon: Icons.visibility_off,
                    color: _dice,
                    body:
                        'Slain enemies have a 50% chance to return as Hollowpoints. Does not affect Bosses, Hollowpoints, Blobulins, Bombshees, small Bullat variants, or enemies that already spawn another on death. Mine Flayer\'s Bells/Claymores only have 25% chance.',
                    exclusiveWith: 'Blobulin Rancher',
                  ),
                  _ModifierCard(
                    name: 'Gorgun\'s Gaze',
                    icon: Icons.remove_red_eye,
                    color: _dice,
                    body:
                        'The Gorgun\'s eyes periodically appear at random locations and send out a petrifying wave that prevents firing. Dodge roll through it or look away to avoid. If Shockwave is also active, they take turns triggering.',
                  ),
                  _ModifierCard(
                    name: 'Gull\'s Revenge',
                    icon: Icons.air,
                    color: _amber,
                    body:
                        'Causes rockets like those fired by the Gatling Gull to rain down periodically at random locations near the player. These can damage enemies.',
                  ),
                  _ModifierCard(
                    name: 'Gun Queue',
                    icon: Icons.swap_horiz,
                    color: _dice,
                    body:
                        'Prevents manual gun switching. Upon emptying a magazine, reloading, or waiting ~30 seconds, the next weapon auto-switches. Disables dual-wielding synergies for the room. Co-op bug: dying loses all guns except the starter.',
                  ),
                  _ModifierCard(
                    name: 'Hammer Time',
                    icon: Icons.build,
                    color: _amber,
                    body:
                        'Spawns a Dead Blow that persists for the rest of the room, attacking the player. Bug: using Escape Rope or Teleporter Prototype and re-entering still has the Dead Blow present alongside rerolled modifiers.',
                  ),
                  _ModifierCard(
                    name: 'High Stress',
                    icon: Icons.warning,
                    color: _amber,
                    body:
                        'Taking damage sets you to half a heart for 5 seconds — two quick hits are almost always fatal. The Robot doesn\'t have hearts, so all its armour briefly disappears instead. You may still count as full health for Blasphemy.',
                  ),
                  _ModifierCard(
                    name: 'Last Bullet Standing',
                    icon: Icons.shield,
                    color: _dice,
                    body:
                        'One random enemy is invulnerable until all others are slain, indicated by a marker above their head. Harmless entities, invulnerable enemies, and exploding enemies can\'t be chosen. Transmogrification can remove their protection.',
                    exclusiveWith: 'Long Live the King',
                  ),
                  _ModifierCard(
                    name: 'Long Live the King',
                    icon: Icons.emoji_events,
                    color: _amber,
                    body:
                        'One random enemy is marked as King. All others are invulnerable until the King is slain. If a Wall Mimic is designated King, the room can\'t be cleared until it\'s found and killed. Transmogrification and pits can bypass invulnerability.',
                    exclusiveWith: 'Last Bullet Standing',
                  ),
                  _ModifierCard(
                    name: 'Poison Pursuit',
                    icon: Icons.science,
                    color: _dice,
                    body:
                        'A trail of poison goop follows you for the duration of the room. This poison can afflict enemies. Bug: on the Resourceful Rat\'s second phase, it may force unavoidable damage during the boss intro.',
                  ),
                  _ModifierCard(
                    name: 'Pot Shots',
                    icon: Icons.grid_view,
                    color: _dice,
                    body:
                        'Minor breakable objects fire a bullet towards the player upon being destroyed. If combined with Cursed Ceramics, the cursed pots fire bullets on destruction.',
                  ),
                  _ModifierCard(
                    name: 'Rat\'s Revenge',
                    icon: Icons.local_fire_department_outlined,
                    color: _amber,
                    body:
                        'Places flame traps at random positions throughout the room, which periodically produce bursts of damaging flame on a consistent timer. Traps permanently disable once the room is cleared. Bug: some boss floor sprites layer over the traps, making them invisible.',
                  ),
                  _ModifierCard(
                    name: 'Shockwave',
                    icon: Icons.bolt,
                    color: _dice,
                    body:
                        'Periodically, rings of bullets linked with electricity appear and expand outwards. Touching bullets or electricity damages you. Electric immunity (Battery Bullets, Hazmat Suit) prevents link damage but not bullet damage. Cannot appear in rooms with less than 150 tiles.',
                  ),
                  _ModifierCard(
                    name: 'Thermal Clips',
                    icon: Icons.local_fire_department,
                    color: _amber,
                    body:
                        'Upon reloading an empty magazine, a pool of fire appears at your feet. Passive reloading (switching away and waiting) does not trigger this modifier.',
                  ),
                  _ModifierCard(
                    name: 'Unfriendly Fire',
                    icon: Icons.flip,
                    color: _dice,
                    body:
                        'Player bullets that hit walls ricochet and turn into hostile enemy bullets that can hit both player and enemies. Beam weapons are unaffected. In co-op, players can hit each other even before ricochet. Bullet modifiers still apply to ricocheted projectiles.',
                  ),
                  _ModifierCard(
                    name: 'Zone Control',
                    icon: Icons.place,
                    color: _dice,
                    body:
                        'Spawns supply crates in the room. You can only fire while standing within a marked zone around a crate. The zone fills as a progress meter — once full, all crates disappear and you can fire freely. Overlapping zones fill faster.',
                    exclusiveWith: 'Cursed Ceramics',
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.terrain,
                    title: 'Boss-Specific Modifiers',
                    color: _dice,
                  ),
                  _InfoBlock(
                    body:
                        'Bosses in the Hollow and Forge have special unique modifiers that modify their attack patterns. These are always the same for each boss, designed to make difficult fights more consistently fair rather than wildly variable.',
                    accent: _dice,
                  ),
                  _ModifierCard(
                    name: 'Something Wicked',
                    icon: Icons.fireplace,
                    color: _dice,
                    body:
                        'High Priest — Simple candle enemies appear randomly throughout the fight. They don\'t attack, but leave a pool of fire goop when slain. This fire doesn\'t dissipate until the High Priest is defeated. Jammed candles deal contact damage.',
                  ),
                  _ModifierCard(
                    name: 'Extremely Bad Chess',
                    icon: Icons.grid_on,
                    color: _dice,
                    body:
                        'Kill Pillars — Large rectangular patches of poison goop periodically appear in a checkerboard pattern on the floor throughout the fight.',
                  ),
                  _ModifierCard(
                    name: 'Night\'s Watch',
                    icon: Icons.gpp_good,
                    color: _dice,
                    body:
                        'Wallmonger — Two invincible Sniper Shells appear on top of the Wallmonger, periodically firing at the player throughout the fight. Despite being invulnerable, they can be transmogrified into Mutant Bullet Kin by a Big Boy explosion.',
                  ),
                  _ModifierCard(
                    name: 'Dragun Rage',
                    icon: Icons.local_fire_department,
                    color: _amber,
                    body:
                        'High Dragun — Makes all Dragun attacks much harder: bullets travel faster, fiery streams bounce off walls, more bouncing bullets in quicker succession, fires two rockets instead of one, fires nine homing skulls instead of five, and phase 2 safe zones are much smaller. Always accompanied by High Stress.',
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.card_giftcard,
                    title: 'Related Unlocks',
                    color: _amber,
                  ),
                  _InfoBlock(
                    heading: 'Chance Bullets',
                    body:
                        'Reach the Black Powder Mine with Challenge Mode enabled.',
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'Chaos Bullets',
                    body:
                        'Defeat the High Dragun with Challenge Mode enabled, or fail 30 attempts at Challenge Mode.',
                    accent: _amber,
                  ),
                  _InfoBlock(
                    heading: 'Double Challenge Mode',
                    body:
                        'Defeat the High Dragun with Challenge Mode enabled.',
                    accent: _amber,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.lightbulb,
                    title: 'Trivia',
                    color: _dice,
                  ),
                  _InfoBlock(
                    body:
                        'Blobulin Rancher references Slime Rancher. Cursed Ceramics references Curse Jars from Dark Souls II. Explosive Pyres references Destiny. Ghost of the Shell references the anime Ghost In The Shell. High Stress references Darkest Dungeon. Extremely Bad Chess references Really Bad Chess. Don\'t Blink references Doctor Who. Thermal Clips references Mass Effect. Night\'s Watch references Game of Thrones. Dark Was The Night references the song by Blind Willie Johnson. Hammer Time references MC Hammer. Something Wicked quotes Shakespeare\'s Macbeth. Dragun Rage may reference the Pokemon move Dragon Rage.',
                    accent: _dice,
                  ),
                  const SizedBox(height: 20),
                  _WikiLink(),
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
// Header — hero title with dice glow
// =============================================================================

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ChallengeModeCodexScreen._diceDim.withValues(alpha: 0.3),
            ChallengeModeCodexScreen._void,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Stack(
        children: [
          // Decorative dice icons
          Positioned(
            top: 30,
            right: 24,
            child: Icon(
              Icons.casino,
              size: 80,
              color: ChallengeModeCodexScreen._dice.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: Icon(
              Icons.casino,
              size: 50,
              color: ChallengeModeCodexScreen._amber.withValues(alpha: 0.08),
            ),
          ),
          // Title overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GoopText(
                  'SPECIAL MODE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: ChallengeModeCodexScreen._amber.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                GoopText(
                  'CHALLENGE MODE',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: ChallengeModeCodexScreen._dice,
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                GoopText(
                  '20 Room Modifiers + 4 Boss Modifiers',
                  style: TextStyle(
                    fontSize: 11,
                    color: ChallengeModeCodexScreen._dice.withValues(alpha: 0.7),
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
        color: ChallengeModeCodexScreen._panel,
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
// Modifier card — icon + name + body + optional exclusivity badge
// =============================================================================

class _ModifierCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String body;
  final String? exclusiveWith;

  const _ModifierCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.body,
    this.exclusiveWith,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: ChallengeModeCodexScreen._panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ChallengeModeCodexScreen._void,
              border: Border.all(color: color, width: 1.2),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6),
              ],
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GoopText(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (exclusiveWith != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4),
                            width: 0.6,
                          ),
                        ),
                        child: GoopText(
                          'vs $exclusiveWith',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                GoopText(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms, delay: 80.ms);
  }
}

// =============================================================================
// Wiki link — external reference
// =============================================================================

class _WikiLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: ChallengeModeCodexScreen._dice,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: const Icon(Icons.open_in_new, size: 14),
        label: GoopText(
          'View on wiki.gg',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ChallengeModeCodexScreen._dice,
          ),
        ),
        onPressed: () async {
          final url = Uri.parse(
              'https://enterthegungeon.wiki.gg/wiki/Challenge_Mode');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
      ),
    );
  }
}
