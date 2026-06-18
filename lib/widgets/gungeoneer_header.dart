import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/gungeoneer.dart';
import '../services/effect_tagger.dart';
import '../services/elemental_tagger.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';

/// Banner for the Inventory: portrait + name + quick-glance stats row.
class GungeoneerHeader extends StatefulWidget {
  final Gungeoneer character;
  final double topDps;
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

  /// Aggregated elemental effects this player's loadout currently
  /// applies (Fire, Freeze, Poison, Electric, Water, Stun, Charm,
  /// Explosive). When non-empty, renders a compact dashboard row of
  /// tinted element chips below the main stats strip so the player
  /// can see "this team ignites + electrifies" without drilling in.
  final Set<ElementKind> elements;

  /// Recognized passive effects (damage up, flight, dodge roll up, etc.)
  /// surfaced as compact chips with their extracted numeric stat where
  /// we can isolate one. Renders below the elemental row, only when
  /// non-empty so a fresh loadout doesn't take the vertical hit.
  final List<EffectChip> effectChips;

  const GungeoneerHeader({
    super.key,
    required this.character,
    required this.topDps,
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
    this.elements = const <ElementKind>{},
    this.effectChips = const <EffectChip>[],
  });

  @override
  State<GungeoneerHeader> createState() => _GungeoneerHeaderState();
}

class _GungeoneerHeaderState extends State<GungeoneerHeader> {
  String? _quickComment;
  Timer? _commentTimer;

  void _onAvatarTapped() {
    _commentTimer?.cancel();
    Haptics.selection();
    
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
  }

