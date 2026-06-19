import 'package:flutter/material.dart';
import '../services/goop_talk_engine.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/gungeoneer.dart';
import '../widgets/avatar_aura.dart';
import '../services/app_theme.dart';

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
          appBar: AppBar(
            title: Text(
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Text(
                    isCoop
                        ? 'Adds a second player to the current run with the character\'s default loadout. Long-press tiles to transfer items between players.'
                        : 'Starts a new run with character\'s default loadout.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.65),
                      height: 1.35,
                    ),
                  ),
                ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: p.allGungeoneers.length,
                  itemBuilder: (c, i) => _CharacterCard(
                    character: p.allGungeoneers[i],
                    flair: flair,
                    prefs: prefs,
                    onTap: () {
                      if (isMultiplayerPick) {
                        // Return character for multiplayer lobby
                        Navigator.pop(c, p.allGungeoneers[i]);
                      } else if (isCoop) {
                        p.startCoopPlayer(p.allGungeoneers[i]);
                        if (Navigator.canPop(c)) Navigator.pop(c);
                      } else {
                        p.startNewRun(p.allGungeoneers[i]);
                        if (Navigator.canPop(c)) Navigator.pop(c);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
    return Card(
      color: const Color(0xFF1E1E22),
      elevation: 3,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: flair.primary.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                color: Colors.white.withValues(alpha: 0.02),
                padding: const EdgeInsets.all(14),
                child: LayoutBuilder(
                  builder: (ctx, box) {
                    // Square aura sized to the available area. Card's
                    // aspect + padding keeps box.maxWidth close to the
                    // card width; take shortest side so the aura stays
                    // pixel-perfect square on any grid configuration.
                    final side = box.biggest.shortestSide.clamp(40.0, 120.0);
                    return AvatarAura(
                      size: side,
                      borderRadius: 10,
                      speedScale: 1.4, // calmer when 4+ tile the grid
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Transform.scale(
                          scale: 1.5,
                          child: character.icon.startsWith('assets/')
                              ? Image.asset(
                                  character.icon,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.none,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.person,
                                    size: 56,
                                    color: Colors.white70,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 56,
                                  color: Colors.white70,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              color: flair.primary.withValues(alpha: 0.12),
              child: GoopText(
                character.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: prefs.font.textStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
