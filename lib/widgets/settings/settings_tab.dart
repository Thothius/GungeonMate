import '../../theme/tokens.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/multiplayer_messages.dart';
import '../../models/player.dart';
import '../../providers/run_provider.dart';
import '../../services/mp_session.dart';
import '../../services/run_lifecycle.dart';
import '../../services/haptics.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../screens/character_select_screen.dart';
import '../../screens/shrine_picker_screen.dart';
import '../../screens/experience_studio_screen.dart';
import '../../utils/fast_route.dart';
import 'debug_tab.dart';
import '../active_run/active_run_helpers.dart';
import '../active_run/dice_roll.dart';
import 'swipe_picker.dart';
part 'settings_sections.dart';
part 'settings_widgets.dart';

/// Unified settings tab — gameplay preferences, multiplayer status,
/// account/data, developer tools, and danger zone.
///
/// Formerly split across GameplayTab + AppTab. Unified into a single
/// scrollable view with modern grouped sections (v1.9.62).
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> with _SettingsTabSections {
  // ── Confirm dialogs ────────────────────────────────────────────────

  @override
  void _confirmEndRun(BuildContext context, RunProvider p) {
    RunLifecycle.confirmEndRun(context);
  }

  void _confirmLeaveMp(BuildContext context, MpSession session) {
    final isSidekick = session.myRole == MpRole.sidekick;
    showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            icon: const Icon(
              Icons.bluetooth_disabled,
              color: Colors.lightBlueAccent,
            ),
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
                  backgroundColor: Colors.lightBlueAccent.withValues(
                    alpha: 0.15,
                  ),
                  foregroundColor: Colors.lightBlueAccent,
                ),
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

  void _handleAddCoop(BuildContext context, RunProvider p) {
    if (p.runState.hasCoop) {
      showDialog(
        context: context,
        builder:
            (c) => AlertDialog(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.redAccent,
              ),
              title: const GoopText('Remove Co-op Player?'),
              content: GoopText(
                'Removes ${p.runState.coop?.character?.name ?? 'Player 2'} from the run.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const GoopText('Cancel'),
                ),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade900,
                  ),
                  onPressed: () {
                    p.endCoopPlayer();
                    Navigator.pop(c);
                  },
                  child: const GoopText('Remove'),
                ),
              ],
            ),
      );
    } else {
      final cultist =
          p.gungeoneerByName('The Cultist') ?? p.gungeoneerByName('Cultist');
      if (cultist != null) {
        p.startCoopPlayer(cultist);
      }
      Navigator.push(
        context,
        fastRoute(const CharacterSelectScreen(mode: CharSelectMode.coop)),
      );
    }
  }

  @override
  Future<void> _confirmResetAppData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            icon: const Icon(
              Icons.restart_alt,
              color: Colors.deepOrange,
              size: 32,
            ),
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
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
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
    } catch (e) {
      debugPrint('[SettingsTab] prefs clear error: $e');
    }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      fastRoute(const CharacterSelectScreen()),
      (_) => false,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RunProvider>();
    final hasCoop = p.runState.hasCoop;
    final player1Name = p.runState.main.character?.name ?? 'Player 1';
    final player2Name = p.runState.coop?.character?.name ?? 'Player 2';
    final mpSession = context.watch<MpSession>();
    final mpActive = mpSession.isActive;
    final flair = AppTheme.flair;

    return ListenableBuilder(
      listenable: VisualPrefs.notifier,
      builder: (context, _) {
        final prefs = VisualPrefs.notifier.value;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isWide = screenWidth >= 600;

        // Build all section widgets
        final List<Widget> sections = [
          _SettingsSection(
            label: 'GENERAL',
            flair: flair,
            child: _CollapsibleCard(
              title: 'RUN TOOLS',
              icon: Icons.build_rounded,
              flair: flair,
              initiallyExpanded: true,
              child: _buildGrid([
                _TileData(
                  icon: Icons.temple_buddhist,
                  label: 'Shrine Picker',
                  color: Colors.amber,
                  onTap:
                      () => Navigator.push(
                        context,
                        fastRoute(const ShrinePickerScreen()),
                      ),
                ),
                _TileData(
                  icon:
                      p.runState.hasCoop
                          ? Icons.remove_circle_outline
                          : Icons.person_add_alt_1,
                  label: p.runState.hasCoop ? 'Remove Co-op' : 'Add Co-op',
                  color:
                      p.runState.hasCoop ? Colors.redAccent : Colors.pinkAccent,
                  onTap: () => _handleAddCoop(context, p),
                ),
                _TileData(
                  icon: Icons.save_outlined,
                  label: 'Save Run',
                  color: Colors.greenAccent,
                  onTap: () {
                    unawaited(
                      p
                          .saveRun()
                          .then((_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: GoopText('Run saved'),
                                  duration: Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          })
                          .catchError((e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: GoopText('Failed to save run: $e'),
                                  duration: const Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }),
                    );
                  },
                ),
              ]),
            ),
          ),
          _SettingsSection(
            label: '',
            flair: flair,
            child: _CollapsibleCard(
              title: 'DICE',
              icon: Icons.casino_rounded,
              flair: flair,
              initiallyExpanded: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CompactActionTile(
                      data: _TileData(
                        icon: Icons.casino_outlined,
                        label: 'Dice Roll',
                        color: const Color(0xFFFFD54F),
                        onTap: () => showDiceRollDialog(context),
                      ),
                    ),
                  ),
                  _buildDicePanel(flair, prefs),
                ],
              ),
            ),
          ),
          if (mpActive || hasCoop)
            _SettingsSection(
              label: '',
              flair: flair,
              child: _CollapsibleCard(
                title: 'MULTIPLAYER',
                icon: Icons.bluetooth_rounded,
                flair: flair,
                initiallyExpanded: mpActive,
                child: Column(
                  children: [
                    _buildMpStatusBar(
                      context,
                      p,
                      hasCoop,
                      player2Name,
                      mpActive,
                    ),
                    if (mpActive) ...[
                      const SizedBox(height: 10),
                      _buildGrid([
                        if (mpSession.myRole == MpRole.sidekick)
                          _TileData(
                            icon: Icons.bluetooth_disabled,
                            label: 'Leave MP',
                            color: Colors.lightBlueAccent,
                            onTap: () => _confirmLeaveMp(context, mpSession),
                          ),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          _SettingsSection(
            label: '',
            flair: flair,
            child: _CollapsibleCard(
              title: 'DATA & STORAGE',
              icon: Icons.storage_rounded,
              flair: flair,
              initiallyExpanded: false,
              child: _buildGrid([
                _TileData(
                  icon: Icons.restart_alt_rounded,
                  label: 'Reset $player1Name',
                  color: Colors.cyanAccent,
                  onTap:
                      () => confirmClearInventoryDialog(
                        context,
                        p,
                        PlayerSlot.main,
                      ),
                ),
                if (hasCoop)
                  _TileData(
                    icon: Icons.restart_alt_rounded,
                    label: 'Reset $player2Name',
                    color: Colors.pinkAccent,
                    onTap:
                        () => confirmClearInventoryDialog(
                          context,
                          p,
                          PlayerSlot.coop,
                        ),
                  ),
              ]),
            ),
          ),
          _SettingsSection(
            label: 'CUSTOMIZATION',
            flair: flair,
            child: _CompactActionTile(
              data: _TileData(
                icon:
                    AppTheme.isSkeuo
                        ? Icons.lock_outline_rounded
                        : Icons.palette_rounded,
                label:
                    AppTheme.isSkeuo
                        ? 'Customization (locked in Neo-Skeuo)'
                        : 'Customization',
                color: AppTheme.isSkeuo ? Colors.grey : Colors.pinkAccent,
                onTap: () {
                  if (AppTheme.isSkeuo) return;
                  Navigator.push(
                    context,
                    fastRoute(const ExperienceStudioScreen()),
                  );
                },
              ),
            ),
          ),
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2-column grid for sections (wraps on narrow)
              if (isWide) ...[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      sections
                          .map(
                            (s) => SizedBox(
                              width: (screenWidth - 2 * Insets.lg - 12) / 2,
                              child: s,
                            ),
                          )
                          .toList(),
                ),
              ] else ...[
                // Narrow: vertical stack
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      sections
                          .expand((s) => [s, const SizedBox(height: 12)])
                          .toList(),
                ),
              ],

              // APP / DANGER ZONE — always full-width
              const SizedBox(height: 12),
              _sectionLabel('APP', flair),
              _buildEndRunButton(context, p),
              const SizedBox(height: 10),
              _buildResetDataButton(context),
              const SizedBox(height: 12),

              // DEV TOOLS — full-width
              _CollapsibleCard(
                title: 'DEV TOOLS',
                icon: Icons.bug_report_rounded,
                flair: flair,
                initiallyExpanded: false,
                child: _buildGrid([
                  _TileData(
                    icon: Icons.grid_view_rounded,
                    label: 'Dev Tools',
                    color: Colors.amber,
                    onTap: () {
                      if (p.runState.main.character != null) {
                        Haptics.selection();
                        Navigator.push(
                          context,
                          fastRoute(const SpecialItemsGridScreen()),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: GoopText(
                              'Start a run first to spawn special items.',
                            ),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ]),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  @override
  (Color, Color, Color, Color) _diceColors(
    CustomDiceType type,
    ThemeFlair flair,
  ) {
    switch (type) {
      case CustomDiceType.classicWhite:
        return (
          const Color(0xFFFAFAFA),
          const Color(0xFF90A4AE),
          const Color(0xFF263238),
          Colors.white24,
        );
      case CustomDiceType.goldGlimmer:
        return (
          const Color(0xFF2C2210),
          const Color(0xFFFFD54F),
          const Color(0xFFFFD54F),
          const Color(0x33FFD54F),
        );
      case CustomDiceType.frostShard:
        return (
          const Color(0xFF101C2C),
          const Color(0xFF00E5FF),
          const Color(0xFF00E5FF),
          const Color(0x3300E5FF),
        );
      case CustomDiceType.moltenAmber:
        return (
          const Color(0xFF2C1010),
          const Color(0xFFFF3D00),
          const Color(0xFFFF3D00),
          const Color(0x33FF3D00),
        );
      case CustomDiceType.voidPurple:
        return (
          const Color(0xFF1F102C),
          const Color(0xFFD500F9),
          const Color(0xFFD500F9),
          const Color(0x33D500F9),
        );
      case CustomDiceType.toxicOoze:
        return (
          const Color(0xFF102C13),
          const Color(0xFF00E676),
          const Color(0xFF00E676),
          const Color(0x3300E676),
        );
      case CustomDiceType.themeDefault:
        return (
          const Color(0xFF161413),
          flair.primary,
          flair.primary,
          flair.primary.withValues(alpha: 0.3),
        );
    }
  }
}
