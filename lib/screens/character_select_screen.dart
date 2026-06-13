import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/run_provider.dart';
import '../models/gungeoneer.dart';
import '../widgets/avatar_aura.dart';

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
            child: Text(
              isCoop
                  ? 'Choose Player 2\'s Gungeoneer'
                  : isMultiplayerPick
                      ? 'Choose your character for multiplayer'
                      : 'Choose your Gungeoneer',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isMultiplayerPick)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                isCoop
                    ? 'Adds a second player to the current run with the character\'s default loadout. Long-press tiles to transfer items between players.'
                    : 'Starts a new run with character\'s default loadout.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
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
  }
}

class _CharacterCard extends StatelessWidget {
  final Gungeoneer character;
  final VoidCallback onTap;
  const _CharacterCard({required this.character, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                color: Colors.white.withValues(alpha: 0.03),
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
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                character.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
