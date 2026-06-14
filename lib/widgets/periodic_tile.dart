import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/gun.dart';
import '../models/item.dart';
import '../models/player.dart';
import '../providers/run_provider.dart';
import '../services/elemental_tagger.dart';
import '../services/app_theme.dart';
import 'game_icon.dart';
import 'quality_badge.dart';
import 'synergy_glow.dart';

/// Periodic-table inspired tile for Active Run inventory.
///
/// Interactions:
/// - single tap → `onTap`
/// - **hold** → the tile shakes for ~650ms to communicate "I'm listening",
///   then fires `onLongPress` (if provided). The shake cancels if the
///   finger is lifted before the threshold, so single-tap-to-open stays
///   snappy.
class PeriodicTile extends StatefulWidget {
  final Gun? gun;
  final Item? item;
  final bool isTopDps;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  /// When non-null the tile renders a pulsing colored glow ring to signal
  /// an active synergy. Each synergy gets a distinct deterministic color
  /// from [RunProvider.activeSynergyGlowColors].
  final Color? synergyGlowColor;
  final bool wideMode;

  const PeriodicTile({
    super.key,
    this.gun,
    this.item,
    this.isTopDps = false,
    required this.onTap,
    this.onLongPress,
    this.synergyGlowColor,
    this.wideMode = false,
  }) : assert(
          (gun == null) != (item == null),
          'PeriodicTile needs exactly one of gun/item — '
          'the icon/type fallbacks assume the other is non-null.',
        );

  @override
  State<PeriodicTile> createState() => _PeriodicTileState();
}

