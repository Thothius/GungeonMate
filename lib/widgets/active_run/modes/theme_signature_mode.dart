import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/player.dart';
import '../../../providers/run_provider.dart';
import '../../../services/app_theme.dart';
import '../../../services/goop_talk_engine.dart';
import '../../../utils/asset_paths.dart';
import '../../../utils/fast_route.dart';
import '../../../screens/item_detail_screen.dart';
import '../../game_icon.dart';
import '../depth_tile.dart';
import '../gungeon_meter.dart';
import '../mode_helpers.dart' as mh;
import 'theme_lore.dart';

/// Mode 4 — Theme Signature.
///
/// Adapts its entire layout, decorations, and flavor text to match
/// the active theme. Each theme has a [ThemeLore] entry that drives:
/// - The lore header (title, tagline, quote, accent glyph)
/// - The decorative background painter (embers, frost, sparkles, etc.)
/// - Themed stat labels (COOLNESS → TEMPER for Forge Master, etc.)
/// - The color treatment (reads from the active ThemeFlair)
///
/// The layout is a vertical scroll: lore header → character portrait
/// → interactive meters → gun list → item list. All inventory tiles
/// use DepthTile 2.5D. The decorative painter sits behind everything
/// as a subtle background flourish.
class ThemeSignatureMode extends StatefulWidget {
  final PlayerSlot slot;
  const ThemeSignatureMode({super.key, required this.slot});

  @override
  State<ThemeSignatureMode> createState() => _ThemeSignatureModeState();
}

