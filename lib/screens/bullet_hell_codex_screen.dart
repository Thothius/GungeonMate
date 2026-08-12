import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/goop_talk_engine.dart';

/// Themed Codex page for Chamber 6: Bullet Hell — the true final domain.
/// Opened from a dedicated tab in the Codex. Presents lore, entry
/// conditions, survival mechanics, the three-loop layout, hazards, and
/// the Lich boss fight in a clear, scrollable, dark-neon layout.
class BulletHellCodexScreen extends StatelessWidget {
  const BulletHellCodexScreen({super.key});

  // Bullet Hell's demonic/fleshy aesthetic — red/orange neon on near-black.
  static const Color _ember = Color(0xFFFF5252);
  static const Color _emberDim = Color(0xFFB71C1C);
  static const Color _bone = Color(0xFFFFD54F);
  static const Color _void = Color(0xFF0D0B0A);
  static const Color _panel = Color(0xFF1A1311);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header image + title
          SliverToBoxAdapter(child: _Header()),
          // Content sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(
                    icon: Icons.auto_stories,
                    title: 'Lore & Entry',
                    color: _ember,
                  ),
                  _InfoBlock(
                    body:
                        'Bullet Hell is the true final domain of the Gungeon, home to the Lich — the cursed gunslinger who mastered the Gungeon and commands its undead legions.',
                    accent: _ember,
                  ),
                  _InfoBlock(
                    heading: 'Access Trigger',
                    body:
                        'The floor remains hidden until the player has successfully defeated the Pasts of the four main Gungeoneers (Marine, Pilot, Convict, Hunter).',
                    accent: _ember,
                  ),
                  _InfoBlock(
                    heading: 'The Descent',
                    body:
                        'Once unlocked, proceeding to the "Gun That Can Kill The Past" in the Aimless Void (after defeating the Dragun) will prompt a skeletal hand to drag the player down into Chamber 6. On subsequent runs, players can choose to walk around the central pit to end the run normally, or jump in to face the Lich.',
                    accent: _ember,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.block,
                    title: 'Survival — The "No Loot" Rule',
                    color: _bone,
                  ),
                  _InfoBlock(
                    heading: 'Resource Starvation',
                    body:
                        'The engine restricts all standard loot generation. There are no chest rooms, no shops, and no shrines on this floor.',
                    accent: _bone,
                  ),
                  _InfoBlock(
                    heading: 'Drop Reliance',
                    body:
                        'Players are entirely dependent on random room-clear drops for health, armor, and ammo. Ammo conservation and cycling backup weapons is mechanically essential here.',
                    accent: _bone,
                  ),
                  _InfoBlock(
                    heading: 'High Jammed Rate',
                    body:
                        'Due to the late stage of the game, players carrying any Curse stat will encounter a significantly higher volume of "Jammed" (red/black) enemies, who deal double damage and have massive health pools.',
                    accent: _bone,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.route,
                    title: 'The Three-Loop Layout',
                    color: _ember,
                  ),
                  _InfoBlock(
                    body:
                        'Unlike the sprawling randomness of earlier chambers, Bullet Hell\'s map generation follows a strict mathematical ruleset built around three distinct junction points. Vital data for players trying to conserve ammo:',
                    accent: _ember,
                  ),
                  _JunctionCard(
                    label: 'Junction 1',
                    body:
                        'The starting room branches into three paths. One path is a hard dead-end. The other two paths will eventually merge together and lead to the next junction.',
                  ),
                  _JunctionCard(
                    label: 'Junction 2',
                    body:
                        'Three new paths emerge. In this loop, two of the paths will connect to each other (often leading to a dead-end loop), while the singular third path pushes forward.',
                  ),
                  _JunctionCard(
                    label: 'Junction 3',
                    body:
                        'The final three-way split. Two of these are extensive dead-ends. The third path leads straight to the boss.',
                  ),
                  _InfoBlock(
                    heading: 'The Boss Door Rule',
                    body:
                        'The layout generation dictates that the final boss room can only be entered by moving North. The engine will never generate a South, East, or West-facing door into the final arena.',
                    accent: _ember,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.dangerous,
                    title: 'Hazards & Enemies',
                    color: _bone,
                  ),
                  _InfoBlock(
                    heading: 'Flesh Cubes & Shotgrubs',
                    body:
                        'The floor uses a demonic, fleshy aesthetic. Players will face the highest-tier enemy variants, notably Shotgrubs (which fire fast, highly erratic, waving bullet patterns) and Flesh Cubes (which aggressively crush the player while releasing bullets).',
                    accent: _bone,
                  ),
                  _InfoBlock(
                    heading: 'Environmental Traps',
                    body:
                        'Rooms frequently lack cover and are surrounded by pits, forcing players into pure dodging mechanics rather than table-flipping.',
                    accent: _bone,
                  ),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    icon: Icons.emoji_events,
                    title: 'The Boss: The Lich',
                    color: _ember,
                  ),
                  _InfoBlock(
                    body:
                        'The final encounter is a grueling, three-phase endurance test that ignores the standard boss DPS-cap in its transitions.',
                    accent: _ember,
                  ),
                  _PhaseCard(
                    phase: 'Phase 1',
                    name: 'The Gunslinger',
                    body:
                        'Fought in a standard room. The Lich uses fast, traditional revolver patterns, requiring tight dodge rolls and quick sidesteps.',
                  ),
                  _PhaseCard(
                    phase: 'Phase 2',
                    name: 'The Giant Skeleton',
                    body:
                        'The player falls into a massive arena. The Lich becomes a giant skeletal torso, sweeping the entire screen with dense, interlocking walls of bullets and slamming the ground.',
                  ),
                  _PhaseCard(
                    phase: 'Phase 3',
                    name: 'The Cosmic Entity',
                    body:
                        'The Lich transforms into a spinning, multi-armed entity traversing the room. This phase generates the most mathematically complex, overlapping geometric bullet patterns in the game, acting as the ultimate test of the player\'s i-frame mastery.',
                  ),
                  const SizedBox(height: 20),
                  _WikiLink(),
                ],
              ),
            ),
          ),
        ],
    );
  }
}

