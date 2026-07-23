import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../models/gun.dart';
import '../../models/gungeoneer.dart';
import '../../models/item.dart';
import '../../models/player.dart';
import '../periodic_tile.dart';
import '../../services/goop_talk_engine.dart';

enum StarterKind { guns, items }

/// Empty-state hint shown when a player has no guns or no items in
/// inventory. For most characters it surfaces the *starting loadout*
/// (e.g. The Marine starts with Marine Sidearm) as ghosted, tappable
/// tiles ΓÇö taping a ghost adds that starter to the player's loadout
/// without leaving the screen. Falls back to a plain message for
/// The Paradox (random starter) and any character whose starting list
/// is empty.
class StarterHint extends StatelessWidget {
  final Gungeoneer character;
  final StarterKind kind;
  final PlayerSlot slot;
  final SliverGridDelegate tileGrid;
  final bool wideMode;

  const StarterHint({super.key, 
    required this.character,
    required this.kind,
    required this.slot,
    required this.tileGrid,
    // ignore: unused_element_parameter
    this.wideMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.read<RunProvider>();
    final isGuns = kind == StarterKind.guns;

    // Paradox specifically starts with a *random* loadout, so the hint
    // doesn't apply ΓÇö leave them with a clear message instead of showing
    // 0 ghosts.
    final isParadox = character.name == 'The Paradox';

    // Resolve starter names to actual entities via the indexed lookups.
    // Names that don't resolve (typo, removed item) are silently dropped.
    final List<Gun> starterGuns = isGuns
        ? character.startingGuns
            .map((n) => p.gunByName(n))
            .whereType<Gun>()
            .toList()
        : const [];
    final List<Item> starterItems = !isGuns
        ? character.startingItems
            .map((n) => p.itemByName(n))
            .whereType<Item>()
            .toList()
        : const [];

    final hasStarters = (isGuns ? starterGuns : starterItems).isNotEmpty;

    if (isParadox || !hasStarters) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: GoopText(
                isParadox
                    ? 'The Paradox starts with a random loadout ΓÇö '
                        'add ${isGuns ? "guns" : "items"} as you pick them up.'
                    : isGuns
                        ? 'No guns yet ΓÇö hit ADD to bring in your first.'
                        : 'No items yet ΓÇö pick some up!',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ),
        ),
      );
    }

    final headline = isGuns
        ? '${character.name} usually starts with'
        : 'Plus this passive';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GoopText(
                    headline,
                    style: TextStyle(
                      fontSize: 11.5,
                      letterSpacing: 0.6,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Render starters in the same grid layout as the real loadout
          // so the ghost preview slots into the same visual rhythm ΓÇö the
          // user instantly recognises "this is what a filled grid will
          // look like".
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: tileGrid,
            itemCount: isGuns ? starterGuns.length : starterItems.length,
            itemBuilder: (c, i) {
              final gun = isGuns ? starterGuns[i] : null;
              final it = isGuns ? null : starterItems[i];
              final name = gun?.name ?? it!.name;
              return Opacity(
                opacity: 0.55,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: PeriodicTile(
                        gun: gun,
                        item: it,
                        wideMode: wideMode,
                        onTap: () {
                          // Tile's own _handleTap already fires a light
                          // haptic, so we don't buzz twice. Capture the
                          // messenger *before* mutating the loadout ΓÇö
                          // addGun triggers a rebuild that unmounts this
                          // ghost sub-tree, so looking up the messenger
                          // via `c` afterwards would be fragile.
                          final messenger = ScaffoldMessenger.of(c);
                          if (gun != null) {
                            p.addGun(gun, slot: slot);
                          } else {
                            p.addItem(it!, slot: slot);
                          }
                          messenger.showSnackBar(SnackBar(
                            content: GoopText('Added $name'),
                            duration:
                                const Duration(milliseconds: 1200),
                          ));
                        },
                      ),
                    ),
                    // Tiny "+" badge bottom-centre to differentiate the
                    // ghost preview from a real tile at a glance.
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 13,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
            child: GoopText(
              'Tap a starter to add it, or use the ADD button for anything else.',
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}