class _ThemeSignatureModeState extends State<ThemeSignatureMode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _decor;

  @override
  void initState() {
    super.initState();
    _decor = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _decor.dispose();
    super.dispose();
  }

  bool get isMain => widget.slot == PlayerSlot.main;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final state = p.runState;
    final player = isMain ? state.main : state.coop;

    if (player == null || player.character == null) {
      return const Center(child: GoopText('No player'));
    }

    final flair = AppTheme.flair;
    final mode = AppTheme.mode;
    final lore = themeLoreFor(mode);
    final glowColors = mh.synergyGlowColors(p);
    final topDps = mh.topDpsInfo(player, p);
    final labels = lore.statLabels;

    return SafeArea(
      top: false,
      child: Stack(
        children: [
          // Layer 0: decorative background
          if (lore.decor != ThemeDecor.none)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _decor,
                    builder: (_, __) => CustomPaint(
                      painter: _ThemeDecorPainter(
                        decor: lore.decor,
                        t: _decor.value,
                        color: flair.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Layer 1: content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _loreHeader(lore, flair),
                  const SizedBox(height: 16),
                  _characterSection(player, flair),
                  const SizedBox(height: 16),
                  if (isMain) ...[
                    GungeonMeter(
                      value: state.totalCoolness.clamp(0.0, 15.0),
                      isCool: true,
                      color: const Color(0xFF00E5FF),
                      label: labels.coolness ?? 'COOLNESS',
                      onDelta: (d) => p.adjustCoolness(d),
                    ),
                    const SizedBox(height: 10),
                    GungeonMeter(
                      value: state.totalCurse.clamp(0.0, 15.0),
                      isCool: false,
                      color: const Color(0xFFFF3D00),
                      label: labels.curse ?? 'CURSE',
                      onDelta: (d) => p.adjustCurse(d),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _gunSection(player, p, topDps, flair, glowColors, labels),
                  const SizedBox(height: 14),
                  _itemSection(player, flair, glowColors, labels),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Lore header ----------------------------------------------------

  Widget _loreHeader(ThemeLore lore, ThemeFlair flair) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: flair.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: flair.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GoopText(
                lore.accentGlyph,
                style: TextStyle(
                  fontSize: 20,
                  color: flair.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GoopText(
                      lore.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: flair.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    GoopText(
                      lore.tagline,
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              _elementBadge(lore.element, flair),
            ],
          ),
          const SizedBox(height: 8),
          GoopText(
            '"${lore.quote}"',
            style: TextStyle(
              fontSize: 10,
              color: flair.secondary.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _elementBadge(String element, ThemeFlair flair) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: flair.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: flair.primary.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: GoopText(
        element,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: flair.primary.withValues(alpha: 0.7),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // ---- Character section ----------------------------------------------

  Widget _characterSection(Player player, ThemeFlair flair) {
    final char = player.character!;
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: flair.primary.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: flair.primary.withValues(alpha: 0.15),
                blurRadius: 12,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              gungeoneerGifPath(char.name),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.person,
                size: 28,
                color: flair.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoopText(
                char.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: flair.primary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _miniStat('${player.guns.length}', 'GUNS', flair),
                  const SizedBox(width: 12),
                  _miniStat('${player.items.length}', 'ITEMS', flair),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String value, String label, ThemeFlair flair) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoopText(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: flair.primary,
            fontFamily: 'monospace',
          ),
        ),
        GoopText(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.4),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ---- Gun section ----------------------------------------------------

  Widget _gunSection(
    Player player,
    RunProvider p,
    ({String name, double dps}) topDps,
    ThemeFlair flair,
    Map<String, Color> glowColors,
    ThemedStatLabels labels,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('⚔ ${labels.guns ?? "GUNS"}', flair),
        const SizedBox(height: 8),
        if (player.guns.isEmpty)
          _emptyState('No guns loaded', flair)
        else
          ...player.guns.map((g) {
            final isTop = g.name == topDps.name;
            final glow = glowColors[g.name.toLowerCase()];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DepthTile(
                isTopDps: isTop,
                glowColor: glow,
                onTap: () => Navigator.push(
                  context,
                  fastRoute(ItemDetailScreen(gun: g, ownerSlot: widget.slot)),
                ),
                onLongPress: () => mh.promptTileActions(
                  context,
                  slot: widget.slot,
                  gun: g,
                ),
                child: _inventoryRow(
                  g.name,
                  '${mh.effectiveDps(g, p).toStringAsFixed(1)} DPS',
                  g.icon,
                  g.quality,
                  isTop,
                  glow,
                  flair,
                ),
              ),
            );
          }),
      ],
    );
  }

  // ---- Item section ---------------------------------------------------

  Widget _itemSection(
    Player player,
    ThemeFlair flair,
    Map<String, Color> glowColors,
    ThemedStatLabels labels,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('◈ ${labels.items ?? "ITEMS"}', flair),
        const SizedBox(height: 8),
        if (player.items.isEmpty)
          _emptyState('No items equipped', flair)
        else
          ...player.items.map((it) {
            final glow = glowColors[it.name.toLowerCase()];
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DepthTile(
                glowColor: glow,
                onTap: () => Navigator.push(
                  context,
                  fastRoute(
                      ItemDetailScreen(item: it, ownerSlot: widget.slot)),
                ),
                onLongPress: () => mh.promptTileActions(
                  context,
                  slot: widget.slot,
                  item: it,
                ),
                child: _inventoryRow(
                  it.name,
                  it.rechargeTime.isNotEmpty ? it.rechargeTime : '',
                  it.icon,
                  it.quality,
                  false,
                  glow,
                  flair,
                ),
              ),
            );
          }),
      ],
    );
  }

  // ---- Shared widgets -------------------------------------------------

  Widget _sectionHeader(String label, ThemeFlair flair) {
    return Row(
      children: [
        GoopText(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: flair.primary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  flair.primary.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _inventoryRow(
    String name,
    String stat,
    String icon,
    String quality,
    bool isTop,
    Color? glow,
    ThemeFlair flair,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isTop
              ? Colors.amberAccent.withValues(alpha: 0.4)
              : glow != null
                  ? glow.withValues(alpha: 0.25)
                  : flair.primary.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: GameIcon(
              assetPath: icon,
              fallback: Icons.help_outline,
              quality: quality,
              size: 22,
              showRing: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GoopText(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isTop ? Colors.amberAccent : Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (stat.isNotEmpty)
            GoopText(
              stat,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: flair.primary.withValues(alpha: 0.8),
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyState(String message, ThemeFlair flair) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: GoopText(
          message,
          style: TextStyle(
            fontSize: 11,
            color: flair.primary.withValues(alpha: 0.3),
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}

/// Decorative background painter for Theme Signature mode.
/// Draws subtle theme-specific flourishes behind the run data.
class _ThemeDecorPainter extends CustomPainter {
  final ThemeDecor decor;
  final double t;
  final Color color;

  _ThemeDecorPainter({
    required this.decor,
    required this.t,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (decor) {
      case ThemeDecor.embers:
        _paintEmbers(canvas, size);
      case ThemeDecor.frost:
        _paintFrost(canvas, size);
      case ThemeDecor.sparkles:
        _paintSparkles(canvas, size);
      case ThemeDecor.circuits:
        _paintCircuits(canvas, size);
      case ThemeDecor.paws:
        _paintPaws(canvas, size);
      case ThemeDecor.moonlight:
        _paintMoonlight(canvas, size);
      case ThemeDecor.lightning:
        _paintLightning(canvas, size);
      case ThemeDecor.brass:
        _paintBrass(canvas, size);
      case ThemeDecor.blade:
        _paintBlade(canvas, size);
      case ThemeDecor.rift:
        _paintRift(canvas, size);
      case ThemeDecor.powder:
        _paintPowder(canvas, size);
      case ThemeDecor.bone:
        _paintBone(canvas, size);
      case ThemeDecor.tactical:
        _paintTactical(canvas, size);
      case ThemeDecor.custom:
        _paintCustom(canvas, size);
      case ThemeDecor.none:
        break;
    }
  }

  // ---- Embers (rising orange particles) ----
  void _paintEmbers(Canvas canvas, Size size) {
    final rng = math.Random(42);
    for (var i = 0; i < 30; i++) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final y = (baseY - t * 100) % size.height;
      final radius = 1 + rng.nextDouble() * 2;
      final alpha = 0.15 + rng.nextDouble() * 0.15;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  // ---- Frost (drifting ice crystals) ----
  void _paintFrost(Canvas canvas, Size size) {
    final rng = math.Random(7);
    for (var i = 0; i < 20; i++) {
      final x = rng.nextDouble() * size.width;
      final y = (rng.nextDouble() * size.height + t * 30) % size.height;
      final radius = 2 + rng.nextDouble() * 3;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()
          ..color = color.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  // ---- Sparkles (twinkling pastel dots) ----
  void _paintSparkles(Canvas canvas, Size size) {
    final rng = math.Random(99);
    for (var i = 0; i < 25; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final phase = (t * 2 + i * 0.3) % 1.0;
      final alpha = phase < 0.5 ? phase * 0.3 : (1 - phase) * 0.3;
      canvas.drawCircle(
        Offset(x, y),
        1.5,
        Paint()..color = color.withValues(alpha: alpha),
      );
    }
  }

  // ---- Circuits (scrolling horizontal lines) ----
  void _paintCircuits(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 0.8;
    for (var i = 0; i < 8; i++) {
      final y = (i * size.height / 8 + t * 20) % size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  // ---- Paws (drifting paw print shapes) ----
  void _paintPaws(Canvas canvas, Size size) {
    final rng = math.Random(13);
    final paint = Paint()..color = color.withValues(alpha: 0.05);
    for (var i = 0; i < 8; i++) {
      final x = rng.nextDouble() * size.width;
      final y = (rng.nextDouble() * size.height + t * 15) % size.height;
      // Simple paw: 1 big circle + 3 small
      canvas.drawCircle(Offset(x, y), 4, paint);
      canvas.drawCircle(Offset(x - 3, y - 4), 1.5, paint);
      canvas.drawCircle(Offset(x + 3, y - 4), 1.5, paint);
      canvas.drawCircle(Offset(x, y - 5), 1.5, paint);
    }
  }

  // ---- Moonlight (crescent shapes + rays) ----
  void _paintMoonlight(Canvas canvas, Size size) {
    final rng = math.Random(77);
    for (var i = 0; i < 5; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final alpha = 0.04 + (t * 0.03);
      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  // ---- Lightning (occasional arc flashes) ----
  void _paintLightning(Canvas canvas, Size size) {
    final flash = (t * 3) % 1.0;
    if (flash < 0.15) {
      final rng = math.Random(flash.round());
      final x = rng.nextDouble() * size.width;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
      var y = 0.0;
      while (y < size.height) {
        final nextY = y + 20 + rng.nextDouble() * 30;
        final nextX = x + (rng.nextDouble() - 0.5) * 40;
        canvas.drawLine(Offset(x, y), Offset(nextX, nextY), paint);
        y = nextY;
      }
    }
  }

  // ---- Brass (filigree corner decorations) ----
  void _paintBrass(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final r = 30.0;
    // Top-left corner
    canvas.drawArc(Rect.fromLTWH(0, 0, r * 2, r * 2), 0, math.pi / 2, false, paint);
    // Bottom-right corner
    canvas.drawArc(Rect.fromLTWH(size.width - r * 2, size.height - r * 2, r * 2, r * 2),
        math.pi, math.pi / 2, false, paint);
  }

  // ---- Blade (crossed blade silhouettes) ----
  void _paintBlade(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..strokeWidth = 2;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final len = size.width * 0.3;
    canvas.drawLine(
      Offset(cx - len, cy - len),
      Offset(cx + len, cy + len),
      paint,
    );
    canvas.drawLine(
      Offset(cx + len, cy - len),
      Offset(cx - len, cy + len),
      paint,
    );
  }

  // ---- Rift (fractured reality shards) ----
  void _paintRift(Canvas canvas, Size size) {
    final rng = math.Random(333);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 6; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final w = 10 + rng.nextDouble() * 20;
      final h = 30 + rng.nextDouble() * 50;
      final angle = (t * 2 + i) * 0.3;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRect(Rect.fromLTWH(-w / 2, -h / 2, w, h), paint);
      canvas.restore();
    }
  }

  // ---- Powder (falling gunpowder grains) ----
  void _paintPowder(Canvas canvas, Size size) {
    final rng = math.Random(22);
    for (var i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = (rng.nextDouble() * size.height + t * 50) % size.height;
      canvas.drawCircle(
        Offset(x, y),
        0.8,
        Paint()..color = color.withValues(alpha: 0.1),
      );
    }
  }

  // ---- Bone (floating bone fragments) ----
  void _paintBone(Canvas canvas, Size size) {
    final rng = math.Random(666);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 8; i++) {
      final x = rng.nextDouble() * size.width;
      final y = (rng.nextDouble() * size.height + t * 10) % size.height;
      final w = 8 + rng.nextDouble() * 12;
      canvas.drawRect(Rect.fromLTWH(x, y, w, 2), paint);
    }
  }

  // ---- Tactical (grid overlay) ----
  void _paintTactical(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  // ---- Custom (subtle particle dust) ----
  void _paintCustom(Canvas canvas, Size size) {
    final rng = math.Random(1);
    for (var i = 0; i < 15; i++) {
      final x = rng.nextDouble() * size.width;
      final y = (rng.nextDouble() * size.height + t * 20) % size.height;
      canvas.drawCircle(
        Offset(x, y),
        1,
        Paint()..color = color.withValues(alpha: 0.06),
      );
    }
  }

  @override
  bool shouldRepaint(_ThemeDecorPainter old) => old.t != t;
}
