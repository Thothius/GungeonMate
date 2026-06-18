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

  String _cleanStat(String raw) {
    if (raw.isEmpty) return '';
    var clean = raw;
    if (clean.contains('(')) {
      clean = clean.split('(').first;
    }
    if (clean.contains('/')) {
      clean = clean.split('/').first;
    }
    if (clean.contains('ETG')) {
      clean = clean.split('ETG').first;
    }
    clean = clean.trim();
    if (clean.length > 7) {
      clean = clean.substring(0, 7).trim();
    }
    return clean;
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 7.2,
              fontWeight: FontWeight.w900,
              color: Colors.white30,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(width: 2.0),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8.0,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
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
    final prefs = VisualPrefs.notifier.value;
    final displayMode = prefs.inventoryDisplayMode;

    final rawQColor = _qualityColor;
    final isS = _quality.toUpperCase() == 'S' || _quality.toUpperCase() == '1S';
    final qColor = isS ? const Color(0xFFFFD700) : rawQColor; // Gold/yellow for S
    final isHighTier = isS || _quality.toUpperCase() == 'A';

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: isS 
            ? const Color(0xFFFFD700) // Gold border
            : qColor.withValues(alpha: isHighTier ? 0.85 : 0.35),
        width: isS ? 1.9 : (isHighTier ? 1.4 : 0.8), // Fatter border frame for S
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
              child: CustomPaint(
                painter: _StrikethroughPainter(
                  color: Colors.redAccent.withValues(alpha: 0.42),
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
      return Positioned(
        top: topOffset,
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
                color: const Color(0xFF66E07A).withValues(alpha: 0.55 + 0.45 * t),
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
        // High density stats layout
        final double statsFontSize = (prefs.inventoryFontSize - 3).clamp(8.0, 12.0);
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          color: cardBgColor,
          shape: cardShape,
          elevation: isHighTier ? 4 : 1,
          child: InkWell(
            onTap: _handleTap,
            child: Column(
              children: [
                Expanded(
                  child: SizedBox.expand(
                    child: Stack(
                      children: [
                      Positioned(
                        left: 4,
                        top: 0,
                        bottom: 0,
                        width: 42,
                        child: Center(
                          child: maybeStrikethrough(
                            GameIcon(
                              assetPath: _iconPath,
                              fallback: isGun ? Icons.gps_fixed : Icons.extension,
                              quality: _quality,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 48,
                        right: 4,
                        top: 4,
                        bottom: 4,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: isGun
                                ? [
                                    if (widget.gun!.damage.isNotEmpty)
                                      _buildMiniStat('DMG', _cleanStat(widget.gun!.damage), Colors.redAccent),
                                    if (widget.gun!.magazineSize.isNotEmpty)
                                      _buildMiniStat('MAG', _cleanStat(widget.gun!.magazineSize), Colors.cyanAccent),
                                    if (widget.gun!.reloadTime.isNotEmpty)
                                      _buildMiniStat('RLD', _cleanStat(widget.gun!.reloadTime), Colors.amberAccent),
                                    if (widget.gun!.ammoCapacity.isNotEmpty)
                                      _buildMiniStat('MAX', _cleanStat(widget.gun!.ammoCapacity), Colors.greenAccent),
                                  ]
                                : [
                                    if (widget.item!.curse > 0)
                                      _buildMiniStat('CRS', '+${widget.item!.curse.toStringAsFixed(0)}', Colors.deepPurpleAccent)
                                    else if (widget.item!.coolness > 0)
                                      _buildMiniStat('COL', '+${widget.item!.coolness.toStringAsFixed(0)}', Colors.tealAccent)
                                    else if (widget.item!.rechargeTime.isNotEmpty)
                                      _buildMiniStat('RCH', _cleanStat(widget.item!.rechargeTime), Colors.orangeAccent)
                                    else if (widget.item!.duration.isNotEmpty)
                                      _buildMiniStat('DUR', _cleanStat(widget.item!.duration), Colors.pinkAccent)
                                    else ...[
                                      const SizedBox(height: 4),
                                      const Icon(Icons.shield_outlined, size: 10, color: Colors.white24),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'TACTICAL',
                                        style: TextStyle(
                                          fontSize: 6.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white24,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 3,
                        left: 4,
                        child: maybeQualityBadge(size: 15),
                      ),
                      maybeFastActiveDot(topOffset: 20),
                      Positioned(
                        top: 3,
                        right: 4,
                        child: maybeElements(),
                      ),
                      // EXPLICIT NUMERICAL DISPLAY TAG AT THE BOTTOM LEFT
                      if (_corner.isNotEmpty)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: widget.isTopDps 
                                  ? const Color(0xFFFFD700).withValues(alpha: 0.25)
                                  : Colors.black87,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: widget.isTopDps ? const Color(0xFFFFD700) : Colors.white12,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              _corner,
                              style: TextStyle(
                                fontSize: statsFontSize,
                                fontWeight: FontWeight.w900,
                                color: widget.isTopDps ? const Color(0xFFFFD700) : Colors.amberAccent,
                              ),
                            ),
                          ),
                        ),
                      // COMPACT CLASS / ROLE TAG AT THE BOTTOM RIGHT
                      if (_typeTagCompacted.isNotEmpty)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: _typeColor().withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: _typeColor().withValues(alpha: 0.4),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              _typeTagCompacted,
                              style: TextStyle(
                                fontSize: statsFontSize - 0.5,
                                fontWeight: FontWeight.bold,
                                color: _typeColor(),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(2, 3, 2, 4),
                  color: Colors.white.withValues(alpha: 0.02),
                  child: Text(
                    _name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: prefs.inventoryFontSize - 1.5,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case InventoryDisplayMode.highDefGraphic:
        // Gorgeous Pixel Art Showcase Layout
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          color: cardBgColor ?? const Color(0xFF131315),
          shape: cardShape,
          elevation: isHighTier ? 6 : 2,
          child: InkWell(
            onTap: _handleTap,
            child: SizedBox.expand(
              child: Stack(
                children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 20),
                    child: Center(
                      child: maybeStrikethrough(
                        GameIcon(
                          assetPath: _iconPath,
                          fallback: isGun ? Icons.gps_fixed : Icons.extension,
                          quality: _quality,
                          size: 60,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 5,
                  child: maybeQualityBadge(size: 20),
                ),
                maybeFastActiveDot(topOffset: 28),
                Positioned(
                  top: 5,
                  right: 5,
                  child: maybeElements(),
                ),
                // Glowing stats crown if top dps
                if (widget.isTopDps)
                  const Positioned(
                    top: 5,
                    left: 28,
                    child: Icon(Icons.star, color: Color(0xFFFFD700), size: 14),
                  ),
                // Transparent Overlaid Name Banner at the Bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                    child: Text(
                      _name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: prefs.inventoryFontSize - 1.0,
                        fontWeight: FontWeight.w900,
                        color: isHighTier ? qColor : Colors.white,
                        letterSpacing: 0.3,
                        shadows: const [
                          Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        );

      case InventoryDisplayMode.solidLabelBag:
        // Wide RPG list-grid row layout
        return Card(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          color: cardBgColor ?? const Color(0xFF17171A),
          shape: cardShape,
          elevation: isHighTier ? 3 : 1,
          child: InkWell(
            onTap: _handleTap,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: maybeStrikethrough(
                            GameIcon(
                              assetPath: _iconPath,
                              fallback: isGun ? Icons.gps_fixed : Icons.extension,
                              quality: _quality,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        left: 2,
                        child: maybeQualityBadge(size: 14),
                      ),
                      maybeFastActiveDot(topOffset: 16),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: prefs.inventoryFontSize + 1.0,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (widget.isTopDps) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 14),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (_typeTag.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: _typeColor().withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _typeColor().withValues(alpha: 0.45),
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  _typeTag,
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: _typeColor(),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 6),
                            if (_elements.isNotEmpty) ...[
                              for (final e in _elements)
                                Padding(
                                  padding: const EdgeInsets.only(right: 3),
                                  child: Icon(e.icon, size: 10, color: e.color),
                                ),
                            ],
                            const Spacer(),
                            if (_corner.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white12, width: 0.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isGun ? Icons.adjust_rounded : Icons.flash_on_rounded,
                                      size: 8,
                                      color: isGun ? Colors.amberAccent : Colors.lightBlueAccent,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _corner,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

      case InventoryDisplayMode.classicPeriodic:
      default:
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
                          padding: const EdgeInsets.all(4),
                          child: Center(
                            child: maybeStrikethrough(
                              GameIcon(
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
                      ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: maybeQualityBadge(),
                      ),
                      maybeFastActiveDot(),
                      Positioned(
                        top: 3,
                        right: 3,
                        child: maybeElements(),
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
                                      fontWeight: FontWeight.w900,
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
                      fontSize: prefs.inventoryFontSize,
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