  @override
  void dispose() {
    _commentTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.notifier,
      builder: (context, _, __) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.35),
          ),
          child: _buildExpanded(context),
        );
      },
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final f = AppTheme.flair;
    final iconPath = widget.character.icon;
    final cdReduction = (widget.coolness * 5.0).clamp(0.0, 50.0);
    final ammoMultiplier = 1.0 + (widget.curse * 0.05) + (widget.coolness * 0.01);

    final trailingWidget = widget.trailing ?? (widget.onEndRun != null
        ? IconButton(
            tooltip: 'End run',
            onPressed: widget.onEndRun,
            icon: const Icon(Icons.exit_to_app, color: Colors.white70, size: 18),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          )
        : null);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Container(
        decoration: BoxDecoration(
          color: f.card,
          borderRadius: BorderRadius.circular(f.cardRadius),
          border: f.cardBorderColor != null
              ? Border.all(color: f.cardBorderColor!, width: f.cardBorderWidth)
              : Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0),
        ),
        clipBehavior: Clip.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Character Portrait, Name and Quick settings
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      // Clean, flat Avatar (Tappable for Quick Quotes!)
                      GestureDetector(
                        onTap: _onAvatarTapped,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: f.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: f.primary.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Transform.scale(
                              scale: 1.5,
                              child: iconPath.startsWith('assets/')
                                  ? Image.asset(
                                      iconPath,
                                      fit: BoxFit.contain,
                                      filterQuality: FilterQuality.none,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        size: 24,
                                        color: Colors.white54,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 24,
                                      color: Colors.white54,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Name column (vertically centered now that the
                      // status subtitle is gone)
                      Expanded(
                        child: Text(
                          widget.character.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.0,
                            height: 1.1,
                          ),
                        ),
                      ),

                      if (trailingWidget != null) ...[
                        trailingWidget,
                      ],
                    ],
                  ),
                  if (_quickComment != null)
                    Positioned(
                      top: 36,
                      left: 56,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E22), // Solid dark grey background
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: f.primary.withValues(alpha: 0.5), width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          _quickComment!,
                          style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: f.headlineStat,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Row 2: spacious horizontal gauge bar for stats (full width!)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFlatCapsule(
                      icon: Icons.ac_unit_rounded,
                      color: const Color(0xFF00E5FF),
                      value: '+${widget.coolness.toStringAsFixed(1)}',
                      label: 'COOL',
                      onTap: widget.onTapCoolness,
                      onLongPress: widget.onLongPressCoolness,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildFlatCapsule(
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFFF5252),
                      value: '+${widget.curse.toStringAsFixed(1)}',
                      label: 'CURSE',
                      onTap: widget.onTapCurse,
                      onLongPress: widget.onLongPressCurse,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildFlatCapsule(
                      icon: Icons.flash_on,
                      color: const Color(0xFF00B0FF),
                      value: '-${cdReduction.toStringAsFixed(0)}%',
                      label: 'CD ↓',
                      isActive: cdReduction > 0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildFlatCapsule(
                      icon: Icons.radio_button_checked_rounded,
                      color: const Color(0xFF00E676),
                      value: 'x${ammoMultiplier.toStringAsFixed(2)}',
                      label: 'AMMO',
                      isActive: ammoMultiplier > 1.0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildFlatCapsule(
                      icon: Icons.auto_awesome,
                      color: widget.activeSynergies > 0 ? const Color(0xFFFFD740) : Colors.white38,
                      value: '${widget.activeSynergies}',
                      label: 'SYN',
                      isActive: widget.activeSynergies > 0,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildFlatCapsule(
                      icon: Icons.bolt_rounded,
                      color: widget.topDps > 0 ? const Color(0xFFFF9100) : Colors.white38,
                      value: widget.topDps > 0 ? widget.topDps.toStringAsFixed(0) : '0',
                      label: 'DPS',
                      isActive: widget.topDps > 0,
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

            // PREMIUM BEVELED PASSIVE TAGS PANEL (Visually Padded and Shadowed!)
            if (widget.effectChips.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  child: _EffectChipsWrap(chips: widget.effectChips),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFlatCapsule({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isActive = true,
  }) {
    final capsule = Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: isActive 
            ? color.withValues(alpha: 0.08) 
            : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive 
              ? color.withValues(alpha: 0.35) 
              : Colors.white.withValues(alpha: 0.05),
          width: 1.0,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 13, color: isActive ? color : Colors.white38),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isActive ? Colors.white : Colors.white38,
                    height: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: isActive ? color : Colors.white24,
                letterSpacing: 0.6,
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
            _EffectChip(
              chip: c,
              color: _categoryColor(c.tag.category),
            ),
        ],
      );
    }

    final displayedChips = _isExpanded ? widget.chips : widget.chips.take(maxCollapsed).toList();
    final hiddenCount = widget.chips.length - maxCollapsed;

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final c in displayedChips)
          _EffectChip(
            chip: c,
            color: _categoryColor(c.tag.category),
          ),
        
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
                  _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: flair.headlineStat,
                  size: 13,
                ),
                const SizedBox(width: 3),
                Text(
                  _isExpanded ? 'COLLAPSE' : '+$hiddenCount MORE',
                  style: TextStyle(
                    fontSize: 10.5,
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.45),
            width: 0.7,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(chip.tag.icon, color: color, size: 12.5),
            const SizedBox(width: 3),
            Text(
              chip.tag.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
            if (chip.sourceCount > 1) ...[
              const SizedBox(width: 3),
              Text(
                '×${chip.sourceCount}',
                style: TextStyle(
                  fontSize: 10.5,
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

/// Horizontal strip of element indicators. Each chip is tinted with the
/// element's signature colour and carries a tooltip with the label so
/// long-press on mobile (and hover on desktop) surfaces the name. We
/// iterate `Element.values` (not the passed set) to keep ordering
/// deterministic across rebuilds.
///
/// Currently unused: the dashboard no longer renders this row (effect
/// chips already cover the same info). Kept around so we can put it
/// back behind a setting without re-implementing the layout.
// ignore: unused_element
class _ElementRow extends StatelessWidget {
  final Set<ElementKind> elements;
  const _ElementRow({required this.elements});

  @override
  Widget build(BuildContext context) {
    final ordered =
        ElementKind.values.where(elements.contains).toList(growable: false);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Icon(Icons.bolt,
              size: 12, color: Colors.white.withValues(alpha: 0.35)),
          const SizedBox(width: 6),
          Text(
            'ELEMENTS',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          for (final e in ordered) ...[
            Tooltip(
              message: e.label,
              child: Container(
                margin: const EdgeInsets.only(right: 5),
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: e.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: e.color.withValues(alpha: 0.5),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.icon, color: e.color, size: 11),
                    const SizedBox(width: 3),
                    Text(
                      e.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: e.color,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

