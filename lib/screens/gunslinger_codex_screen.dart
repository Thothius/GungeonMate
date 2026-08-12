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
                    title: 'Story',
                    color: _gold,
                  ),
                  _InfoBlock(
                    body:
                        'The Gunslinger is the ancient gunslinging wizard who constructed The Gungeon out of a concern that the way of guns would out-compete the old magics. He is the pre-mortem version of the Lich, whose presence in the present is only possible thanks to the paradoxical timestream.',
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
                    icon: Icons.lock_open,
                    title: 'How to Unlock',
                    color: _ember,
                  ),
                  _InfoBlock(
                    heading: 'Step 1 — Play as The Paradox',
                    body:
                        'Defeat the Lich as The Paradox. This will immediately launch you into a new run as The Gunslinger at the beginning of the first chamber (or wherever the Paradox started, if the elevator was used).',
                    accent: _ember,
                  ),
                  _InfoBlock(
                    heading: 'Step 2 — A Single Attempt',
                    body:
                        'This is only a single attempt at unlocking him permanently. If you die, quick restart, or exit the game without saving before finishing his run, you will have to start the entire process over with another Paradox run.',
                    accent: _ember,
                  ),
                  _InfoBlock(
                    heading: 'Step 3 — Get the Bullet',
                    body:
                        'Play through the game again, making SURE to get the Bullet That Can Kill The Past from the Blacksmith in the Forge. If you don\'t get the Bullet before entering the Aimless Void, firing the Gun will send you straight to the credits — and you\'ll have to begin again with another Paradox run.',
                    accent: _ember,
                  ),
                  _InfoBlock(
                    heading: 'Step 4 — Kill His Past',
                    body:
                        'Traveling to the past takes you to Bullet Hell. Unlike other pasts, you keep your health and all items gathered during the run. Everything is identical to normal Bullet Hell until the Lich boss fight — which is special. See "The Past Kill" below.',
                    accent: _ember,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.emoji_events,
                    title: 'The Past Kill — Dual Lich Fight',
                    color: _gold,
                  ),
                  _InfoBlock(
                    heading: 'Two Liches',
                    body:
                        'Instead of fighting a normal three-phase Lich, you fight TWO Liches simultaneously — similar to the Glitch Chest boss. One Lich is normal, and the other has the same visual effect as The Paradox.',
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
                    icon: Icons.casino,
                    title: 'Starter Loadout & Strategy',
                    color: _ember,
                  ),
                  _InfoBlock(
                    heading: 'Starter Gun — Slinger',
                    body:
                        'The Gunslinger starts with the Slinger, a unique weapon that embodies his legendary reloading technique. He also carries Lich\'s Eye Bullets as his passive item.',
                    accent: _ember,
                  ),
                  _InfoBlock(
                    heading: 'Lich\'s Eye Bullets',
                    body:
                        'This passive grants the player every synergy a gun could have without needing the counterpart item. For example, you can have the Cactus and get the Cactus Flower synergy without needing Broccoli or Orange. This renders many weak weapons much more powerful and makes cheap shop guns excellent options.',
                    accent: _ember,
                  ),
                  _InfoBlock(
                    heading: 'Easiest Gungeoneer',
                    body:
                        'The Gunslinger is generally considered the easiest Gungeoneer to play, thanks to Lich\'s Eye Bullets making nearly any gun viable. He costs 7 Hegemony Credits to play and cannot drop Lich\'s Eye Bullets.',
                    accent: _ember,
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