class _PeriodicTileState extends State<PeriodicTile>
    with TickerProviderStateMixin {
  late final AnimationController _shake;
  late final AnimationController _poof;

  /// Slow ambient pulse that drives the "fast active" green dot. Only
  /// allocated for tiles that actually need it (active items with a
  /// short recharge), so the rest of the grid stays cheap.
  AnimationController? _pulse;
  /// Repeating pulse controller for the synergy glow ring. Allocated only
  /// when [PeriodicTile.synergyGlowColor] is non-null.
  AnimationController? _glow;
  bool _longPressArmed = false;

  /// Duration the user must hold to fire [onLongPress]. Tuned so normal
  /// tap-and-release feels instant while the shake gives clear feedback.
  static const Duration _holdDuration = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _poof = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    if (_isFastActive) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    }
    if (widget.synergyGlowColor != null) {
      final idx = _effectIndex;
      _glow = AnimationController(
        vsync: this,
        duration: synergyEffectDuration(idx),
      )..repeat(reverse: synergyEffectReverse(idx));
    }
  }

  int get _effectIndex => _name.hashCode.abs() % 10;

  @override
  void didUpdateWidget(covariant PeriodicTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // SliverGrid reuses State across different gun/item identities when
    // the underlying list mutates (sort change, remove, add). Re-evaluate
    // whether the *current* widget warrants a pulse dot and reconcile the
    // controller — without this, a slot that originally held a non-fast
    // active never grows the dot when promoted to a fast active.
    final wantsPulse = _isFastActive;
    if (wantsPulse && _pulse == null) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    } else if (!wantsPulse && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
    // Sync glow controller with current synergyGlowColor.
    // If the name changed the effect index may differ — recreate.
    final wantsGlow = widget.synergyGlowColor != null;
    final nameChanged = oldWidget.gun?.name != widget.gun?.name ||
        oldWidget.item?.name != widget.item?.name;
    if (wantsGlow && (_glow == null || nameChanged)) {
      _glow?.dispose();
      final idx = _effectIndex;
      _glow = AnimationController(
        vsync: this,
        duration: synergyEffectDuration(idx),
      )..repeat(reverse: synergyEffectReverse(idx));
    } else if (!wantsGlow && _glow != null) {
      _glow!.dispose();
      _glow = null;
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    _poof.dispose();
    _pulse?.dispose();
    _glow?.dispose();
    super.dispose();
  }

  // --- Decoration heuristics ----------------------------------------------

  /// True when this tile represents an active item with a short
  /// (≤ 5-second) recharge. Used to flag "press me often" actives with a
  /// gentle pulsing dot so the user can tell at-a-glance which actives
  /// are spammable vs damage-charged or kills-charged.
  bool get _isFastActive {
    final it = widget.item;
    if (it == null || !it.isActive) return false;
    final rt = it.rechargeTime.trim().toLowerCase();
    if (rt.isEmpty) return false;
    // Must be seconds-charged. "300 dmg" / "30 kills" / "1 room" stay false.
    if (!RegExp(r's\b').hasMatch(rt)) return false;
    final m = RegExp(r'\d+(?:\.\d+)?').firstMatch(rt);
    if (m == null) return false;
    final n = double.tryParse(m.group(0)!) ?? 999;
    return n <= 5.0;
  }

  /// True when the active item is consumed on use (Junk, Mirror, etc.).
  /// Surfaced as a corner "ONE USE" badge so the user instantly clocks
  /// "single-shot — use deliberately" without a strikethrough making
  /// the artwork look like it's broken.
  bool get _isDestroyedOnUse =>
      widget.item != null && widget.item!.isDestroyedOnUse;

  /// Border + glow color, derived from the entity's quality. We lean on
  /// the same palette as [QualityBadge] so the badge and tile read as
  /// the same visual language.
  Color get _qualityColor =>
      _quality.isEmpty ? Colors.white24 : QualityBadge.colorFor(_quality);

  bool get isGun => widget.gun != null;
  String get _name => widget.gun?.name ?? widget.item?.name ?? '';
  String get _quality =>
      widget.gun?.quality ?? widget.item?.quality ?? '';
  String get _iconPath =>
      widget.gun?.icon ?? widget.item?.icon ?? '';

  String get _corner {
    if (widget.gun != null) {
      final g = widget.gun!;
      if (g.dps.isEmpty) return '';
      final v = g.dpsValue;
      if (v == 0) return g.dps;
      return v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    }
    final it = widget.item;
    if (it != null) {
      if (it.name.toLowerCase() == 'ser junkan') {
        final p = context.read<RunProvider>();
        final hasP1 = p.runState.main.items.any((i) => i.name.toLowerCase() == 'ser junkan');
        final hasCoop = p.runState.coop?.items.any((i) => i.name.toLowerCase() == 'ser junkan') ?? false;
        final player = hasCoop && !hasP1 ? (p.runState.coop ?? Player()) : p.runState.main;
        final junkCount = player.items.where((i) => i.name.toLowerCase() == 'junk').length;
        final hasGoldJunk = player.items.any((i) => i.name.toLowerCase() == 'gold junk');
        if (hasGoldJunk) return 'MECHA';
        switch (junkCount) {
          case 0: return 'PEASANT';
          case 1: return 'SQUIRE';
          case 2: return 'HEDGE';
          case 3: return 'KNIGHT';
          case 4: return 'LIEUT';
          case 5: return 'CMDR';
          case 6: return 'HOLY';
          default: return 'ANGEL';
        }
      }
      if (it.isActive && it.rechargeTime.isNotEmpty) {
        return it.rechargeTime;
      }
    }
    return '';
  }

  /// User-facing tag shown in the bottom-right corner of each tile.
  /// For guns: the firearm class (Pistol / Shotgun / Rifle / ...).
  /// For items: full-text role (Active / Passive / Companion).
  String get _typeTag {
    if (widget.gun != null) {
      final cls = widget.gun!.gunClass.trim().toUpperCase();
      if (cls.isEmpty || cls == 'NONE') return 'GUN';
      switch (cls) {
        case 'FULLAUTO':
          return 'Auto';
        case 'PISTOL':
          return 'Pistol';
        case 'SHOTGUN':
          return 'Shotgun';
        case 'RIFLE':
          return 'Rifle';
        case 'BEAM':
          return 'Beam';
        case 'CHARGE':
          return 'Charge';
        case 'EXPLOSIVE':
          return 'Explosive';
        case 'FIRE':
          return 'Fire';
        case 'ICE':
          return 'Ice';
        case 'POISON':
          return 'Poison';
        case 'CHARM':
          return 'Charm';
        case 'SILLY':
          return 'Silly';
        case 'SHITTY':
          return 'Joke';
        default:
          // Title-case fallback: "RAILGUN" → "Railgun"
          if (cls.isEmpty) return cls;
          return cls[0] + cls.substring(1).toLowerCase();
      }
    }
    final it = widget.item;
    if (it == null) return '';
    if (it.isCompanion) return 'Companion';
    if (it.isActive) return 'Active';
    if (it.isPassive) return 'Passive';
    return 'Item';
  }

  String get _typeTagCompacted {
    final full = _typeTag;
    if (widget.wideMode) return full;
    switch (full) {
      case 'Companion': return 'Comp';
      case 'Passive': return 'Pass';
      case 'Active': return 'Act';
      case 'Explosive': return 'Expl';
      case 'Shotgun': return 'Shtg';
      case 'Pistol': return 'Pist';
      case 'Rifle': return 'Rifl';
      case 'Charge': return 'Chrg';
      case 'Semiauto': return 'Semi';
      case 'Automatic': return 'Auto';
      default: return full;
    }
  }

  Color _typeColor() {
    if (widget.gun != null) {
      final cls = widget.gun!.gunClass.toUpperCase();
      switch (cls) {
        case 'FIRE':
          return Colors.deepOrangeAccent;
        case 'ICE':
          return Colors.lightBlueAccent;
        case 'POISON':
          return Colors.lightGreenAccent;
        case 'CHARM':
          return Colors.pinkAccent;
        case 'EXPLOSIVE':
          return Colors.redAccent;
        case 'BEAM':
          return Colors.cyanAccent;
        case 'SHOTGUN':
          return Colors.amberAccent;
        case 'PISTOL':
        case 'RIFLE':
        case 'FULLAUTO':
        case 'CHARGE':
          return Colors.orangeAccent;
        default:
          return Colors.deepOrangeAccent;
      }
    }
    final it = widget.item;
    if (it == null) return Colors.white54;
    if (it.isCompanion) return Colors.purpleAccent;
    if (it.isActive) return Colors.lightBlueAccent;
    if (it.isPassive) return Colors.lightGreenAccent;
    return Colors.white54;
  }

  /// Elemental effect icons for the tile — shown top-right, max 3.
  /// Delegates detection to [ElementalTagger] so both guns *and* items
  /// surface the same badges (e.g. Frost Bullets shows a freeze icon,
  /// Shock Rounds shows an electric icon). Order follows the enum
  /// declaration so a given loadout always renders indicators in a
  /// stable order.
  List<({IconData icon, Color color, String tooltip})> get _elements {
    final Set<ElementKind> els = widget.gun != null
        ? ElementalTagger.elementsOfGun(widget.gun!)
        : widget.item != null
            ? ElementalTagger.elementsOfItem(widget.item!)
            : const <ElementKind>{};
    if (els.isEmpty) return const [];
    // Iterate the enum (not the set) so ordering is deterministic.
    final out = <({IconData icon, Color color, String tooltip})>[];
    for (final e in ElementKind.values) {
      if (!els.contains(e)) continue;
      out.add((icon: e.icon, color: e.color, tooltip: e.label));
      if (out.length >= 3) break;
    }
    return out;
  }

  void _beginHoldCycle() {
    if (widget.onLongPress == null) return;
    _longPressArmed = true;
    // Gentle shake = "I'm listening, keep holding"
    _shake.repeat(reverse: true);
    Future.delayed(_holdDuration, () {
      if (!mounted || !_longPressArmed) return;
      _longPressArmed = false;
      _shake.stop();
      _shake.value = 0;
      // Quick confirmation pulse, then open the transfer sheet.
      _poof.forward(from: 0);
      widget.onLongPress?.call();
    });
  }

  void _cancelHoldCycle() {
    _longPressArmed = false;
    if (_shake.isAnimating) {
      _shake.stop();
      _shake.animateTo(0, duration: const Duration(milliseconds: 120));
    }
  }

  /// Tap forwarder for the parent's onTap.
  /// Both gesture paths and the inner InkWell route through this so we
  /// can't double-fire even if Flutter delivers redundant events.
  void _handleTap() {
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    final constrainedBody = MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.05),
      ),
      child: body,
    );
    if (widget.onLongPress == null) {
      // No long-press wiring needed — the inner InkWell handles the tap
      // (and its haptic) by itself, no outer GestureDetector required.
      return constrainedBody;
    }
    // Outer GestureDetector is here purely for the hold→fire long-press
    // cycle; taps fall through to the inner InkWell (which already pipes
    // through `_handleTap`), avoiding a double-registered tap recognizer.
    return GestureDetector(
      onLongPressStart: (_) => _beginHoldCycle(),
      onLongPressCancel: _cancelHoldCycle,
      onLongPressEnd: (_) => _cancelHoldCycle(),
      // Use our own timing; disable default long-press behavior by NOT
      // passing onLongPress directly.
      child: AnimatedBuilder(
        animation: Listenable.merge([_shake, _poof]),
        builder: (ctx, child) {
          final shakeOffset = _shake.isAnimating
              ? math.sin(_shake.value * math.pi * 6) * 2.2
              : 0.0;
          // Poof: quick scale 1.0 → 1.15 → 0.92, fading ring
          double scale = 1.0;
          double glow = 0.0;
          if (_poof.isAnimating || _poof.value > 0) {
            final t = _poof.value;
            // 0 → 0.35 scale up, 0.35 → 1 scale down
            if (t < 0.35) {
              scale = 1.0 + (t / 0.35) * 0.15;
            } else {
              scale = 1.15 - ((t - 0.35) / 0.65) * 0.23;
            }
            glow = (1.0 - (t - 0.2).clamp(0.0, 1.0)).clamp(0.0, 1.0);
          }
          return Transform.translate(
            offset: Offset(shakeOffset, 0),
            child: Transform.scale(
              scale: scale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  child!,
                  if (glow > 0.01)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.45 * glow),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
        child: constrainedBody,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final card = _buildCard(context);
    if (widget.synergyGlowColor == null || _glow == null) return card;
    return SynergyGlowOverlay(
      controller: _glow!,
      color: widget.synergyGlowColor!,
      effectIndex: _effectIndex,
      radius: 8,
      child: card,
    );
  }

  Widget _buildCard(BuildContext context) {
    final rawQColor = _qualityColor;
    final isS = _quality.toUpperCase() == 'S' || _quality.toUpperCase() == '1S';
    final qColor = isS ? const Color(0xFFFFD700) : rawQColor; // Gold/yellow for S
    final isHighTier = isS || _quality.toUpperCase() == 'A';
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: isS ? const Color(0xFF14120E) : null, // Premium dark gold/black background frame for S-tier
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isS 
              ? const Color(0xFFFFD700) // Gold border
              : qColor.withValues(alpha: isHighTier ? 0.85 : 0.35),
          width: isS ? 1.9 : (isHighTier ? 1.4 : 0.8), // Fatter border frame for S
        ),
      ),
      shadowColor: isHighTier ? qColor.withValues(alpha: 0.55) : null,
      elevation: isHighTier ? 4 : 1,
      child: InkWell(
        onTap: _handleTap,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Center(
                        child: GameIcon(
                          assetPath: _iconPath,
                          fallback: isGun
                              ? Icons.gps_fixed
                              : (widget.item!.isActive
                                  ? Icons.flash_on
                                  : Icons.inventory_2_outlined),
                          quality: _quality,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                  // Diagonal strike across the icon for single-use actives
                  // (Junk, Mirror, Glass Guon Stone). Subtle alpha so it
                  // reads as a hint, not a "broken" indicator.
                  if (_isDestroyedOnUse)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _StrikethroughPainter(
                            color: Colors.redAccent.withValues(alpha: 0.42),
                          ),
                        ),
                      ),
                    ),
                  if (_quality.isNotEmpty)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: QualityBadge(quality: _quality, size: 18),
                    ),
                  // Pulsing green dot for fast active items (≤ 5s recharge).
                  // Lives just below the quality badge so the two left-aligned
                  // indicators stack cleanly when both are present.
                  if (_isFastActive && _pulse != null)
                    Positioned(
                      top: _quality.isNotEmpty ? 24 : 4,
                      left: 6,
                      child: AnimatedBuilder(
                        animation: _pulse!,
                        builder: (_, __) {
                          final t = _pulse!.value;
                          return Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF66E07A).withValues(
                                alpha: 0.55 + 0.45 * t,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF66E07A).withValues(
                                    alpha: 0.55 * t,
                                  ),
                                  blurRadius: 4 + 2 * t,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  // Elemental effect icons, top-right. Stacked vertically
                  // when multiple elements apply (e.g. The Judge).
                  if (_elements.isNotEmpty)
                    Positioned(
                      top: 3,
                      right: 3,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final e in _elements)
                            Tooltip(
                              message: e.tooltip,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: e.color.withValues(alpha: 0.65),
                                    width: 0.6,
                                  ),
                                ),
                                child: Icon(e.icon,
                                    size: 11, color: e.color),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (widget.gun != null && widget.gun!.range.isNotEmpty && widget.gun!.range != '0')
                    Positioned(
                      bottom: 24,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.6,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.adjust_outlined, size: 8, color: Colors.orangeAccent),
                            const SizedBox(width: 2.5),
                            Text(
                              widget.gun!.range,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: 4,
                    right: 4,
                    bottom: 4,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_corner.isNotEmpty)
                          (() {
                            final badge = Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isTopDps 
                                    ? const Color(0xFFFFD700).withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(4),
                                border: widget.isTopDps
                                    ? Border.all(color: const Color(0xFFFFD700), width: 1)
                                    : null,
                              ),
                              child: Text(
                                _corner,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900, // bolder and chunkier!
                                  color: widget.isTopDps ? const Color(0xFFFFD700) : Colors.white,
                                  height: 1.1,
                                ),
                              ),
                            );
                            if (widget.isTopDps) {
                              return badge.animate(
                                onPlay: (controller) => controller.repeat(reverse: true),
                              ).scaleXY(end: 1.08, duration: 1000.ms, curve: Curves.easeInOut)
                               .shimmer(delay: 1500.ms, duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5));
                            }
                            return badge;
                          })()
                        else
                          const SizedBox.shrink(),
                        if (_typeTagCompacted.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: _typeColor().withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _typeColor().withValues(alpha: 0.55),
                                width: 0.7,
                              ),
                            ),
                            child: Text(
                              _typeTagCompacted,
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: _typeColor(),
                                letterSpacing: 0.2,
                                height: 1.1,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
              color: Colors.white.withValues(alpha: 0.03),
              child: Text(
                _name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: VisualPrefs.notifier.value.inventoryFontSize,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a single faint diagonal line across the tile face, used to
/// flag actives that get destroyed on use (e.g. Junk, Glass Guon Stone).
/// Kept as a `CustomPainter` rather than a rotated container so the
/// stroke stays crisp at any tile aspect ratio.
class _StrikethroughPainter extends CustomPainter {
  final Color color;
  const _StrikethroughPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    // Top-right → bottom-left, leaving a small inset so the line doesn't
    // hug the tile corners.
    final inset = size.shortestSide * 0.18;
    canvas.drawLine(
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StrikethroughPainter oldDelegate) =>
      oldDelegate.color != color;
}
