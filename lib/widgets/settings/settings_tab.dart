import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/run_provider.dart';
import '../../services/run_lifecycle.dart';
import '../../services/app_data_reset.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../services/mp_session.dart';
import '../../screens/experience_studio_screen.dart';
import '../../utils/asset_paths.dart' show kAppVersion;
import '../../utils/fast_route.dart';
import '../../utils/responsive.dart' show ScreenProfile;
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
              'You will return to the main menu with default settings. '
              'This cannot be undone.',
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
                child: const GoopText('RESET ALL DATA'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final p = context.read<RunProvider>();
    final session = context.read<MpSession>();
    await resetAllAppData(runProvider: p, session: session);
    if (!context.mounted) return;

    // Land on the existing Home/MainMenu route — never strand the user
    // on character select (U-026).
    Navigator.of(context).popUntil((route) => route.isFirst);
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
        final profile = ScreenProfile.of(context);
        final isWide = !profile.isCompactWidth;

        final synergyCount =
            (prefs.showLichEyeBulletsSynergies ? 1 : 0) +
            (prefs.showSynergyCoopTags ? 1 : 0);

        final runPanels = <Widget>[
          _SettingsPanel(
            title: 'SYNERGY READOUT',
            icon: Icons.hub_outlined,
            flair: flair,
            summary: synergyCount == 0 ? 'OFF' : '$synergyCount ON',
            child: Column(
              children: [
                _SettingsToggleRow(
                  title: "Lich's Eye Bullets",
                  subtitle: 'Show simulated synergies for all guns',
                  value: prefs.showLichEyeBulletsSynergies,
                  flair: flair,
                  onChanged: VisualPrefs.setShowLichEyeBulletsSynergies,
                ),
                const SizedBox(height: Insets.md),
                _SettingsToggleRow(
                  title: 'Co-op scope tags',
                  subtitle: 'Tag synergies as CO-OP / TEAM / ONE PLAYER',
                  value: prefs.showSynergyCoopTags,
                  flair: flair,
                  onChanged: VisualPrefs.setShowSynergyCoopTags,
                ),
              ],
            ),
          ),
          _SettingsPanel(
            title: 'DICE STYLE',
            icon: Icons.casino_rounded,
            flair: flair,
            summary: prefs.customDiceType.label,
            child: _buildDicePanel(flair, prefs),
          ),
          _SettingsPanel(
            title: 'SPECIAL PANELS',
            icon: Icons.dashboard_customize_outlined,
            flair: flair,
            summary: prefs.showDashboards ? 'On' : 'Off',
            child: _SettingsToggleRow(
              title: 'Special item panels',
              subtitle: 'Gunderfury, Ser Junkan, Evolver & co. trackers',
              value: prefs.showDashboards,
              flair: flair,
              onChanged: VisualPrefs.setShowDashboards,
            ),
          ),
        ];

        final Widget runDisplaySection;
        if (isWide) {
          final contentWidth = profile.width - 2 * Insets.lg;
          final colWidth = (contentWidth - Insets.lg) / 2;
          runDisplaySection = _SettingsSection(
            label: 'RUN DISPLAY',
            flair: flair,
            child: Wrap(
              spacing: Insets.lg,
              runSpacing: Insets.lg,
              children:
                  runPanels
                      .map((panel) => SizedBox(width: colWidth, child: panel))
                      .toList(),
            ),
          );
        } else {
          runDisplaySection = _SettingsSection(
            label: 'RUN DISPLAY',
            flair: flair,
            child: Column(
              children: [
                for (var i = 0; i < runPanels.length; i++) ...[
                  if (i > 0) const SizedBox(height: Insets.lg),
                  runPanels[i],
                ],
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Insets.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusStrip(p, prefs),
              const SizedBox(height: Insets.lg),
              runDisplaySection,
              const SizedBox(height: Insets.lg),
              _SettingsSection(
                label: 'STUDIO',
                flair: flair,
                child: _SettingsActionCard(
                  icon: Icons.palette_rounded,
                  iconColor: Colors.pinkAccent,
                  title: 'Customization',
                  subtitle: 'Theme, particles, fonts & studio presets',
                  flair: flair,
                  onTap: () {
                    Navigator.push(
                      context,
                      fastRoute(const ExperienceStudioScreen()),
                    );
                  },
                ),
              ),
              if (hasRun) ...[
                const SizedBox(height: Insets.lg),
                _SettingsSection(
                  label: 'DEV TOOLS',
                  flair: flair,
                  child: _SettingsActionCard(
                    icon: Icons.grid_view_rounded,
                    iconColor: Colors.amber,
                    title: 'Special Items & Guns',
                    subtitle: 'Spawn or remove special loadout pieces',
                    flair: flair,
                    onTap: () {
                      Navigator.push(
                        context,
                        fastRoute(const SpecialItemsGridScreen()),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: Insets.lg),
              _buildDangerZone(context, p, hasRun, flair),
              const SizedBox(height: Insets.xl),
            ],
          ),
        );
      },
    );
  }
}
