import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/goop_talk_engine.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/gungeoneer.dart';
import '../widgets/game_icon.dart';
import '../widgets/quality_badge.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import '../utils/asset_paths.dart';

enum CharSelectMode { solo, coop, multiplayerPick }

class CharacterSelectScreen extends StatelessWidget {
  final CharSelectMode mode;
  const CharacterSelectScreen({
    super.key,
    this.mode = CharSelectMode.solo,
  });

  /// Quick constructor for multiplayer lobby picking.
  const CharacterSelectScreen.multiplayerPick({super.key})
      : mode = CharSelectMode.multiplayerPick;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final isCoop = mode == CharSelectMode.coop;
    final isMultiplayerPick = mode == CharSelectMode.multiplayerPick;

    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        final flair = AppTheme.flair;
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: GoopText(
              isCoop
                  ? 'Add Co-op Player'
                  : isMultiplayerPick
                      ? 'Pick your Gungeoneer'
                      : 'Gungeon Mate',
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: GoopText(
                  isCoop
                      ? 'Choose Player 2\'s Gungeoneer'
                      : isMultiplayerPick
                          ? 'Choose your character for multiplayer'
                          : 'Choose your Gungeoneer',
                  style: prefs.font.textStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!isMultiplayerPick)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: GoopText(
                    isCoop
                        ? 'Adds a second player to the current run with the character\'s default loadout. Long-press tiles to transfer items between players.'
                        : 'Starts a new run with character\'s default loadout.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.35,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: flair.primary.withValues(alpha: 0.12),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: isMultiplayerPick ? 0.62 : 0.64,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: p.allGungeoneers.length,
                  itemBuilder: (c, i) {
                    final char = p.allGungeoneers[i];
                    void onTap() {
                      Haptics.selection();
                      if (isMultiplayerPick) {
                        Navigator.pop(c, char);
                      } else if (isCoop) {
                        p.startCoopPlayer(char);
                        if (Navigator.canPop(c)) Navigator.pop(c);
                      } else {
                        p.startNewRun(char);
                        if (Navigator.canPop(c)) Navigator.pop(c);
                      }
                    }
                    final card = isMultiplayerPick
                        ? _SimpleCharacterCard(
                            character: char,
                            flair: flair,
                            prefs: prefs,
                            onTap: onTap,
                          )
                        : _CharacterCard(
                            character: char,
                            flair: flair,
                            prefs: prefs,
                            provider: p,
                            onTap: onTap,
                          );
                    return card.animate().fadeIn(
                      duration: 300.ms,
                      delay: (i * 60).ms,
                    ).slide(
                      begin: const Offset(0, 0.08),
                      duration: 300.ms,
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Simple card for MP pick — flip avatar, confirm button to select.
class _SimpleCharacterCard extends StatefulWidget {
  final Gungeoneer character;
  final ThemeFlair flair;
  final VisualPrefs prefs;
  final VoidCallback onTap;

  const _SimpleCharacterCard({
    required this.character,
    required this.flair,
    required this.prefs,
    required this.onTap,
  });

  @override
  State<_SimpleCharacterCard> createState() => _SimpleCharacterCardState();
}

class _SimpleCharacterCardState extends State<_SimpleCharacterCard>
    with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  late final AnimationController _flipCtrl;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      duration: 500.ms,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    Haptics.selection();
    setState(() => _isFlipped = !_isFlipped);
    if (_isFlipped) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final flair = widget.flair;
    final prefs = widget.prefs;
    final char = widget.character;
    final gunList = char.startingGuns.take(2).join(', ');

    return Card(
      color: const Color(0xFF1E1E22),
      elevation: 6,
      shadowColor: flair.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: flair.primary.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          flair.primary.withValues(alpha: 0.1),
                          flair.primary.withValues(alpha: 0.02),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleFlip,
                  child: AnimatedBuilder(
                    animation: _flipCtrl,
                    builder: (context, _) {
                      final angle = _flipCtrl.value * math.pi;
                      final showFront = angle < math.pi / 2;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: showFront
                            ? _buildCardArt()
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(math.pi),
                                child: _buildInGameSprite(),
                              ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: flair.primary.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gps_fixed, size: 9, color: flair.primary.withValues(alpha: 0.8)),
                        const SizedBox(width: 2),
                        Text(
                          '${char.startingGuns.length}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: flair.primary.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(Icons.inventory_2_outlined, size: 9, color: Colors.white.withValues(alpha: 0.6)),
                        const SizedBox(width: 2),
                        Text(
                          '${char.startingItems.length}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFlipped ? Icons.flip_to_front : Icons.flip_to_back,
                      size: 12,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            decoration: BoxDecoration(
              color: flair.primary.withValues(alpha: 0.08),
              border: Border(
                top: BorderSide(color: flair.primary.withValues(alpha: 0.15), width: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GoopText(
                  char.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: prefs.font.textStyle.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                if (gunList.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  GoopText(
                    gunList,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Colors.white.withValues(alpha: 0.45),
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildSelectButton(flair),
        ],
      ),
    );
  }

  Widget _buildSelectButton(ThemeFlair flair) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: widget.onTap,
          icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
          label: const GoopText(
            'SELECT',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: flair.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardArt() {
    final animPath = gungeoneerAnimatedCardPath(widget.character.name);
    if (animPath.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          animPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
        ),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildInGameSprite() {
    final char = widget.character;
    final gifPath = gungeoneerGifPath(char.name);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: gifPath.isNotEmpty
          ? Image.asset(
              gifPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Image.asset(
                char.icon,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 64, color: Colors.white70),
              ),
            )
          : (char.icon.startsWith('assets/')
              ? Image.asset(
                  char.icon,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 64, color: Colors.white70),
                )
              : const Icon(Icons.person, size: 64, color: Colors.white70)),
    );
  }

  Widget _buildFallbackIcon() {
    final char = widget.character;
    if (char.icon.startsWith('assets/')) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          char.icon,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 64, color: Colors.white70),
        ),
      );
    }
    return const Icon(Icons.person, size: 64, color: Colors.white70);
  }
}

/// Interactive card for solo/coop — flip avatar to see in-game sprite,
/// collapsible starting items panel.
class _CharacterCard extends StatefulWidget {
  final Gungeoneer character;
  final ThemeFlair flair;
  final VisualPrefs prefs;
  final RunProvider provider;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.flair,
    required this.prefs,
    required this.provider,
    required this.onTap,
  });

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard>
    with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  bool _itemsExpanded = false;
  late final AnimationController _flipCtrl;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      duration: 500.ms,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    Haptics.selection();
    setState(() => _isFlipped = !_isFlipped);
    if (_isFlipped) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
  }

  void _toggleItems() {
    Haptics.selection();
    setState(() => _itemsExpanded = !_itemsExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final flair = widget.flair;
    final prefs = widget.prefs;
    final char = widget.character;

    return Card(
      color: const Color(0xFF1E1E22),
      elevation: 6,
      shadowColor: flair.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: flair.primary.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
        children: [
          // --- Flip image area ---
          // Fixed-height image area instead of Expanded to prevent
          // overflow when the items panel expands.
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                // Gradient background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 0.8,
                        colors: [
                          flair.primary.withValues(alpha: 0.1),
                          flair.primary.withValues(alpha: 0.02),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Flip content
                GestureDetector(
                  onTap: _toggleFlip,
                  child: AnimatedBuilder(
                    animation: _flipCtrl,
                    builder: (context, _) {
                      final angle = _flipCtrl.value * math.pi;
                      final showFront = angle < math.pi / 2;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: showFront
                            ? _buildCardArt()
                            : Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()..rotateY(math.pi),
                                child: _buildInGameSprite(),
                              ),
                      );
                    },
                  ),
                ),
                // Count badges
                Positioned(
                  top: 8,
                  right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: flair.primary.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed, size: 9, color: flair.primary.withValues(alpha: 0.8)),
                          const SizedBox(width: 2),
                          Text(
                            '${char.startingGuns.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: flair.primary.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.inventory_2_outlined, size: 9, color: Colors.white.withValues(alpha: 0.6)),
                          const SizedBox(width: 2),
                          Text(
                            '${char.startingItems.length}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Flip hint icon
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isFlipped ? Icons.flip_to_front : Icons.flip_to_back,
                        size: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // --- Name bar ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              decoration: BoxDecoration(
                color: flair.primary.withValues(alpha: 0.08),
                border: Border(
                  top: BorderSide(color: flair.primary.withValues(alpha: 0.15), width: 0.5),
                ),
              ),
              child: GoopText(
                char.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: prefs.font.textStyle.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),
            // --- Collapsible starting items panel ---
            InkWell(
              onTap: _toggleItems,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _itemsExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 14,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    GoopText(
                      'STARTING LOADOUT',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white54,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_itemsExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: _buildStartingItems(),
              ),
            // --- Select button ---
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: widget.onTap,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
                  label: const GoopText(
                    'SELECT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: flair.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      );
  }

  Widget _buildCardArt() {
    final char = widget.character;
    final animPath = gungeoneerAnimatedCardPath(char.name);
    if (animPath.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          animPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
        ),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildInGameSprite() {
    final char = widget.character;
    final gifPath = gungeoneerGifPath(char.name);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: gifPath.isNotEmpty
          ? Image.asset(
              gifPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => Image.asset(
                char.icon,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 64, color: Colors.white70),
              ),
            )
          : (char.icon.startsWith('assets/')
              ? Image.asset(
                  char.icon,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 64, color: Colors.white70),
                )
              : const Icon(Icons.person, size: 64, color: Colors.white70)),
    );
  }

  Widget _buildFallbackIcon() {
    final char = widget.character;
    if (char.icon.startsWith('assets/')) {
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Image.asset(
          char.icon,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 64, color: Colors.white70),
        ),
      );
    }
    return const Icon(Icons.person, size: 64, color: Colors.white70);
  }

  Widget _buildStartingItems() {
    final char = widget.character;
    final provider = widget.provider;

    // Look up actual gun/item objects from provider data
    final guns = provider.allGuns
        .where((g) => char.startingGuns.contains(g.name))
        .toList();
    final items = provider.allItems
        .where((i) => char.startingItems.contains(i.name))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (guns.isNotEmpty) ...[
          _buildItemRow('Guns', guns.map((g) => _EntityChip(name: g.name, iconPath: g.icon, quality: g.quality)).toList()),
          const SizedBox(height: 4),
        ],
        if (items.isNotEmpty) ...[
          _buildItemRow('Items', items.map((i) => _EntityChip(name: i.name, iconPath: i.icon, quality: i.quality)).toList()),
        ],
      ],
    );
  }

  Widget _buildItemRow(String label, List<_EntityChip> chips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoopText(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w900,
            color: Colors.white38,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: chips.map((c) => c.build(widget.flair)).toList(),
        ),
      ],
    );
  }
}

class _EntityChip {
  final String name;
  final String iconPath;
  final String quality;

  _EntityChip({required this.name, required this.iconPath, required this.quality});

  Widget build(ThemeFlair flair) {
    return Tooltip(
      message: name,
      preferBelow: false,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: QualityBadge.colorFor(quality).withValues(alpha: 0.4),
            width: 1.0,
          ),
        ),
        child: GameIcon(
          assetPath: iconPath,
          quality: quality,
          size: 28,
          showRing: false,
        ),
      ),
    );
  }
}
