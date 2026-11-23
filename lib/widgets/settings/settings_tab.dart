import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/run_provider.dart';
import '../../services/run_lifecycle.dart';
import '../../services/haptics.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../screens/character_select_screen.dart';
import '../../screens/experience_studio_screen.dart';
import '../../utils/fast_route.dart';
import 'debug_tab.dart';
import '../active_run/dice_roll.dart';
import 'swipe_picker.dart';

part 'settings_sections.dart';
part 'settings_widgets.dart';

/// Unified settings screen — gameplay preferences, studio shortcut,
/// developer tools, and danger zone.
///
/// Prefs-only by design (v3.7.x IA split): run-scoped actions —
/// shrines, co-op, save run, MP status/leave, per-player inventory
/// resets — live in the active-run tools sheet instead. Reachable
/// from the main-menu settings chip AND the in-run sheet's Settings
/// row, so gameplay prefs (dice type, synergy toggles, panels) no
/// longer require an active run.
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

  @override
  Future<void> _confirmResetAppData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (c) => AlertDialog(
            icon: Icon(Icons.restart_alt, color: Colors.deepOrange, size: 32),
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
    final hasRun = p.runState.main.character != null;
    final flair = AppTheme.flair;

    return ListenableBuilder(
      listenable: VisualPrefs.notifier,
      builder: (context, _) {
        final prefs = VisualPrefs.notifier.value;
        final screenWidth = MediaQuery.sizeOf(context).width;
        final isWide = screenWidth >= 600;

        // Build all section widgets — prefs-only; run-scoped actions
        // live in the active-run tools sheet (shrines, co-op, save,
        // MP leave, per-player resets).
        final List<Widget> sections = [
          _SettingsSection(
            label: 'GAMEPLAY',
            flair: flair,
            child: Column(
              children: [
                _CollapsibleCard(
                  title: 'SYNERGIES',
                  icon: Icons.hub_outlined,
                  flair: flair,
                  initiallyExpanded: false,
                  child: Column(
                    children: [
                      _SynergyToggleRow(
                        title: "Lich's Eye Bullets",
                        subtitle: 'Show simulated synergies for all guns',
                        value: prefs.showLichEyeBulletsSynergies,
                        flair: flair,
                        onChanged: VisualPrefs.setShowLichEyeBulletsSynergies,
                      ),
                      const SizedBox(height: 10),
                      _SynergyToggleRow(
                        title: 'Co-op scope tags',
                        subtitle: 'Tag synergies as CO-OP / TEAM / ONE PLAYER',
                        value: prefs.showSynergyCoopTags,
                        flair: flair,
                        onChanged: VisualPrefs.setShowSynergyCoopTags,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _CollapsibleCard(
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
                const SizedBox(height: 12),
                _CollapsibleCard(
                  title: 'PANELS',
                  icon: Icons.dashboard_customize_outlined,
                  flair: flair,
                  initiallyExpanded: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GoopText(
                              'Special item panels',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            GoopText(
                              'Gunderfury, Ser Junkan, Evolver & co. trackers',
                              style: TextStyle(
                                fontSize: FontSizes.labelMedium,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: prefs.showDashboards,
                        activeThumbColor: flair.primary,
                        onChanged: VisualPrefs.setShowDashboards,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _SettingsSection(
            label: 'STUDIO',
            flair: flair,
            child: _CompactActionTile(
              data: _TileData(
                icon: Icons.palette_rounded,
                label: 'Customization',
                color: Colors.pinkAccent,
                onTap: () {
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

              // DEV TOOLS — full-width, before the danger zone
              const SizedBox(height: 12),
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

              // DANGER ZONE — always last, full-width. End Run only
              // appears while a run is actually active (this screen is
              // also reachable from the main menu with no run).
              const SizedBox(height: 12),
              _sectionLabel('DANGER ZONE', flair),
              if (hasRun) ...[
                _buildEndRunButton(context, p),
                const SizedBox(height: 10),
              ],
              _buildResetDataButton(context),

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

/// One labelled toggle row inside the SYNERGIES settings card.
class _SynergyToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ThemeFlair flair;
  final ValueChanged<bool> onChanged;

  const _SynergyToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.flair,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GoopText(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              GoopText(
                subtitle,
                style: TextStyle(
                  fontSize: FontSizes.labelMedium,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: flair.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
