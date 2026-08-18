import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/goop_talk_engine.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/gungeoneer.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';
import '../utils/asset_paths.dart';
import '../utils/fast_route.dart';
import '../utils/responsive.dart';
import 'gungeoneer_detail_screen.dart';

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
        final profile = ScreenProfile.of(context);
        // On short screens we collapse the helper text to reclaim vertical
        // space for the grid — the description is nice-to-have, not essential.
        final showDescription = !isMultiplayerPick && !profile.isShort;
        final titleFontSize = profile.isShort ? 16.0 : 18.0;

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
                padding: EdgeInsets.fromLTRB(16, profile.isShort ? 8 : 16, 16, 4),
                child: GoopText(
                  isCoop
                      ? 'Choose Player 2\'s Gungeoneer'
                      : isMultiplayerPick
                          ? 'Choose your character for multiplayer'
                          : 'Choose your Gungeoneer',
                  style: prefs.font.textStyle.copyWith(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (showDescription)
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
                child: _CharacterGrid(
                  gungeoneers: p.allGungeoneers,
                  flair: flair,
                  prefs: prefs,
                  profile: profile,
                  isMultiplayerPick: isMultiplayerPick,
                  isCoop: isCoop,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Grid that computes its cell aspect ratio from the available height so all
/// rows fit without scrolling — the core fix for the overflow/scroll bug on
/// short phones.
class _CharacterGrid extends StatelessWidget {
  final List<Gungeoneer> gungeoneers;
  final ThemeFlair flair;
  final VisualPrefs prefs;
  final ScreenProfile profile;
  final bool isMultiplayerPick;
  final bool isCoop;

  const _CharacterGrid({
    required this.gungeoneers,
    required this.flair,
    required this.prefs,
    required this.profile,
    required this.isMultiplayerPick,
    required this.isCoop,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = gungeoneers.length;
    if (itemCount == 0) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = profile.columnsFor(itemCount);
        // Grid interior padding — tightened on short screens.
        final hPad = 12.0;
        final vPad = profile.isShort ? 8.0 : 12.0;
        final crossSpacing = 8.0;
        final mainSpacing = profile.isShort ? 6.0 : 10.0;

        // Square tiles: aspect ratio = 1.0. The grid fills available space
        // but tiles are always square — compact, solid, 2026 standard.
        final aspect = 1.0;

        return GridView.builder(
          padding: EdgeInsets.fromLTRB(hPad, vPad, hPad, vPad),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: aspect,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: mainSpacing,
          ),
          // The grid is sized to fit — scrolling is unnecessary and indicates
          // a layout bug. NeverScrollable makes that explicit.
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (c, i) {
            final char = gungeoneers[i];
            void onTap() {
              Haptics.selection();
              final run = c.read<RunProvider>();
              if (isMultiplayerPick) {
                Navigator.pop(c, char);
              } else if (isCoop) {
                run.startCoopPlayer(char);
                if (Navigator.canPop(c)) Navigator.pop(c);
              } else {
                run.startNewRun(char);
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
        );
      },
    );
  }
}

/// Unified character card — in-game sprite, tap-to-select. Square tiles
/// with compact, solid visuals. 2026 standard: always show the in-game
/// sprite model, not special card art graphics.
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
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: flair.primary.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // ── In-game sprite fills the square tile ──
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.75,
                    colors: [
                      flair.primary.withValues(alpha: 0.08),
                      flair.primary.withValues(alpha: 0.02),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // In-game GIF sprite — fills the area above the name label.
            // No padding so the sprite scales up to fill the full tile
            // height. The name label at the bottom has its own
            // semi-transparent backing so the sprite reads behind it.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 22, // space for the name label
              child: _buildInGameSprite(),
            ),
            // ── Name label at bottom ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
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
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // ── ? info button — opens Gungeoneer detail screen ──
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  Haptics.selection();
                  Navigator.push(
                    context,
                    fastRoute(GungeoneerDetailScreen(
                      gungeoneer: character,
                    )),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    size: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Always show the in-game sprite GIF. Falls back to the static icon
  /// if no GIF exists. No animated card art — just the raw sprite model.
  /// Uses BoxFit.fitHeight so portrait pixel-art sprites fill the
  /// available height — much bigger than the old BoxFit.contain which
  /// left them tiny in the center of a square tile.
  Widget _buildInGameSprite() {
    final gifPath = gungeoneerGifPath(character.name);
    if (gifPath.isNotEmpty) {
      return Image.asset(
        gifPath,
        fit: BoxFit.fitHeight,
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
        fit: BoxFit.fitHeight,
        filterQuality: FilterQuality.none,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.person, size: 64, color: Colors.white70),
      );
    }
    return const Icon(Icons.person, size: 64, color: Colors.white70);
  }
}
