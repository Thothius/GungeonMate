import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/multiplayer_messages.dart';
import '../../models/player.dart';
import '../../providers/run_provider.dart';
import '../../services/app_theme.dart';
import '../../services/multiplayer_session.dart';
import '../../services/haptics.dart';
import '../../services/goop_talk_engine.dart';
import '../../screens/character_select_screen.dart';
import '../../screens/shrine_picker_screen.dart';
import '../../utils/fast_route.dart';
import '../active_run/active_run_helpers.dart';
import 'debug_tab.dart';
import 'run_log_screen.dart';

/// Combined Run + App settings tab.
/// Replaces the old separate RunTab + AppTab with a single compact
/// 2-column grid of action tiles + the dialogue card.
class CombinedRunAppTab extends StatefulWidget {
  const CombinedRunAppTab({super.key});

  @override
  State<CombinedRunAppTab> createState() => _CombinedRunAppTabState();
}

class _CombinedRunAppTabState extends State<CombinedRunAppTab> {
  // ── Confirm dialogs (lifted from old RunTab + AppTab) ──────────────

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

  Future<void> _confirmResetAppData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.restart_alt, color: Colors.deepOrange, size: 32),
        title: const GoopText('Reset All App Data?'),
        content: const GoopText(
          'This permanently erases ALL saved data:\n\n'
          '• Active run & inventory\n'
          '• Favourites\n'
          '• Theme & visual preferences\n'
          '• Special weapon upgrades\n'
          '• Multiplayer session data\n\n'
          'The app will restart. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const GoopText('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () => Navigator.pop(c, true),
            child: const GoopText('RESET EVERYTHING'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      fastRoute(const CharacterSelectScreen()),
      (_) => false,
    );
  }

  // ── Changelog dialog (lifted from old AppTab) ──────────────────────

  void _showChangelogDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F0F12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF332225), width: 1.5),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_edu_rounded, color: Color(0xFFFFD54F), size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: GoopText(
                        'CHANGELOG',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: FutureBuilder<String>(
                      future: DefaultAssetBundle.of(context).loadString('assets/data/changelog.json'),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.cyanAccent)));
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const GoopText('Error loading changelog.', style: TextStyle(color: Colors.white24, fontSize: 11));
                        }
                        try {
                          final List<dynamic> data = json.decode(snapshot.data!);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: data.map((v) {
                              final String version = v['version'] ?? '';
                              final String title = v['title'] ?? '';
                              final List<dynamic> items = v['items'] ?? [];
                              return _changelogGroup('$title ($version)', items.map((i) => i.toString()).toList());
                            }).toList(),
                          );
                        } catch (e) {
                          return const GoopText('Failed to parse changelog.', style: TextStyle(color: Colors.white24, fontSize: 11));
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _changelogGroup(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoopText(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    Expanded(child: GoopText(it, style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.25))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
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
          // ── Dialogue card (full-width, has interactive controls) ──
          _buildDialogueCard(flair),
          const SizedBox(height: 16),

          // ── MP & Co-op status bar (slim full-width) ──
          _buildMpStatusBar(context, p, hasCoop, player2Name, mpActive),
          const SizedBox(height: 16),

          // ── RUN SESSION grid ──
          _groupLabel('RUN SESSION'),
          _buildGrid([
            _TileData(
              icon: hasCoop ? Icons.remove_circle_outline : Icons.person_add_alt_1,
              label: hasCoop ? 'Remove P2' : 'Add Co-op',
              color: hasCoop ? Colors.redAccent : Colors.pinkAccent,
              onTap: () => hasCoop ? _confirmRemoveCoop(context, p) : _addCoopPlayer(context, p),
            ),
            _TileData(
              icon: Icons.temple_buddhist,
              label: 'Use Shrine',
              color: Colors.amber,
              onTap: () => Navigator.push(context, fastRoute(const ShrinePickerScreen())),
            ),
            _TileData(
              icon: Icons.history_edu_rounded,
              label: 'Event Log',
              color: const Color(0xFFFFD740),
              onTap: () => Navigator.push(context, fastRoute(const RunLogScreen())),
            ),
            if (mpActive)
              _TileData(
                icon: Icons.save_outlined,
                label: 'Save MP',
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
            if (mpActive && mpSession.myRole == MpRole.sidekick)
              _TileData(
                icon: Icons.bluetooth_disabled,
                label: 'Leave MP',
                color: Colors.lightBlueAccent,
                onTap: () => _confirmLeaveMp(context, mpSession),
              ),
          ]),
          const SizedBox(height: 16),

          // ── INVENTORY & DATA grid ──
          _groupLabel('INVENTORY & DATA'),
          _buildGrid([
            _TileData(
              icon: Icons.restart_alt_rounded,
              label: 'Reset $player1Name',
              color: Colors.cyanAccent,
              onTap: () => confirmClearInventoryDialog(context, p, PlayerSlot.main),
            ),
            if (hasCoop)
              _TileData(
                icon: Icons.restart_alt_rounded,
                label: 'Reset $player2Name',
                color: Colors.pinkAccent,
                onTap: () => confirmClearInventoryDialog(context, p, PlayerSlot.coop),
              ),
            _TileData(
              icon: Icons.history_edu_rounded,
              label: 'Changelog',
              color: const Color(0xFFFFD740),
              onTap: () => _showChangelogDialog(context),
            ),
            _TileData(
              icon: Icons.grid_view_rounded,
              label: 'Dev Tools',
              color: Colors.greenAccent,
              onTap: () {
                if (p.runState.main.character != null) {
                  Haptics.selection();
                  Navigator.push(context, fastRoute(const SpecialItemsGridScreen()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: GoopText('Start a run first to spawn special items.'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ]),
          const SizedBox(height: 16),

          // ── DANGER ZONE grid ──
          _groupLabel('DANGER ZONE'),
          _buildGrid([
            _TileData(
              icon: Icons.cancel_presentation_rounded,
              label: 'End Run',
              color: Colors.redAccent,
              isDanger: true,
              onTap: () => _confirmEndRun(context, p),
            ),
            _TileData(
              icon: Icons.restart_alt,
              label: 'Reset All Data',
              color: Colors.deepOrange,
              isDanger: true,
              onTap: () => _confirmResetAppData(context),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Widget _groupLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: GoopText(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.white38,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGrid(List<_TileData> tiles) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.8,
      children: tiles.map((t) => _CompactActionTile(data: t)).toList(),
    );
  }

  Widget _buildMpStatusBar(
    BuildContext context,
    RunProvider p,
    bool hasCoop,
    String player2Name,
    bool mpActive,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(
            mpActive ? Icons.wifi_rounded : (hasCoop ? Icons.people_alt_rounded : Icons.person_rounded),
            size: 16,
            color: mpActive ? Colors.greenAccent : (hasCoop ? Colors.pinkAccent : Colors.white54),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GoopText(
              mpActive
                  ? 'MP ACTIVE'
                  : (hasCoop ? 'P2 ACTIVE: $player2Name' : 'SOLO'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: mpActive ? Colors.greenAccent : (hasCoop ? Colors.pinkAccent : Colors.white70),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogueCard(ThemeFlair flair) {
    final prefs = VisualPrefs.notifier.value;
    return Card(
      color: flair.card.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: flair.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            _buildSwitchRow(
              context: context,
              icon: Icons.vibration_rounded,
              label: 'Dialogue Haptics',
              value: prefs.dialogueHapticsEnabled,
              onChanged: VisualPrefs.setDialogueHapticsEnabled,
              flair: flair,
            ),
            const Divider(color: Colors.white12, height: 20),
            _buildCompactSliderRow(
              'Text Speed',
              '${prefs.dialogueTextSpeedMs}ms',
              prefs.dialogueTextSpeedMs.toDouble(),
              10.0,
              80.0,
              14,
              flair.headlineStat,
              (v) => VisualPrefs.setDialogueTextSpeedMs(v.toInt()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required ThemeFlair flair,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: flair.card.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: flair.primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: GoopText(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 0.5),
            ),
          ),
          Switch(
            value: value,
            activeColor: flair.primary,
            activeTrackColor: flair.primary.withValues(alpha: 0.25),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: Colors.white10,
            onChanged: (val) {
              onChanged(val);
              Haptics.selection();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSliderRow(
    String label,
    String displayValue,
    double value,
    double min,
    double max,
    int divisions,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GoopText(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white70)),
            GoopText(displayValue, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
        SizedBox(
          height: 32,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3.0,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
              activeTrackColor: color,
              inactiveTrackColor: Colors.white12,
              thumbColor: Colors.white,
              valueIndicatorColor: color,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Data model for a compact grid action tile.
class _TileData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isDanger;

  const _TileData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isDanger = false,
  });
}

/// Compact icon+label action tile for the 2-column settings grid.
class _CompactActionTile extends StatelessWidget {
  final _TileData data;
  const _CompactActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: data.isDanger
                  ? data.color.withValues(alpha: 0.35)
                  : data.color.withValues(alpha: 0.2),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(data.icon, color: data.color, size: 22),
              const SizedBox(height: 6),
              GoopText(
                data.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: data.isDanger ? data.color : Colors.white70,
                  letterSpacing: 0.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
