import '../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/gungeoneer.dart';
import '../services/effect_tagger.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import '../services/goop_talk_engine.dart';
import '../utils/asset_paths.dart';
import 'active_run/run_effects_block.dart';
import '../utils/responsive.dart';
part 'gungeoneer_header/header_builders.dart';
part 'gungeoneer_header/effect_chips.dart';

/// Banner for the Inventory: portrait + name + quick-glance stats row.
class GungeoneerHeader extends StatefulWidget {
  final Gungeoneer character;
  final double topDps;

  /// Tap handler for the DPS capsule — opens the damage calculator sheet.
  final VoidCallback? onTapDPS;
  final int gunCount;
  final int itemCount;
  final int activeSynergies;

  /// Back-compat: when provided, a tiny exit icon is rendered in the top-right.
  /// Prefer [trailing] for full control.
  final VoidCallback? onEndRun;

  /// Custom widget (e.g. popup menu) shown in the top-right of the banner.
  /// Takes precedence over [onEndRun].
  final Widget? trailing;

  /// When false, hides the synergies chip (used for the co-op player page).
  final bool showSynergies;

  /// Dungeon-wide coolness & curse totals. Shown as tappable bubbles in
  /// the name row. Each is dimmed when zero, lit when non-zero.
  final double coolness;
  final double curse;
  final VoidCallback? onTapCoolness;
  final VoidCallback? onTapCurse;

  /// Long-press handlers for the cool/curse bubbles. Wire to a quick
  /// inline +/- adjuster sheet so the user can tweak values without
  /// jumping to the full stats screen.
  final VoidCallback? onLongPressCoolness;
  final VoidCallback? onLongPressCurse;

  /// Tapped to open a compact grid of all possible synergies.
  final VoidCallback? onTapSynergies;

  /// Number of partial (potential) synergies — shown after a `|` in the
  /// synergy pill so users can see what's possible to complete.
  final int partialSynergies;

  /// Recognized passive effects (damage up, flight, dodge roll up, etc.)
  /// surfaced as compact chips with their extracted numeric stat where
  /// we can isolate one. Renders below the stats strip, toggled by the
  /// effects icon in the header trailing row.
  final List<EffectChip> effectChips;

  /// Chronological list of shrine names used this run. Shown in a
  /// compact tracker panel toggled by the shrine icon.
  final List<String> shrinesUsed;

  /// Robot damage boost percentage — when > 0, a cyber-styled +DMG%
  /// overlay is shown next to the avatar. Only meaningful for Robot.
  final double robotDamageBoost;

  const GungeoneerHeader({
    super.key,
    required this.character,
    required this.topDps,
    this.onTapDPS,
    required this.gunCount,
    required this.itemCount,
    required this.activeSynergies,
    this.onEndRun,
    this.trailing,
    this.showSynergies = true,
    this.coolness = 0,
    this.curse = 0,
    this.onTapCoolness,
    this.onTapCurse,
    this.onLongPressCoolness,
    this.onLongPressCurse,
    this.onTapSynergies,
    this.partialSynergies = 0,
    this.effectChips = const <EffectChip>[],
    this.shrinesUsed = const <String>[],
    this.robotDamageBoost = 0,
  });

  @override
  State<GungeoneerHeader> createState() => _GungeoneerHeaderState();
}

