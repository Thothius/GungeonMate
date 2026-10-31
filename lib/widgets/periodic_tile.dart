import '../theme/tokens.dart';
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
import '../services/goop_talk_engine.dart';
import 'game_icon.dart';
import 'quality_badge.dart';
import 'synergy_glow.dart' hide SynergyGlowOverlay;
import '../utils/reduce_motion.dart';
import '../utils/responsive.dart';
part 'periodic_tile/tile_logic.dart';
part 'periodic_tile/tile_parts.dart';

/// Periodic-table inspired tile for Active Run inventory.
///
/// Interactions:
/// - single tap → `onTap`
/// - **hold** → the tile shakes briefly to communicate "I'm listening",
///   then fires `onLongPress` (if provided) after ~180ms. The shake
///   cancels if the finger is lifted before the threshold, so
///   single-tap-to-open stays snappy.
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
    with TickerProviderStateMixin, _PeriodicTileLogic {
  // --- Decoration heuristics ----------------------------------------------
  /// Border + glow color, derived from the entity's quality. We lean on
  /// the same palette as [QualityBadge] so the badge and tile read as
  /// the same visual language.
  Color get _qualityColor =>
      _quality.isEmpty ? Colors.white24 : QualityBadge.colorFor(_quality);

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

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);
    // ponytail: removed the textScaler clamp (0.8–1.05) that prevented
    // fonts from scaling on bigger screens. Font sizes are now scaled
    // individually via Responsive.font() in _buildCard.
    // Semantic label: announce the entity name and quality tier so
    // screen-reader users can navigate the grid meaningfully.
    final semLabel =
        _name.isNotEmpty ? '$_name, quality $_quality' : 'Item tile';
    final constrainedBody = Semantics(
      label: semLabel,
      button: true,
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
          final shakeOffset =
              _shake.isAnimating
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
                            borderRadius: BorderRadius.all(Radii.sm),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(
                                  alpha: 0.45 * glow,
                                ),
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
    // Reduced-motion: skip the animated synergy glow overlay — the card
    // still shows its quality border and content, just without the glow.
    if (widget.synergyGlowColor == null || _glow == null) return card;
    // Uniform blue synergy badge — replaces the color-coded animated
    // glow border; one marker meaning "in a synergy" for all tiles.
    return Stack(
      children: [
        card,
        const Positioned(top: 4, right: 4, child: SynergyBadge()),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    final prefs = VisualPrefs.notifier.value;
    final displayMode = prefs.inventoryDisplayMode;
    final sf = Responsive.factor(context);

    final rawQColor = _qualityColor;
    final isS = _quality.toUpperCase() == 'S';
    final qColor =
        isS ? const Color(0xFFFFD700) : rawQColor; // Gold/yellow for S
    final isHighTier = isS || _quality.toUpperCase() == 'A';

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radii.sm),
      side: BorderSide(
        color:
            isS
                ? const Color(0xFFFFD700) // Gold border
                : qColor.withValues(alpha: isHighTier ? 0.85 : 0.35),
        width:
            isS ? 1.9 : (isHighTier ? 1.4 : 0.8), // Fatter border frame for S
      ),
    );

    final cardBgColor = isS ? const Color(0xFF14120E) : null;

    // Helper: Strikethrough for single-use active items
    Widget maybeStrikethrough(Widget child) {
      if (!_isDestroyedOnUse) return child;
      return Stack(
        children: [
          child,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _StrikethroughPainter(
                    color: Colors.redAccent.withValues(alpha: 0.42),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Helper: Quality Badge overlay
    Widget maybeQualityBadge({double size = 18}) {
      if (_quality.isEmpty) return const SizedBox.shrink();
      return QualityBadge(quality: _quality, size: size);
    }

    // Helper: Fast active item pulsing green dot
    Widget maybeFastActiveDot({double topOffset = 24}) {
      if (!_isFastActive || _pulse == null) return const SizedBox.shrink();
      // Reduced-motion: static green dot (no pulse).
      if (ReduceMotion.of(context)) {
        return Positioned(
          top: topOffset,
          left: 6,
          child: Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF66E07A),
            ),
          ),
        );
      }
      return Positioned(
        top: topOffset,
        left: 6,
        child: AnimatedBuilder(
          animation: _pulse!,
          builder: (_, _) {
            final t = _pulse!.value;
            return Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF66E07A,
                ).withValues(alpha: 0.55 + 0.45 * t),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF66E07A).withValues(alpha: 0.55 * t),
                    blurRadius: 4 + 2 * t,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // Helper: Elemental badge row/column
    Widget maybeElements() {
      if (_elements.isEmpty) return const SizedBox.shrink();
      return Column(
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
                child: Icon(e.icon, size: 11, color: e.color),
              ),
            ),
        ],
      );
    }

    // Branch visual representation based on displayMode
    switch (displayMode) {
      case InventoryDisplayMode.tacticalStats:
        final double statsFontSize = (prefs.inventoryFontSize - 2.0).clamp(
          9.0,
          13.0,
        );
        final double labelFontSize = (statsFontSize - 2.0).clamp(7.0, 10.0);
        final flair = AppTheme.flair;

        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.all(3),
          color: cardBgColor ?? const Color(0xFF17150F),
          shape: cardShape,
          elevation: isHighTier ? 4 : 1,
          child: InkWell(
            onTap: _handleTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top: big icon + full-width name + quality badge
                  Row(
                    children: [
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: GameIcon(
                          assetPath: _iconPath,
                          fallback: isGun ? Icons.gps_fixed : Icons.extension,
                          quality: _quality,
                          size: 39,
                          showRing: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GoopText(
                          _name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: statsFontSize + 1,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      maybeQualityBadge(size: 18),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Type badge + indicators row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: flair.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: flair.secondary.withValues(alpha: 0.45),
                            width: 0.6,
                          ),
                        ),
                        child: GoopText(
                          (isGun ? widget.gun!.type : widget.item!.type)
                              .toUpperCase(),
                          style: TextStyle(
                            fontSize: labelFontSize,
                            fontWeight: FontWeight.w900,
                            color: flair.secondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (widget.isTopDps)
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: Colors.orangeAccent,
                          size: 16,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.white10,
                  ),
                  const SizedBox(height: 4),
                  // 2×3 stat grid — all stats visible
                  Expanded(
                    child:
                        isGun
                            ? _StatGrid(
                              stats: [
                                (
                                  'DPS',
                                  _cleanStat(widget.gun!.dps),
                                  Colors.amberAccent,
                                ),
                                (
                                  'MAG',
                                  _cleanStat(widget.gun!.magazineSize),
                                  Colors.cyanAccent,
                                ),
                                (
                                  'RELOAD',
                                  _cleanStat(widget.gun!.reloadTime),
                                  Colors.orangeAccent,
                                ),
                                (
                                  'RANGE',
                                  _cleanStat(widget.gun!.range),
                                  Colors.lightBlueAccent,
                                ),
                                (
                                  'FORCE',
                                  _cleanStat(widget.gun!.force),
                                  Colors.redAccent,
                                ),
                                (
                                  'SPREAD',
                                  _cleanStat(widget.gun!.spread),
                                  Colors.purpleAccent,
                                ),
                              ],
                              valueSize: statsFontSize,
                              labelSize: labelFontSize,
                            )
                            : _StatGrid(
                              stats: [
                                (
                                  'CURSE',
                                  '+${widget.item!.curse.toStringAsFixed(0)}',
                                  Colors.deepPurpleAccent,
                                ),
                                (
                                  'COOL',
                                  '+${widget.item!.coolness.toStringAsFixed(0)}',
                                  Colors.tealAccent,
                                ),
                                (
                                  'RCHRG',
                                  _cleanStat(widget.item!.rechargeTime),
                                  Colors.orangeAccent,
                                ),
                                (
                                  'DUR',
                                  _cleanStat(widget.item!.duration),
                                  Colors.pinkAccent,
                                ),
                                ('CLASS', widget.item!.type, Colors.white60),
                                (
                                  'PRICE',
                                  _cleanStat(widget.item!.sellPrice),
                                  Colors.greenAccent,
                                ),
                              ],
                              valueSize: statsFontSize,
                              labelSize: labelFontSize,
                            ),
                  ),
                ],
              ),
            ),
          ),
        );

      case InventoryDisplayMode.classicPeriodic:
        // Balanced classic Gungeon periodic table look (default)
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          color: cardBgColor,
          shape: cardShape,
          shadowColor: isHighTier ? qColor.withValues(alpha: 0.55) : null,
          elevation: isHighTier ? 4 : 1,
          child: InkWell(
            onTap: _handleTap,
            child: Column(
              children: [
                Expanded(
                  child: SizedBox.expand(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Center(
                              child: maybeStrikethrough(
                                GameIcon(
                                  assetPath: _iconPath,
                                  fallback:
                                      isGun
                                          ? Icons.gps_fixed
                                          : (widget.item!.isActive
                                              ? Icons.flash_on
                                              : Icons.inventory_2_outlined),
                                  quality: _quality,
                                  // 20% smaller inventory graphics
                                  // (66 → 53) per the declutter pass.
                                  size: 53,
                                  showRing: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(top: 4, left: 4, child: maybeQualityBadge()),
                        maybeFastActiveDot(),
                        // Top-right: elemental icons only (type moved to subtitle below name)
                        Positioned(top: 3, right: 3, child: maybeElements()),
                        // Bottom-center: item badges only (RCHRG/DUR, Junkan
                        // rank). Guns keep the tile face clean — DPS moved
                        // to the bottom subtitle row next to the gun type.
                        if (!isGun)
                          Positioned(
                            left: 4,
                            right: 4,
                            bottom: 4,
                            child: Center(
                              child:
                                  widget.item != null && widget.item!.isActive
                                      ? _buildItemStatsBadge()
                                      : _buildLegacyItemBadge(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(4, 3, 4, 5),
                  color: Colors.white.withValues(alpha: 0.03),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GoopText(
                        _name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: prefs.inventoryFontSize * sf,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      // Type subtitle — centered below the name. Guns get
                      // the DPS value beside the type as a dimmed yellow
                      // tag (RANGE hidden per the declutter pass).
                      if (_typeTag.isNotEmpty ||
                          (isGun && _corner.isNotEmpty)) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_typeTag.isNotEmpty)
                              Flexible(
                                child: GoopText(
                                  _typeTag,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: FontSizes.labelSmall * sf,
                                    fontWeight: FontWeight.w700,
                                    color: _typeColor(),
                                    letterSpacing: 0.3,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            if (isGun && _corner.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              GoopText(
                                _corner,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: FontSizes.labelSmall * sf,
                                  fontWeight: FontWeight.w800,
                                  // Top-DPS gun: solid gold + soft glow so
                                  // the best damage weapon reads at a
                                  // glance. Others stay dimmed.
                                  color:
                                      widget.isTopDps
                                          ? const Color(0xFFFFD700)
                                          : const Color(
                                            0xFFFFD54F,
                                          ).withValues(alpha: 0.6),
                                  shadows:
                                      widget.isTopDps
                                          ? const [
                                            Shadow(
                                              color: Color(0xAAFFD700),
                                              blurRadius: 7,
                                            ),
                                          ]
                                          : null,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }
}
