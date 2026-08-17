import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/goop_talk_engine.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/gungeoneer.dart';
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: isMultiplayerPick ? 0.52 : 0.54,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 10,
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
                    final card = _CharacterCard(
                      character: char,
                      flair: flair,
                      prefs: prefs,
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

/// Unified character card — static art, tap-to-select.
class _CharacterCard extends StatelessWidget {
  final Gungeoneer character;
  final ThemeFlair flair;
  final VisualPrefs prefs;
  final VoidCallback onTap;

  const _CharacterCard({
    required this.character,
    required this.flair,
    required this.prefs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final char = character;
    return Card(
      color: AppTheme.flair.card,
      elevation: 4,
      shadowColor: flair.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: flair.primary.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
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
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Transform.scale(
                      scale: 1.1,
                      alignment: Alignment.bottomCenter,
                      child: _buildCardArt(),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(4, 5, 4, 6),
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
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardArt() {
    final animPath = gungeoneerAnimatedCardPath(character.name);
    if (animPath.isNotEmpty) {
      return Image.asset(
        animPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => _buildFallbackIcon(),
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    final char = character;
    if (char.icon.startsWith('assets/')) {
      return Image.asset(
        char.icon,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 96, color: Colors.white70),
      );
    }
    return const Icon(Icons.person, size: 96, color: Colors.white70);
  }
}
