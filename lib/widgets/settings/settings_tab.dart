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

class _SettingsTabState extends State<SettingsTab> {
  // ── Confirm dialogs ────────────────────────────────────────────────

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
                icon: Icons.palette_rounded,
                label: 'Themes & Customization',
                color: Colors.pinkAccent,
                onTap:
                    () => Navigator.push(
                      context,
                      fastRoute(const ExperienceStudioScreen()),
                    ),
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

  /// Section label — GENERAL / CUSTOMIZATION / APP group headers.
  Widget _sectionLabel(String text, ThemeFlair flair) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: GoopText(
        text,
        style: TextStyle(
          fontSize: FontSizes.labelSmall,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.2,
          color: flair.primary.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  Widget _buildGrid(List<_TileData> tiles) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: tiles.map((t) => _CompactActionTile(data: t)).toList(),
    );
  }

  Widget _buildDicePanel(ThemeFlair flair, VisualPrefs prefs) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Card(
      color: flair.card.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radii.md),
        side: BorderSide(color: flair.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            SwipePicker<CustomDiceType>(
              items: CustomDiceType.values,
              value: prefs.customDiceType,
              onChanged: (t) => VisualPrefs.setCustomDiceType(t),
              height: 56,
              itemBuilder:
                  (type, isSelected) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? flair.card.withValues(alpha: 0.9)
                              : flair.card.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected
                                ? flair.primary.withValues(alpha: 0.6)
                                : onSurface.withValues(alpha: 0.12),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Center(
                      child: GoopText(
                        type.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color:
                              isSelected
                                  ? onSurface
                                  : onSurface.withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            Center(
              child: _dicePreview(type: prefs.customDiceType, flair: flair),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dicePreview({
    required CustomDiceType type,
    required ThemeFlair flair,
    int value = 5,
  }) {
    final colors = _diceColors(type, flair);
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.$2, width: 3),
        boxShadow: [
          BoxShadow(color: colors.$4, blurRadius: 12, spreadRadius: 3),
        ],
      ),
      child: Text(
        '$value',
        style: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w900,
          color: colors.$3,
        ),
      ),
    );
  }

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

  /// Full-width, prominent End Run button styled with the Lord of the
  /// Jammed sprite and red-accent danger styling.
  Widget _buildEndRunButton(BuildContext context, RunProvider p) {
    return GestureDetector(
      onTap: () => _confirmEndRun(context, p),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.red.shade900.withValues(alpha: 0.25),
          borderRadius: BorderRadius.all(Radii.md),
          border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.4),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Image.asset(
              'assets/images/end_run/Lord_of_the_Jammed.webp',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              cacheWidth: 72,
              cacheHeight: 72,
              errorBuilder:
                  (_, __, ___) => const Icon(
                    Icons.cancel_presentation_rounded,
                    size: 28,
                    color: Colors.redAccent,
                  ),
            ),
            const SizedBox(width: 12),
            const GoopText(
              'END RUN',
              style: TextStyle(
                fontSize: FontSizes.titleSmall,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.redAccent,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  /// Full-width Reset All Data button with deep-orange danger styling.
  Widget _buildResetDataButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmResetAppData(context),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.deepOrange.withValues(alpha: 0.18),
          borderRadius: const BorderRadius.all(Radii.md),
          border: Border.all(
            color: Colors.deepOrange.withValues(alpha: 0.45),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withValues(alpha: 0.08),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.restart_alt, size: 28, color: Colors.deepOrange),
            const SizedBox(width: 12),
            const GoopText(
              'RESET DATA',
              style: TextStyle(
                fontSize: FontSizes.titleSmall,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: Colors.deepOrange,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Colors.deepOrange,
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildMpStatusBar(
    BuildContext context,
    RunProvider p,
    bool hasCoop,
    String player2Name,
    bool mpActive,
  ) {
    final iconColor =
        mpActive
            ? Colors.greenAccent
            : (hasCoop
                ? Colors.pinkAccent
                : Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5));
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.lg,
        vertical: Insets.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withValues(alpha: 0.12),
            iconColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(color: iconColor.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            mpActive
                ? Icons.wifi_rounded
                : (hasCoop ? Icons.people_alt_rounded : Icons.person_rounded),
            size: 20,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GoopText(
              mpActive
                  ? 'MP ACTIVE'
                  : (hasCoop ? 'P2 ACTIVE: $player2Name' : 'SOLO'),
              style: TextStyle(
                fontSize: FontSizes.bodyMedium,
                fontWeight: FontWeight.w800,
                color: iconColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Data model for a compact grid action tile.
class _TileData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TileData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Compact icon+label action tile for the 2-column settings grid.
class _CompactActionTile extends StatelessWidget {
  final _TileData data;
  const _CompactActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: flair.card.withValues(alpha: 0.6),
      borderRadius: BorderRadius.all(Radii.md),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.all(Radii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radii.md),
            border: Border.all(
              color: data.color.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.all(Radii.sm),
                ),
                child: Icon(data.icon, size: 20, color: data.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GoopText(
                  data.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: onSurface.withValues(alpha: 0.8),
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A collapsible settings card with a header row (icon + title + chevron)
/// and expandable content. Tapping the header toggles expansion.
class _CollapsibleCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final ThemeFlair flair;
  final Widget child;
  final bool initiallyExpanded;

  const _CollapsibleCard({
    required this.title,
    required this.icon,
    required this.flair,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<_CollapsibleCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.flair.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: widget.flair.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.all(Radii.md),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.16),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: () {
              Haptics.selection();
              setState(() => _expanded = !_expanded);
            },
            borderRadius: BorderRadius.all(Radii.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: accentColor.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GoopText(
                      widget.title,
                      style: TextStyle(
                        fontSize: FontSizes.labelMedium,
                        fontWeight: FontWeight.w900,
                        color: accentColor.withValues(alpha: 0.9),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: widget.child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState:
                _expanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// Internal helper for 2-col settings layout — wraps a section with an
/// optional label header (e.g., "GENERAL", "CUSTOMIZATION").
class _SettingsSection extends StatelessWidget {
  final String label;
  final ThemeFlair flair;
  final Widget child;

  const _SettingsSection({
    required this.label,
    required this.flair,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: GoopText(
              label,
              style: TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                color: flair.primary.withValues(alpha: 0.65),
              ),
            ),
          ),
        child,
      ],
    );
  }
}