class _GungeoneerHeaderState extends State<GungeoneerHeader>
    with TickerProviderStateMixin, _HeaderBuilders {
  @override
  String? _quickComment;
  Timer? _commentTimer;
  @override
  late final AnimationController _wobbleController;
  @override
  late final AnimationController _borderPulseController;

  /// 0 = static icon, 1 = in-game GIF, 2 = animated card art.
  /// Defaults to 1 (in-game GIF) so the live sprite shows first —
  /// the most recognisable Gungeon visual.
  @override
  int _avatarMode = 1;

  @override
  void _onAvatarTapped() {
    _commentTimer?.cancel();
    Haptics.selection();

    setState(() {
      _avatarMode = (_avatarMode + 1) % 3;
    });

    final charName = widget.character.name.toLowerCase().trim();
    final List<String> quotes;

    if (charName.contains('marine')) {
      quotes = [
        "Area secure. Stay frosty.",
        "Negative. Keep moving by the book.",
        "No ammo wasted. Reloading.",
        "I miss my squad. Focus on Ch. 5.",
      ];
    } else if (charName.contains('pilot')) {
      quotes = [
        "Trust me, I have a magnificent plan.",
        "Never tell me the drop rates.",
        "Just slide-roll, smile, and steal.",
        "Is it hot here, or is it my charisma?",
      ];
    } else if (charName.contains('convict')) {
      quotes = [
        "Eat lead, bullet kin!",
        "Talk is cheap. Shell casings aren't.",
        "No rules down in these chambers.",
        "They think they can cage me? Ha!",
      ];
    } else if (charName.contains('hunter')) {
      quotes = [
        "Quiet... track their crosshairs.",
        "Good boy. Keep sniffing out chests.",
        "My trusty crossbow is ready.",
        "Aim small, miss small.",
      ];
    } else if (charName.contains('robot')) {
      quotes = [
        "JUNK IS THE OPTIMAL SOURCE OF FUEL.",
        "HUMAN VULNERABILITY MATRIX DETECTED.",
        "CRITICAL ERROR: TOO MUCH COOLNESS.",
        "01010011 01001100 01000001 01011001",
      ];
    } else if (charName.contains('bullet')) {
      quotes = [
        "I AM A HEROIC BULLET WITH A BLADE.",
        "No reload necessary for the Blasphemy!",
        "Swish! Whoosh! Clang!",
        "For the glory of the Bullet-King!",
      ];
    } else if (charName.contains('paradox')) {
      quotes = [
        "Who... what... when... am I?",
        "My layout is woven from stardust.",
        "Fractured cycles intersecting.",
        "The chamber is a loop inside a cylinder.",
      ];
    } else if (charName.contains('gunslinger')) {
      quotes = [
        "Draw.",
        "No trigger goes unpulled down here.",
        "This cylinder is empty... not for long.",
        "Yeehaw. Bullet synergies are active.",
      ];
    } else {
      quotes = [
        "Ready to breach the gungeon depths!",
        "Let's find some S-Tier guns!",
        "Watch your slide-rolls!",
        "Every chest is a mystery waiting to unlock.",
      ];
    }

    final rand = math.Random().nextInt(quotes.length);
    setState(() {
      _quickComment = quotes[rand];
    });

    _commentTimer = Timer(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _quickComment = null;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _borderPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _commentTimer?.cancel();
    _wobbleController.dispose();
    _borderPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.notifier,
      builder: (context, _, __) {
        return _buildExpanded(context);
      },
    );
  }
}

class _EffectChip extends StatelessWidget {
  final EffectChip chip;
  final Color color;
  const _EffectChip({required this.chip, required this.color});

  @override
  Widget build(BuildContext context) {
    final value = chip.value;
    return Tooltip(
      message: chip.tag.blurb,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.all(Radii.md),
          border: Border.all(color: color.withValues(alpha: 0.45), width: 0.7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(chip.tag.icon, color: color, size: 12.5),
            const SizedBox(width: 3),
            GoopText(
              chip.tag.label,
              style: TextStyle(
                fontSize: 11.5 * Responsive.factor(context),
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 3),
              GoopText(
                value,
                style: TextStyle(
                  fontSize: 11.5 * Responsive.factor(context),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
            if (chip.sourceCount > 1) ...[
              const SizedBox(width: 3),
              GoopText(
                '×${chip.sourceCount}',
                style: TextStyle(
                  fontSize: 10.5 * Responsive.factor(context),
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _RobotDmgBadge — cyber/matrix styled +DMG% overlay for the Robot
// =============================================================================

class _RobotDmgBadge extends StatelessWidget {
  final double boost;
  const _RobotDmgBadge({required this.boost});

  @override
  Widget build(BuildContext context) {
    final pct = boost.toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.flair.scaffold,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.4),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ASCII-art style header line
          GoopText(
            'DMG',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              fontWeight: FontWeight.w900,
              color: Colors.cyanAccent.withValues(alpha: 0.6),
              letterSpacing: 1.0,
              fontFamily: 'monospace',
              height: 1.0,
            ),
          ),
          const SizedBox(height: 1),
          // Big cyber number
          GoopText(
            '+$pct%',
            style: TextStyle(
              fontSize: 13 * Responsive.factor(context),
              fontWeight: FontWeight.w900,
              color: Colors.cyanAccent,
              letterSpacing: 0.5,
              fontFamily: 'monospace',
              height: 1.0,
              shadows: [
                Shadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
