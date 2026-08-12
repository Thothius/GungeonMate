import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/goop_talk_engine.dart';

/// Themed Codex page for The Paradox — the cosmic glitch Gungeoneer.
/// Presents lore, the rift unlock mechanic, random starter loadout,
/// gameplay notes, and trivia in a cosmic cyan/violet themed layout.
class ParadoxCodexScreen extends StatelessWidget {
  const ParadoxCodexScreen({super.key});

  // Paradox's cosmic/glitch aesthetic — cyan/violet neon on near-black.
  static const Color _rift = Color(0xFF00E5FF);
  static const Color _cosmic = Color(0xFFB388FF);
  static const Color _void = Color(0xFF0A0A12);
  static const Color _panel = Color(0xFF12101E);

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
                    color: _rift,
                  ),
                  _InfoBlock(
                    heading: 'The Anomaly',
                    body:
                        'The Paradox isn\'t a true Gungeoneer, but rather a cosmic glitch — a shifting tear in reality caused by the repeated killing of the past. It represents the timeline collapsing in on itself, a physical manifestation of the temporal paradoxes which would invariably result from carelessly wounding the timestream.',
                    accent: _rift,
                  ),
                  _InfoBlock(
                    heading: 'Visual Identity',
                    body:
                        'Visually, The Paradox is a swirling, static-filled silhouette that rapidly shifts shapes between the original four Gungeoneers. Every dodge-roll, table flip, or barrel roll changes its appearance to a random Gungeoneer and outfit.',
                    accent: _rift,
                  ),
                  _InfoBlock(
                    heading: 'Quote',
                    body:
                        '"Your constant killing of the past has created a time rift, things are getting wacky!" — Dodge Roll',
                    accent: _cosmic,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.casino,
                    title: 'Mechanical Loadout',
                    color: _rift,
                  ),
                  _InfoBlock(
                    heading: 'The Ultimate Test of Adaptability',
                    body:
                        'The Paradox is the ultimate test of adaptability. Every run is a completely random roll of the dice. Costs 5 Hegemony Credits per run.',
                    accent: _rift,
                  ),
                  _InfoBlock(
                    heading: 'Starter Weapon',
                    body:
                        'One random starter weapon from any unlocked character (e.g. Marine Sidearm, Robot\'s Right Hand, Blasphemy). The Paradox can even start with a weapon from a Gungeoneer that hasn\'t been unlocked yet.',
                    accent: _rift,
                  ),
                  _InfoBlock(
                    heading: 'Secondary Weapon',
                    body:
                        'One completely random gun from the player\'s unlocked loot pool. This can be anything from a D-tier peashooter to an S-tier powerhouse.',
                    accent: _rift,
                  ),
                  _InfoBlock(
                    heading: 'Passive Item',
                    body:
                        'One completely random passive item from the loot pool. The items are chosen when you select the character — you can check what guns you have in the Breach, but the item won\'t appear until the run starts.',
                    accent: _rift,
                  ),
                  _InfoBlock(
                    heading: 'No Past',
                    body:
                        'The Paradox has no past to kill. Reaching the Gun That Can Kill The Past immediately forces the player into Chamber 6 (Bullet Hell) to face the Lich. The Blacksmith will speak with them but will not give them the Bullet That Can Kill The Past. If Bullet Hell has been unlocked, the Lich\'s hand will always drag the player down — the Paradox cannot reach the Gun until the Gunslinger is unlocked.',
                    accent: _rift,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.info_outline,
                    title: 'Notes & Mechanics',
                    color: _cosmic,
                  ),
                  _InfoBlock(
                    heading: 'Appearance Shifting',
                    body:
                        'The Paradox\'s appearance changes to a random Gungeoneer and outfit every time they dodge-roll, flip a table, or roll a barrel. Sliding over a table does not trigger a change. If the Paradox picks up an item that changes appearance (e.g. Clown Mask), that appearance is added to the pool.',
                    accent: _cosmic,
                  ),
                  _InfoBlock(
                    heading: 'Co-op',
                    body:
                        'Playing in co-op causes The Cultist to have a randomized loadout different from the Paradox. On quick restart, both players get identical loadouts.',
                    accent: _cosmic,
                  ),
                  _InfoBlock(
                    heading: 'Lich Kill Caveat',
                    body:
                        'Killing the Lich as the Paradox without having unlocked the Gunslinger does not count as an actual Lich kill — it will not add the Lich\'s entry to the Ammonomicon nor unlock his respective unlockables.',
                    accent: _cosmic,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.code,
                    title: 'Trivia',
                    color: _rift,
                  ),
                  _InfoBlock(
                    heading: 'Eevee',
                    body:
                        'Many internal parts of Enter the Gungeon refer to the Paradox by the name "Eevee". The Paradox was present in an unfinished form since the Advanced Gungeons & Draguns Update, but could only be accessed via modding.',
                    accent: _rift,
                  ),
                  _InfoBlock(
                    heading: 'Cut Content',
                    body:
                        'The Paradox was originally planned to visit a random past upon using the Gun with the Bullet. This was removed on release — the Paradox is simply incapable of obtaining the bullet. Early iterations lacked the galaxy shader and would show "STRING_NOT_FOUND" for NPC nicknames.',
                    accent: _rift,
                  ),
                  _InfoBlock(
                    heading: 'Nicknames',
                    body:
                        'Whatever you are, Time blob, Glitch, Temporal horror, Purple ghost.',
                    accent: _rift,
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
// Header — hero image + title with cosmic glow
// =============================================================================

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          child: Image.asset(
            'assets/images/gungeoneers/animated/Paradox_Card_Animated.gif',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: ParadoxCodexScreen._void,
              child: Center(
                child: Icon(Icons.auto_awesome,
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
                    ParadoxCodexScreen._void.withValues(alpha: 0.4),
                    ParadoxCodexScreen._void.withValues(alpha: 0.95),
                  ],
                  stops: const [0.3, 0.7, 1.0],
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
                'GUNGEONEER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: ParadoxCodexScreen._cosmic.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
              GoopText(
                'THE PARADOX',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: ParadoxCodexScreen._rift,
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
        color: ParadoxCodexScreen._panel,
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
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: ParadoxCodexScreen._rift,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: const Icon(Icons.open_in_new, size: 14),
        label: GoopText(
          'View on wiki.gg',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ParadoxCodexScreen._rift,
          ),
        ),
        onPressed: () async {
          final uri = Uri.parse(
              'https://enterthegungeon.wiki.gg/wiki/The_Paradox');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
    );
  }
}
