import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/goop_talk_engine.dart';

/// Themed Codex page for The Gunslinger — the legendary hero who built
/// the Gungeon. Presents lore, the complex unlock chain (Paradox → Lich
/// → Gunslinger run → Bullet → past kill), the dual-Lich boss fight,
/// strategy, and trivia in a gold/amber themed layout.
class GunslingerCodexScreen extends StatelessWidget {
  const GunslingerCodexScreen({super.key});

  // Gunslinger's legendary hero aesthetic — gold/amber on near-black.
  static const Color _gold = Color(0xFFFFD54F);
  static const Color _ember = Color(0xFFFF6B35);
  static const Color _void = Color(0xFF0D0B08);
  static const Color _panel = Color(0xFF1A1610);

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
                    color: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Master of the Gungeon',
                    body:
                        'The Gunslinger is the ultimate reward for mastering the game. He is the pre-cursed form of the Lich himself — the ancient gunslinging wizard who constructed The Gungeon out of a concern that the way of guns would out-compete the old magics. He fights through the Gungeon to prevent his own dark future.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Legendary Gunfighter',
                    body:
                        'Known by enemies and friends alike for his unusual reloading technique — simply throwing the empty gun at his foe and drawing a new one from his magical belt. He was also a powerful wizard who combined his two hobbies via arcane experiments, infusing magic into the firearms of his fascination.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Great Bullet',
                    body:
                        'Fearing guns would replace old magics, he retreated to the planet Gunymede and built a grim fortress with a mine beneath it. He was working on a gun capable of killing the past itself when the Great Bullet — a mighty projectile descending from the heavens — crashed upon the keep. The Slinger was never seen alive again.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Quote',
                    body:
                        '"I think he was worried that guns would make the magics of the old world obsolete. In that way, I guess he was right..." — The Blacksmith',
                    accent: _ember,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.casino,
                    title: 'Mechanical Loadout',
                    color: _ember,
                  ),
                  _InfoBlock(
                    heading: 'Fundamentally Overpowered',
                    body:
                        'The Gunslinger is fundamentally overpowered by design, breaking the game\'s synergy math. He is generally considered the easiest Gungeoneer to play. Costs 7 Hegemony Credits per run — the most expensive in the game.',
                    accent: _ember,
                  ),
                  _InfoBlock(
                    heading: 'Starter Weapon — Slinger',
                    body:
                        'A highly accurate, fast-firing revolver. When thrown upon reloading (like a Tediore weapon in Borderlands), it deals massive damage. This embodies his legendary technique of throwing the empty gun at his foe and drawing a new one from his magical belt.',
                    accent: _ember,
                  ),
                  _InfoBlock(
                    heading: 'Passive Item — Lich\'s Eye Bullets',
                    body:
                        'The most broken passive item in the game. It instantly grants every possible synergy for any gun the Gunslinger holds, bypassing the need to find the matching synergy items. A mediocre D-tier weapon instantly becomes a boss-melting powerhouse in his hands. He cannot drop this item.',
                    accent: _ember,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.lock_open,
                    title: 'The Gauntlet — How to Unlock',
                    color: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Chain',
                    body:
                        'Unlocking these two characters requires a highly specific, consecutive chain of events. Failing at any step after the Paradox is unlocked means you have to start all over with a new Paradox run.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Step 1 — Spawn the Cosmic Rift',
                    body:
                        'Prerequisite: you must have killed at least one character\'s Past. Play a standard run. On Chamber 2, 3, or 4, explore until you find a room with a swirling cosmic puddle on the floor (20% spawn chance).',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Step 2 — Absorb the Paradox',
                    body:
                        'Walk over the cosmic rift and press the interact button. Your character will absorb the rift, gaining a permanent, static-like cosmic visual effect for the rest of the run.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Step 3 — Defeat the Lich (Unlocks The Paradox)',
                    body:
                        'With the cosmic effect active, complete the run and defeat the Lich in Bullet Hell. Upon victory, The Paradox is permanently unlocked.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Step 4 — Start a Paradox Run',
                    body:
                        'Costs 5 Hegemony Credits. Start a new run specifically playing as The Paradox. You are at the mercy of the random loadout generation here.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Step 5 — Defeat the Lich Again (The Transition)',
                    body:
                        'Survive Bullet Hell and defeat the Lich as The Paradox. Do NOT turn off the game. Instead of a victory screen, the game will instantly pull you back to Chamber 1.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Step 6 — Survive the Gunslinger Run',
                    body:
                        'You will instantly start a new run playing as The Gunslinger. You must play entirely through Chambers 1–5 again in this single sitting. Make SURE to get the Bullet That Can Kill The Past from the Blacksmith in the Forge — without it, firing the Gun sends you to the credits and you start over.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Step 7 — Defeat the Gunslinger\'s Past',
                    body:
                        'Grab the Bullet and shoot yourself with the Gun That Can Kill The Past. You will be transported to the Gunslinger\'s past, where you must defeat two Liches simultaneously (one of which is Jammed). Survive this, and The Gunslinger is permanently unlocked.',
                    accent: _gold,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.emoji_events,
                    title: 'The Past Kill — Dual Lich Fight',
                    color: _gold,
                  ),
                  _InfoBlock(
                    heading: 'An Anomalous Past',
                    body:
                        'His "Past" is an anomaly. Because he IS the Lich, killing his past requires fighting two Liches simultaneously in a terrifying showdown — one normal, one Jammed/Paradox-glitched. Unlike other pasts, you keep your health and all items gathered during the run.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Dual Fight',
                    body:
                        'Instead of a normal three-phase Lich, you fight TWO Liches at once — similar to the Glitch Chest boss. One Lich is normal, and the other has the same visual effect as The Paradox. The Paradox Lich fires Jammed bullets and has increased health. Luckily, both Liches use only their first phase, and the player wins once both are defeated.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Paradox Lich',
                    body:
                        'The Paradox Lich fires Jammed bullets and has increased health. Luckily, both Liches use only their first phase, and the player wins once both are defeated.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Ending',
                    body:
                        'The final scene shows the Gungeon as it looked before the Bullet crashed into it. The victory screen shows the Gunslinger throwing away his gun — implying that time was rewritten and the Gungeon was never created. This leads directly into the events of Exit the Gungeon.',
                    accent: _gold,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.info_outline,
                    title: 'Notes & Trivia',
                    color: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Cinematic Inspiration',
                    body:
                        'The Gunslinger resembles Clint Eastwood in A Fistful of Dollars. The Lich (his post-mortem form) resembles Lee Van Cleef in The Good, the Bad and the Ugly — creating narrative symbolism with the Gunslinger being "The Good" and the Lich being "The Bad".',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Living Poncho',
                    body:
                        'His poncho appears to be alive — it has a face on it which blinks during his idle animation. When petting the Dog, the poncho will smile.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Bullet Eyes',
                    body:
                        'His injured portrait during the Punchout fight with the Resourceful Rat shows his eyes to be bullets, suggesting he used bullets as prosthetic eyes even before he became the Lich.',
                    accent: _gold,
                  ),
                  _InfoBlock(
                    heading: 'The Sixth Chamber',
                    body:
                        'Defeating the Gunslinger\'s past unlocks the Sixth Chamber, as the boss is considered Jammed. A golden skull trophy also appears in the Breach in the Sorceress\' room.',
                    accent: _gold,
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
// Header — hero image + title with golden glow
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
            'assets/images/gungeoneers/animated/Gunslinger_Card_Animated.gif',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: GunslingerCodexScreen._void,
              child: Center(
                child: Icon(Icons.emoji_events,
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
                    GunslingerCodexScreen._void.withValues(alpha: 0.4),
                    GunslingerCodexScreen._void.withValues(alpha: 0.95),
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
                'LEGENDARY HERO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: GunslingerCodexScreen._ember.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
              GoopText(
                'THE GUNSLINGER',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: GunslingerCodexScreen._gold,
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
        color: GunslingerCodexScreen._panel,
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
          foregroundColor: GunslingerCodexScreen._gold,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: const Icon(Icons.open_in_new, size: 14),
        label: GoopText(
          'View on wiki.gg',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: GunslingerCodexScreen._gold,
          ),
        ),
        onPressed: () async {
          final uri = Uri.parse(
              'https://enterthegungeon.wiki.gg/wiki/The_Gunslinger');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
    );
  }
}
