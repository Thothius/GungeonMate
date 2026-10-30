part of '../periodic_tile.dart';

// Tile state + logic extracted from _PeriodicTileState (Phase 5i) —
// same library; on-clause gives setState/context/widget/mounted/vsync.

mixin _PeriodicTileLogic on TickerProviderStateMixin<PeriodicTile> {
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
  static const Duration _holdDuration = Duration(milliseconds: 200);

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
    final nameChanged =
        oldWidget.gun?.name != widget.gun?.name ||
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

  bool get isGun => widget.gun != null;

  String get _name => widget.gun?.name ?? widget.item?.name ?? '';

  String get _quality => widget.gun?.quality ?? widget.item?.quality ?? '';

  String get _iconPath => widget.gun?.icon ?? widget.item?.icon ?? '';

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
        final hasP1 = p.runState.main.items.any(
          (i) => i.name.toLowerCase() == 'ser junkan',
        );
        final hasCoop =
            p.runState.coop?.items.any(
              (i) => i.name.toLowerCase() == 'ser junkan',
            ) ??
            false;
        final player =
            hasCoop && !hasP1 ? (p.runState.coop ?? Player()) : p.runState.main;
        final junkCount =
            player.items.where((i) => i.name.toLowerCase() == 'junk').length;
        final hasGoldJunk = player.items.any(
          (i) => i.name.toLowerCase() == 'gold junk',
        );
        if (hasGoldJunk) return 'MECHA';
        switch (junkCount) {
          case 0:
            return 'PEASANT';
          case 1:
            return 'SQUIRE';
          case 2:
            return 'HEDGE';
          case 3:
            return 'KNIGHT';
          case 4:
            return 'LIEUT';
          case 5:
            return 'CMDR';
          case 6:
            return 'HOLY';
          default:
            return 'ANGEL';
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

  /// Compact formatter for the periodic tile stat badges.
  /// Produces short, readable labels that always fit:
  ///   "600 dmg"      → "600d"
  ///   "3 seconds"    → "3s"
  ///   "10 seconds"   → "10s"
  ///   "Cannot be used" → "—"
  ///   "Room cleared" → "room"
  ///   "Single-Use"   → "1use"
  ///   "None"         → "—"
  String _compactStat(String raw) {
    if (raw.isEmpty) return '';
    var s = raw.trim();
    // Strip parenthetical and slash suffixes first
    if (s.contains('(')) s = s.split('(').first.trim();
    if (s.contains('/')) s = s.split('/').first.trim();
    final lower = s.toLowerCase();
    // Unusable / none
    if (lower.contains('cannot') || lower == 'none' || lower.contains('n/a')) {
      return '—';
    }
    // "<N> dmg" → "<N>d"
    final dmgMatch = RegExp(
      r'^(\d+)\s*dmg',
      caseSensitive: false,
    ).firstMatch(s);
    if (dmgMatch != null) return '${dmgMatch.group(1)}d';
    // "<N> kills" → "<N>k"
    final killMatch = RegExp(
      r'^(\d+)\s*kill',
      caseSensitive: false,
    ).firstMatch(s);
    if (killMatch != null) return '${killMatch.group(1)}k';
    // "<N> seconds" → "<N>s"
    final secMatch = RegExp(
      r'^([\d.]+)\s*sec',
      caseSensitive: false,
    ).firstMatch(s);
    if (secMatch != null) {
      final n = double.tryParse(secMatch.group(1)!) ?? 0;
      return n == n.roundToDouble() ? '${n.toInt()}s' : '${n}s';
    }
    // "Room cleared" / "Per room" → "room"
    if (lower.contains('room')) return 'room';
    // "Single-Use" / "Single use" → "1use"
    if (lower.contains('single')) return '1use';
    // Fallback: truncate at 5 chars
    if (s.length > 5) s = s.substring(0, 5).trim();
    return s;
  }

  /// Builds the bottom-center stats badge for active items on the periodic
  /// grid. Shows RCHRG (recharge) and DUR (duration) side by side, mirroring
  /// the gun DPS/RANGE pattern. Passives/companions without recharge fall
  /// back to the legacy single corner badge.
  Widget _buildItemStatsBadge() {
    final it = widget.item!;
    final sf = Responsive.factor(context);

    // Ser Junkan uses the corner badge (special rank text).
    if (it.name.toLowerCase() == 'ser junkan') return _buildLegacyItemBadge();

    final recharge = _compactStat(it.rechargeTime);
    final duration = _compactStat(it.duration);

    // No recharge at all → nothing to show (passive/companion).
    if (recharge.isEmpty) return const SizedBox.shrink();

    final rechargeBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoopText(
            recharge,
            style: TextStyle(
              fontSize: 10.5 * sf,
              fontWeight: FontWeight.w900,
              color: Colors.orangeAccent,
              height: 1.1,
            ),
          ),
          const SizedBox(width: 1),
          Icon(
            Icons.battery_charging_full_rounded,
            size: 8 * sf,
            color: Colors.orangeAccent.withValues(alpha: 0.8),
          ),
        ],
      ),
    );

    final durationBadge =
        duration.isEmpty
            ? const SizedBox.shrink()
            : Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GoopText(
                    duration,
                    style: TextStyle(
                      fontSize: 10.5 * sf,
                      fontWeight: FontWeight.w700,
                      color: Colors.lightBlueAccent,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Icon(
                    Icons.schedule_rounded,
                    size: 8 * sf,
                    color: Colors.lightBlueAccent.withValues(alpha: 0.8),
                  ),
                ],
              ),
            );

    // Single FittedBox wraps both badges so they scale together as a
    // unit — maintaining relative proportions and never clipping.
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            rechargeBadge,
            if (durationBadge is! SizedBox) ...[
              const SizedBox(width: 3),
              durationBadge,
            ],
          ],
        ),
      ),
    );
  }

  /// Legacy single-badge fallback for items that don't use the RCHRG/DUR
  /// layout (e.g. Ser Junkan rank text, isTopDps shimmer).
  Widget _buildLegacyItemBadge() {
    final sf = Responsive.factor(context);
    if (_corner.isEmpty) return const SizedBox.shrink();
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      decoration: BoxDecoration(
        color:
            widget.isTopDps
                ? const Color(0xFFFFD700).withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(4),
        border:
            widget.isTopDps
                ? Border.all(color: const Color(0xFFFFD700), width: 1)
                : null,
      ),
      child: GoopText(
        _corner,
        style: TextStyle(
          fontSize: 10.5 * sf,
          fontWeight: FontWeight.w900,
          color: widget.isTopDps ? const Color(0xFFFFD700) : Colors.white,
          height: 1.1,
        ),
      ),
    );
    if (widget.isTopDps) {
      return badge
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(end: 1.08, duration: 1000.ms, curve: Curves.easeInOut)
          .shimmer(
            delay: 1500.ms,
            duration: 1200.ms,
            color: Colors.white.withValues(alpha: 0.5),
          );
    }
    return badge;
  }

  /// Elemental effect icons for the tile — shown top-right, max 3.
  /// Delegates detection to [ElementalTagger] so both guns *and* items
  /// surface the same badges (e.g. Frost Bullets shows a freeze icon,
  /// Shock Rounds shows an electric icon). Order follows the enum
  /// declaration so a given loadout always renders indicators in a
  /// stable order.
  List<({IconData icon, Color color, String tooltip})> get _elements {
    final Set<ElementKind> els =
        widget.gun != null
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
}
