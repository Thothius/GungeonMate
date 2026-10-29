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
    with TickerProviderStateMixin {
  String? _quickComment;
  Timer? _commentTimer;
  late final AnimationController _wobbleController;
  late final AnimationController _borderPulseController;

  /// 0 = static icon, 1 = in-game GIF, 2 = animated card art.
  /// Defaults to 1 (in-game GIF) so the live sprite shows first —
  /// the most recognisable Gungeon visual.
  int _avatarMode = 1;

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

  Widget _buildExpanded(BuildContext context) {
    final f = AppTheme.flair;
    final iconPath = widget.character.icon;
    final trailingWidget =
        widget.trailing ??
        (widget.onEndRun != null
            ? IconButton(
              tooltip: 'End run',
              onPressed: widget.onEndRun,
              icon: const Icon(
                Icons.exit_to_app,
                color: Colors.white70,
                size: 18,
              ),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(Insets.xs),
            )
            : null);

    // Neutralize the global text scaler so the header layout stays
    // pixel-stable regardless of the theme's font-size setting. The
    // stat capsules use FittedBox, but the avatar/name area doesn't —
    // a 2.28x scale factor would blow up the single-row layout.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _borderPulseController,
            builder: (context, child) {
              final pulse =
                  (math.sin(_borderPulseController.value * 2 * math.pi) + 1) /
                  2;
              final borderAlpha = 0.15 + pulse * 0.25;
              return Container(
                decoration: BoxDecoration(
                  color: f.card,
                  borderRadius: BorderRadius.circular(f.cardRadius),
                  border: Border.all(
                    color: f.primary.withValues(alpha: borderAlpha),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: f.primary.withValues(alpha: borderAlpha * 0.3),
                      blurRadius: 8 + pulse * 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                clipBehavior: Clip.none,
                child: child,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Single row: Avatar + COOL + CURSE + SYN + DPS + Gear menu
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Row(
                        children: [
                          // Clean, flat Avatar (Tappable — cycles through
                          // static icon → in-game GIF → animated card art).
                          GestureDetector(
                            onTap: _onAvatarTapped,
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: _buildAvatarContent(iconPath),
                            ),
                          ),
                          // Robot +DMG cyber overlay — shown when robotDamageBoost > 0.
                          if (widget.robotDamageBoost > 0) ...[
                            const SizedBox(width: 3),
                            _RobotDmgBadge(boost: widget.robotDamageBoost),
                          ],
                          const SizedBox(width: 6),
                          // 4 stat capsules share the remaining space equally
                          Expanded(
                            child: _buildFlatCapsule(
                              color: const Color(0xFF00E5FF),
                              value: '+${widget.coolness.toStringAsFixed(1)}',
                              label: 'COOL',
                              onTap: widget.onTapCoolness,
                              onLongPress: widget.onLongPressCoolness,
                              isCool: true,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildFlatCapsule(
                              color: const Color(0xFFE040FB),
                              value: '+${widget.curse.toStringAsFixed(1)}',
                              label: 'CURSE',
                              onTap: widget.onTapCurse,
                              onLongPress: widget.onLongPressCurse,
                              isCurse: true,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildFlatCapsule(
                              color:
                                  widget.activeSynergies > 0
                                      ? const Color(0xFFFFD740)
                                      : Colors.white38,
                              value:
                                  widget.partialSynergies > 0
                                      ? '${widget.activeSynergies}|${widget.partialSynergies}'
                                      : '${widget.activeSynergies}',
                              label: 'SYN',
                              onTap: widget.onTapSynergies,
                              isActive: widget.activeSynergies > 0,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildFlatCapsule(
                              color:
                                  widget.topDps > 0
                                      ? const Color(0xFFFF9100)
                                      : Colors.white38,
                              value:
                                  widget.topDps > 0
                                      ? widget.topDps.toStringAsFixed(0)
                                      : '0',
                              label: 'DPS',
                              onTap: widget.onTapDPS,
                              isActive: widget.topDps > 0,
                            ),
                          ),
                          if (trailingWidget != null) ...[
                            const SizedBox(width: 6),
                            trailingWidget,
                          ],
                        ],
                      ),
                      if (_quickComment != null)
                        Positioned(
                          top: 42,
                          left: 60,
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Insets.sm,
                                vertical: Insets.xs,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme
                                        .flair
                                        .card, // Solid dark grey background
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: f.primary.withValues(alpha: 0.5),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: GoopText(
                                _quickComment!,
                                style: TextStyle(
                                  fontSize: FontSizes.labelSmall,
                                  fontStyle: FontStyle.italic,
                                  color: f.headlineStat,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Dynamic themed divider/decoration
                Container(
                  height: 1.0,
                  width: double.infinity,
                  color: Colors.white.withValues(alpha: 0.05),
                ),

                // EFFECTS PANEL — compact cool/curse stats + pull-down
                // controls only (passive tags removed). Toggled by the
                // effects button via VisualPrefs.showEffectsPanel.
                ...[
                  ListenableBuilder(
                    listenable: VisualPrefs.notifier,
                    builder: (context, _) {
                      if (!VisualPrefs.notifier.value.showEffectsPanel) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: f.primary.withValues(alpha: 0.12),
                              width: 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const RunEffectsBlock(),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(String iconPath) {
    final char = widget.character;
    final fallback = const Icon(Icons.person, size: 28, color: Colors.white54);

    if (_avatarMode == 0) {
      // Static icon
      return iconPath.startsWith('assets/')
          ? Image.asset(
            iconPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
            cacheWidth: 96,
            cacheHeight: 96,
            errorBuilder: (_, __, ___) => fallback,
          )
          : fallback;
    }

    if (_avatarMode == 1) {
      // In-game animated GIF
      final gifPath = gungeoneerGifPath(char.name);
      if (gifPath.isNotEmpty) {
        return Image.asset(
          gifPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
          cacheWidth: 96,
          cacheHeight: 96,
          errorBuilder:
              (_, __, ___) =>
                  iconPath.startsWith('assets/')
                      ? Image.asset(
                        iconPath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        cacheWidth: 96,
                        cacheHeight: 96,
                        errorBuilder: (_, __, ___) => fallback,
                      )
                      : fallback,
        );
      }
      return iconPath.startsWith('assets/')
          ? Image.asset(
            iconPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            cacheWidth: 96,
            cacheHeight: 96,
            errorBuilder: (_, __, ___) => fallback,
          )
          : fallback;
    }

    // Animated card art
    final cardPath = gungeoneerAnimatedCardPath(char.name);
    if (cardPath.isNotEmpty) {
      return Image.asset(
        cardPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        cacheWidth: 96,
        cacheHeight: 96,
        errorBuilder:
            (_, __, ___) =>
                iconPath.startsWith('assets/')
                    ? Image.asset(
                      iconPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      cacheWidth: 96,
                      cacheHeight: 96,
                      errorBuilder: (_, __, ___) => fallback,
                    )
                    : fallback,
      );
    }
    return iconPath.startsWith('assets/')
        ? Image.asset(
          iconPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          cacheWidth: 96,
          cacheHeight: 96,
          errorBuilder: (_, __, ___) => fallback,
        )
        : fallback;
  }

  Widget _buildFlatCapsule({
    required Color color,
    required String value,
    required String label,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isActive = true,
    bool isCool = false,
    bool isCurse = false,
  }) {
    final double coolVal = widget.coolness;
    final double curseVal = widget.curse;

    final double coolGlowIntensity =
        (coolVal >= 2) ? (coolVal / 20.0).clamp(0.1, 1.0) : 0.0;
    final double curseGlowIntensity =
        (curseVal >= 2) ? (curseVal / 10.0).clamp(0.1, 1.0) : 0.0;

    // Glow wrapper for value text — replaces the old icon-based glow
    Widget valueText = GoopText(
      value,
      style: TextStyle(
        fontSize: FontSizes.bodyMedium,
        fontWeight: FontWeight.w900,
        color: isActive ? Colors.white : Colors.white38,
        height: 1.1,
      ),
    );

    if (isCool && coolGlowIntensity > 0) {
      valueText = RepaintBoundary(
        child: AnimatedBuilder(
          animation: _wobbleController,
          builder: (context, child) {
            final pulse = math.sin(_wobbleController.value * 2 * math.pi) * 3.0;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF00E5FF,
                    ).withValues(alpha: 0.55 * coolGlowIntensity),
                    blurRadius: (8.0 + pulse) * coolGlowIntensity,
                    spreadRadius: (1.5 + pulse * 0.2) * coolGlowIntensity,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: valueText,
        ),
      );
    } else if (isCurse && curseGlowIntensity > 0) {
      valueText = RepaintBoundary(
        child: AnimatedBuilder(
          animation: _wobbleController,
          builder: (context, child) {
            final pulse =
                math.sin(_wobbleController.value * 2 * math.pi * 2) * 2.0;
            final wobbleX =
                math.sin(_wobbleController.value * 2 * math.pi * 4) *
                2.5 *
                curseGlowIntensity;
            final wobbleY =
                math.cos(_wobbleController.value * 2 * math.pi * 3) *
                1.8 *
                curseGlowIntensity;
            final wobbleAngle =
                math.sin(_wobbleController.value * 2 * math.pi * 5) *
                0.14 *
                curseGlowIntensity;

            return Transform.translate(
              offset: Offset(wobbleX, wobbleY),
              child: Transform.rotate(
                angle: wobbleAngle,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFE040FB,
                        ).withValues(alpha: 0.65 * curseGlowIntensity),
                        blurRadius: (8.0 + pulse) * curseGlowIntensity,
                        spreadRadius: (1.2 + pulse * 0.15) * curseGlowIntensity,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: valueText,
        ),
      );
    }

    final capsule = Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color:
            isActive
                ? color.withValues(alpha: 0.16)
                : Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isActive
                  ? color.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.10),
          width: 1.0,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            valueText,
            const SizedBox(height: 2),
            GoopText(
              label,
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w900,
                color: isActive ? color : Colors.white24,
                letterSpacing: 0.4,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null && onLongPress == null) {
      return capsule;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        onLongPress: onLongPress,
        child: capsule,
      ),
    );
  }
}

/// Wrapped strip of recognized-effect chips. Wraps (not scrolls) so
/// every active effect is visible at a glance — the dash "grows" as
/// the run accumulates passives, which is the visual cue the user
/// asked for. Each chip combines: tag icon + label + (optional)
/// extracted numeric value.
class _EffectChipsWrap extends StatefulWidget {
  final List<EffectChip> chips;
  const _EffectChipsWrap({required this.chips});

  @override
  State<_EffectChipsWrap> createState() => _EffectChipsWrapState();
}

class _EffectChipsWrapState extends State<_EffectChipsWrap> {
  bool _isExpanded = false;

  Color _categoryColor(EffectCategory c) {
    switch (c) {
      case EffectCategory.mobility:
        return const Color(0xFF80DEEA);
      case EffectCategory.damage:
        return const Color(0xFFFFAB91);
      case EffectCategory.ammo:
        return const Color(0xFFFFE082);
      case EffectCategory.defense:
        return const Color(0xFFA5D6A7);
      case EffectCategory.utility:
        return const Color(0xFFCE93D8);
      case EffectCategory.economy:
        return const Color(0xFFFFD54F);
      case EffectCategory.status:
        return const Color(0xFFFFB74D);
      case EffectCategory.debuff:
        return const Color(0xFFEF9A9A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final maxCollapsed = 6;

    if (widget.chips.length <= maxCollapsed) {
      return Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final c in widget.chips)
            _EffectChip(chip: c, color: _categoryColor(c.tag.category)),
        ],
      );
    }

    final displayedChips =
        _isExpanded ? widget.chips : widget.chips.take(maxCollapsed).toList();
    final hiddenCount = widget.chips.length - maxCollapsed;

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in displayedChips)
          _EffectChip(chip: c, color: _categoryColor(c.tag.category)),

        // Inline tactile expand/collapse action pill
        InkWell(
          onTap: () {
            Haptics.selection();
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: flair.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: flair.primary.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: flair.headlineStat,
                  size: 13,
                ),
                const SizedBox(width: 3),
                GoopText(
                  _isExpanded ? 'COLLAPSE' : '+$hiddenCount MORE',
                  style: TextStyle(
                    fontSize: 10.5 * Responsive.factor(context),
                    fontWeight: FontWeight.w900,
                    color: flair.headlineStat,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
