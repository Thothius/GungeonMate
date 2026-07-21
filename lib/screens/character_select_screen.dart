import 'package:flutter/material.dart';
import '../services/goop_talk_engine.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/gungeoneer.dart';
import '../widgets/avatar_aura.dart';
import '../widgets/scale_button.dart';
import '../services/app_theme.dart';
import '../services/haptics.dart';

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
                  child: Text(
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
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: p.allGungeoneers.length,
                  itemBuilder: (c, i) => _CharacterCard(
                    character: p.allGungeoneers[i],
                    flair: flair,
                    prefs: prefs,
                    onTap: () {
                      Haptics.selection();
                      if (isMultiplayerPick) {
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
    return ScaleButton(
      onTap: onTap,
      enableHaptics: false,
      child: Card(
        color: const Color(0xFF1E1E22),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: flair.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          flair.primary.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: LayoutBuilder(
                      builder: (ctx, box) {
                        final side = box.biggest.shortestSide.clamp(40.0, 120.0);
                        return AvatarAura(
                          size: side,
                          borderRadius: 10,
                          speedScale: 1.4,
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
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed, size: 8, color: flair.primary.withValues(alpha: 0.7)),
                          const SizedBox(width: 2),
                          Text(
                            '${character.startingGuns.length}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: flair.primary.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.inventory_2_outlined, size: 8, color: Colors.white.withValues(alpha: 0.5)),
                          const SizedBox(width: 2),
                          Text(
                            '${character.startingItems.length}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
              decoration: BoxDecoration(
                color: flair.primary.withValues(alpha: 0.1),
                border: Border(
                  top: BorderSide(color: flair.primary.withValues(alpha: 0.15), width: 0.5),
                ),
              ),
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
