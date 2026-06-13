import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/gun.dart';
import '../models/item.dart';
import '../services/elemental_tagger.dart';
import 'game_icon.dart';
import 'quality_badge.dart';
import 'synergy_glow.dart';

/// Compact one-per-row representation of a gun or item for the
/// inventory *list* view mode. Pairs a pixel-art portrait with the
/// name, quality badge, elemental indicators, a type tag, and a headline
/// stat (DPS for guns, recharge for items) in a single 56px-tall row.
///
/// Gestures match the grid tile so switching views doesn't change
/// interaction: single tap → [onTap], long press → [onLongPress].
class InventoryListRow extends StatefulWidget {
  final Gun? gun;
  final Item? item;
  final bool isTopDps;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  /// When non-null, renders a pulsing left accent bar + background tint
  /// in this color to signal an active synergy for the item/gun.
  final Color? synergyGlowColor;

  const InventoryListRow({
    super.key,
    this.gun,
    this.item,
    this.isTopDps = false,
    required this.onTap,
    this.onLongPress,
    this.synergyGlowColor,
  }) : assert(
          (gun == null) != (item == null),
          'Provide exactly one of gun or item',
        );

  @override
  State<InventoryListRow> createState() => _InventoryListRowState();
}

class _InventoryListRowState extends State<InventoryListRow>
    with SingleTickerProviderStateMixin {
  AnimationController? _glow;

  int get _effectIndex => _name.hashCode.abs() % 10;

  @override
  void initState() {
    super.initState();
    if (widget.synergyGlowColor != null) {
      final idx = _effectIndex;
      _glow = AnimationController(
        vsync: this,
        duration: synergyEffectDuration(idx),
      )..repeat(reverse: synergyEffectReverse(idx));
    }
  }

  @override
  void didUpdateWidget(covariant InventoryListRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wants = widget.synergyGlowColor != null;
    final nameChanged = oldWidget.gun?.name != widget.gun?.name ||
        oldWidget.item?.name != widget.item?.name;
    if (wants && (_glow == null || nameChanged)) {
      _glow?.dispose();
      final idx = _effectIndex;
      _glow = AnimationController(
        vsync: this,
        duration: synergyEffectDuration(idx),
      )..repeat(reverse: synergyEffectReverse(idx));
    } else if (!wants && _glow != null) {
      _glow!.dispose();
      _glow = null;
    }
  }

  @override
  void dispose() {
    _glow?.dispose();
    super.dispose();
  }

  bool get _isGun => widget.gun != null;

  String get _name => _isGun ? widget.gun!.name : widget.item!.name;
  String get _quality => _isGun ? widget.gun!.quality : widget.item!.quality;
  String get _iconPath => _isGun ? widget.gun!.icon : widget.item!.icon;

  /// "DPS 42" for guns, "5s" recharge for timed items, type label for
  /// passives/companions.
  ({String value, String? unit, Color color}) get _primary {
    if (_isGun) {
      final v = widget.gun!.dpsValue;
      if (v <= 0) {
        return (value: '—', unit: null, color: Colors.white38);
      }
      final str = v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
      return (
        value: str,
        unit: 'DPS',
        color: widget.isTopDps
            ? const Color(0xFFFFD700)
            : const Color(0xFFFFB74D),
      );
    }
    final it = widget.item!;
    if (it.rechargeTime.isNotEmpty) {
      return (
        value: it.rechargeTime,
        unit: 's',
        color: const Color(0xFF81D4FA),
      );
    }
    return (value: '', unit: null, color: Colors.transparent);
  }

  /// Short type tag: the gun's `type`, or Active/Passive/Companion for
  /// items. Matches the chip in `PeriodicTile._typeTag` so the two
  /// views stay consistent.
  String get _typeTag {
    if (_isGun) {
      final t = widget.gun!.type.trim();
      return t.isEmpty ? '' : t.toUpperCase();
    }
    final it = widget.item!;
    if (it.isCompanion) return 'COMPANION';
    if (it.isActive) return 'ACTIVE';
    if (it.isPassive) return 'PASSIVE';
    return '';
  }

  Color get _typeColor {
    if (_isGun) return const Color(0xFFB0BEC5);
    final it = widget.item!;
    if (it.isCompanion) return Colors.purpleAccent;
    if (it.isActive) return Colors.lightBlueAccent;
    if (it.isPassive) return Colors.lightGreenAccent;
    return Colors.white54;
  }

  Set<ElementKind> get _elements => _isGun
      ? ElementalTagger.elementsOfGun(widget.gun!)
      : ElementalTagger.elementsOfItem(widget.item!);

  @override
  Widget build(BuildContext context) {
    final primary = _primary;
    final tag = _typeTag;
    final els = _elements;
    final gc = widget.synergyGlowColor;
    final glowCtrl = _glow;

    Widget row = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          child: Row(
            children: [
              GameIcon(
                assetPath: _iconPath,
                fallback: _isGun
                    ? Icons.gps_fixed
                    : Icons.inventory_2_outlined,
                quality: _quality,
                size: 48,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        QualityBadge(quality: _quality, size: 18),
                        if (tag.isNotEmpty)
                          _TypePill(label: tag, color: _typeColor),
                        if (els.isNotEmpty)
                          ...[
                            for (final e in ElementKind.values)
                              if (els.contains(e))
                                _ElementDot(
                                  element: e,
                                  size: 8,
                                ),
                          ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              (() {
                final dpsRow = Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      primary.value,
                      style: TextStyle(
                        fontSize: widget.isTopDps ? 18 : 16,
                        fontWeight: FontWeight.w900,
                        color: primary.color,
                        shadows: widget.isTopDps ? [
                          Shadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ] : null,
                      ),
                    ),
                    if (primary.unit != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        primary.unit!,
                        style: TextStyle(
                          fontSize: widget.isTopDps ? 13 : 12,
                          fontWeight: FontWeight.w700,
                          color: primary.color.withValues(alpha: 0.85),
                          shadows: widget.isTopDps ? [
                            Shadow(
                              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ] : null,
                        ),
                      ),
                    ],
                  ],
                );
                if (widget.isTopDps) {
                  return dpsRow.animate(
                    onPlay: (controller) => controller.repeat(reverse: true),
                  ).scaleXY(end: 1.08, duration: 1000.ms, curve: Curves.easeInOut)
                   .shimmer(delay: 1500.ms, duration: 1200.ms, color: Colors.white.withValues(alpha: 0.55));
                }
                return dpsRow;
              })(),
            ],
          ),
        ),
      ),
    );

    final isS = _quality.toUpperCase() == 'S' || _quality.toUpperCase() == '1S';
    final rawQColor = _quality.isEmpty ? Colors.white24 : QualityBadge.colorFor(_quality);
    final qColor = isS ? const Color(0xFFFFD700) : rawQColor;
    final isHighTier = isS || _quality.toUpperCase() == 'A';

    // Wrap in animated synergy glow overlay when active.
    if (gc == null || glowCtrl == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isS ? const Color(0xFF14120E) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isS 
                  ? const Color(0xFFFFD700) 
                  : qColor.withValues(alpha: isHighTier ? 0.65 : 0.22),
              width: isS ? 1.6 : (isHighTier ? 1.1 : 0.7),
            ),
            boxShadow: isHighTier ? [
              BoxShadow(
                color: qColor.withValues(alpha: isS ? 0.12 : 0.06),
                blurRadius: 6,
                spreadRadius: 0.5,
              )
            ] : null,
          ),
          child: row,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Stack(
        children: [
          SynergyGlowOverlay(
            controller: glowCtrl,
            color: gc,
            effectIndex: _effectIndex,
            radius: 12,
            showBgTint: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isS ? const Color(0xFF14120E) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isS 
                      ? const Color(0xFFFFD700) 
                      : qColor.withValues(alpha: isHighTier ? 0.65 : 0.22),
                  width: isS ? 1.6 : (isHighTier ? 1.1 : 0.7),
                ),
                boxShadow: isHighTier ? [
                  BoxShadow(
                    color: qColor.withValues(alpha: isS ? 0.12 : 0.06),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ] : null,
              ),
              child: row,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  final String label;
  final Color color;
  const _TypePill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
          width: 0.7,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
          height: 1.1,
        ),
      ),
    );
  }
}

class _ElementDot extends StatelessWidget {
  final ElementKind element;
  final double size;

  const _ElementDot({
    required this.element,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: element.color,
        shape: BoxShape.circle,
      ),
    );
  }
}

