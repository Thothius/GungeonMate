import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/multiplayer_messages.dart';
import '../../models/player.dart';
import '../../providers/run_provider.dart';
import '../../services/multiplayer_session.dart';
import '../../services/goop_talk_engine.dart';
import '../../screens/character_select_screen.dart';
import '../../screens/shrine_picker_screen.dart';
import '../../utils/fast_route.dart';
import 'run_log_screen.dart';

class RunTab extends StatefulWidget {
  const RunTab({super.key});

  @override
  State<RunTab> createState() => RunTabState();
}

class RunTabState extends State<RunTab> {
  void _addCoopPlayer(BuildContext context, RunProvider p) {
    final cultist = p.gungeoneerByName('The Cultist') ?? p.gungeoneerByName('Cultist');
    if (cultist != null) {
      p.startCoopPlayer(cultist);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: GoopText('${cultist.name} joined as Player 2!'),
        duration: const Duration(milliseconds: 1400),
        action: SnackBarAction(
          label: 'CHANGE',
          onPressed: () => Navigator.push(
            context,
            fastRoute(const CharacterSelectScreen(mode: CharSelectMode.coop)),
          ),
        ),
      ));
      return;
    }
    Navigator.push(
      context,
      fastRoute(const CharacterSelectScreen(mode: CharSelectMode.coop)),
    );
  }

  void _confirmRemoveCoop(BuildContext context, RunProvider p) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const GoopText('Remove Player 2 (Co-op)?'),
        content: const GoopText('Their loadout will be discarded. Items are not transferred to Player 1.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const GoopText('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () {
              p.endCoopPlayer();
              Navigator.pop(c);
            },
            child: const GoopText('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmClearInventory(BuildContext context, RunProvider p, PlayerSlot slot) {
    final player = slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
    if (player == null || player.character == null) return;
    final name = player.character!.name;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
        title: GoopText("Clear $name's inventory?"),
        content: const GoopText(
          'Removes all guns and items except their starter loadout. '
          'Coolness, curse, and shrine status are unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const GoopText('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () {
              p.clearInventory(slot: slot);
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: GoopText("$name's items cleared!"),
                duration: const Duration(seconds: 1),
              ));
            },
            child: const GoopText('Clear Inventory'),
          ),
        ],
      ),
    );
  }

  void _confirmEndRun(BuildContext context, RunProvider p) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.warning_rounded, color: Colors.redAccent),
        title: const GoopText('End Run?'),
        content: const GoopText('This resets the current active run completely and returns you to the character select screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const GoopText('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade900),
            onPressed: () async {
              final session = context.read<MultiplayerSession>();
              Navigator.pop(c);
              if (session.isActive) {
                await session.notifyEndRunAndCancel();
                if (session.myRole == MpRole.main) {
                  p.endRun();
                }
              } else {
                p.endRun();
              }
            },
            child: const GoopText('End Run'),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveMp(BuildContext context, MultiplayerSession session) {
    final isSidekick = session.myRole == MpRole.sidekick;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.bluetooth_disabled,
            color: Colors.lightBlueAccent),
        title: const GoopText('Leave Multiplayer?'),
        content: GoopText(
          isSidekick
              ? 'You will disconnect from the host. Your inventory will be restored to your pre-MP state.'
              : 'You will disconnect and end the multiplayer session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const GoopText('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent.withValues(alpha: 0.15),
                foregroundColor: Colors.lightBlueAccent),
            onPressed: () {
              session.cancel();
              Navigator.pop(c);
            },
            child: const GoopText('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final hasCoop = p.runState.hasCoop;
    final player1Name = p.runState.main.character?.name ?? 'Player 1';
    final player2Name = p.runState.coop?.character?.name ?? 'Player 2';
    final mpSession = context.watch<MultiplayerSession>();
    final mpActive = mpSession.isActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Multiplayer & Co-op
          _sectionHeader('MULTIPLAYER & CO-OP'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GoopText(
                        hasCoop ? 'PLAYER 2 ACTIVE' : 'SOLO PLAYER ACTIVE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: hasCoop ? Colors.pinkAccent : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GoopText(
                        hasCoop
                            ? 'Drop-in Gungeoneer: $player2Name'
                            : 'Play with a friend by adding the co-op Cultist helper!',
                        style: const TextStyle(fontSize: 11, color: Colors.white54, height: 1.3),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: hasCoop ? () => _confirmRemoveCoop(context, p) : () => _addCoopPlayer(context, p),
                  style: FilledButton.styleFrom(
                    backgroundColor: hasCoop ? Colors.red.withValues(alpha: 0.15) : Colors.pinkAccent.withValues(alpha: 0.15),
                    foregroundColor: hasCoop ? Colors.redAccent : Colors.pinkAccent,
                    side: BorderSide(color: hasCoop ? Colors.redAccent : Colors.pinkAccent),
                  ),
                  child: GoopText(hasCoop ? 'Remove P2' : 'Add Co-op'),
                ),
              ],
            ),
          ),
          if (mpActive) ...[
            const SizedBox(height: 10),
            _utilTile(
              title: 'Save MP Session',
              subtitle: 'Persist current multiplayer state for reconnection.',
              icon: Icons.save_outlined,
              color: Colors.greenAccent,
              onTap: () {
                unawaited(mpSession.saveCurrentSession().then((_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: GoopText('Run saved'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }).catchError((e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: GoopText('Failed to save session: $e'),
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }));
              },
            ),
            if (mpSession.myRole == MpRole.sidekick)
              _utilTile(
                title: 'Leave Multiplayer',
                subtitle: 'Disconnect from the host and return to solo play.',
                icon: Icons.bluetooth_disabled,
                color: Colors.lightBlueAccent,
                onTap: () => _confirmLeaveMp(context, mpSession),
              ),
          ],
          const SizedBox(height: 12),

          // Inventory Maintenance
          _sectionHeader('INVENTORY MAINTENANCE'),
          _utilTile(
            title: 'Reset $player1Name Items',
            subtitle: 'Wipes P1 loadout back to default starter gear.',
            icon: Icons.restart_alt_rounded,
            color: Colors.cyanAccent,
            onTap: () => _confirmClearInventory(context, p, PlayerSlot.main),
          ),
          if (hasCoop)
            _utilTile(
              title: 'Reset $player2Name Items',
              subtitle: 'Wipes Co-op loadout back to default starter gear.',
              icon: Icons.restart_alt_rounded,
              color: Colors.pinkAccent,
              onTap: () => _confirmClearInventory(context, p, PlayerSlot.coop),
            ),
          const SizedBox(height: 12),

          // Gameplay Actions
          _sectionHeader('GAMEPLAY ACTIONS'),
          _utilTile(
            title: 'Use Shrine',
            subtitle: 'Apply a shrine effect to the active player.',
            icon: Icons.temple_buddhist,
            color: Colors.amber,
            onTap: () => Navigator.push(
              context,
              fastRoute(const ShrinePickerScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // Run Data
          _sectionHeader('RUN DATA'),
          _utilTile(
            title: 'View Event History',
            subtitle: 'See all pickups, stat changes, shrines, synergies & manual actions.',
            icon: Icons.history_edu_rounded,
            color: const Color(0xFFFFD740),
            onTap: () => Navigator.push(
              context,
              fastRoute(const RunLogScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // Core Actions
          _sectionHeader('CORE ACTIONS'),
          _utilTile(
            title: 'End Active Run',
            subtitle: 'Resets the current session. WARNING: Wipes all active passive logging.',
            icon: Icons.cancel_presentation_rounded,
            color: Colors.redAccent,
            onTap: () => _confirmEndRun(context, p),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: GoopText(
        title,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Colors.white38, letterSpacing: 0.6),
      ),
    );
  }

  Widget _utilTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        onTap: onTap,
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, color: color, size: 20),
        title: GoopText(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
        subtitle: GoopText(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.white38),
      ),
    );
  }
}