// =============================================================================
// Header — hero image + chamber title with ember glow
// =============================================================================

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hero image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          child: Image.asset(
            'assets/images/codex/Bullethell_header.png',
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: BulletHellCodexScreen._void,
              child: Center(
                child: Icon(Icons.image_not_supported,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
          ),
        ),
        // Gradient scrim for readability
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
                    BulletHellCodexScreen._void.withValues(alpha: 0.4),
                    BulletHellCodexScreen._void.withValues(alpha: 0.95),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Title overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GoopText(
                'CHAMBER 6',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: BulletHellCodexScreen._bone.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 2),
              GoopText(
                'BULLET HELL',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: BulletHellCodexScreen._ember,
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
        color: BulletHellCodexScreen._panel,
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
// Junction card — numbered layout loop with ember accent
// =============================================================================

class _JunctionCard extends StatelessWidget {
  final String label;
  final String body;

  const _JunctionCard({required this.label, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: BulletHellCodexScreen._panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: BulletHellCodexScreen._ember.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: BulletHellCodexScreen._emberDim.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: BulletHellCodexScreen._ember.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: GoopText(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: BulletHellCodexScreen._ember,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GoopText(
              body,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms, delay: 80.ms);
  }
}

// =============================================================================
// Phase card — boss phase with number badge
// =============================================================================

class _PhaseCard extends StatelessWidget {
  final String phase;
  final String name;
  final String body;

  const _PhaseCard({
    required this.phase,
    required this.name,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: BulletHellCodexScreen._panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: BulletHellCodexScreen._ember.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: BulletHellCodexScreen._ember.withValues(alpha: 0.06),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase number circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BulletHellCodexScreen._void,
              border: Border.all(
                color: BulletHellCodexScreen._ember,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: BulletHellCodexScreen._ember.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: GoopText(
                phase.split(' ').last,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: BulletHellCodexScreen._ember,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GoopText(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
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
    ).animate().fadeIn(duration: 200.ms, delay: 100.ms);
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
          foregroundColor: BulletHellCodexScreen._ember,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: const Icon(Icons.open_in_new, size: 14),
        label: GoopText(
          'View on wiki.gg',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: BulletHellCodexScreen._ember,
          ),
        ),
        onPressed: () async {
          final uri = Uri.parse(
              'https://enterthegungeon.wiki.gg/wiki/Bullet_Hell');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
    );
  }
}
