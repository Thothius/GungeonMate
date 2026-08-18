import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/multiplayer_messages.dart';
import '../../models/player.dart';
import '../../providers/run_provider.dart';
import '../../services/multiplayer_session.dart';
import '../../services/haptics.dart';
import '../../services/app_theme.dart';
import '../../services/goop_talk_engine.dart';
import '../../screens/character_select_screen.dart';
import '../../utils/fast_route.dart';
import '../active_run/end_run_confirm_dialog.dart';
import '../active_run/active_run_helpers.dart';
import 'debug_tab.dart';
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
    EndRunConfirmDialog.show(
      context,
      onConfirm: () async {
        final session = context.read<MultiplayerSession>();
        if (session.isActive) {
          await session.notifyEndRunAndCancel();
          if (session.myRole == MpRole.main) {
            p.endRun();
          }
        } else {
          p.endRun();
        }
      },
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
    } catch (e) {
      debugPrint('[SettingsTab] prefs clear error: $e');
    }
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      fastRoute(const CharacterSelectScreen()),
      (_) => false,
    );
  }

  // ── Changelog dialog ───────────────────────────────────────────────

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
                      tooltip: 'Close',
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
    final p = context.watch<RunProvider>();
    final hasCoop = p.runState.hasCoop;
    final player1Name = p.runState.main.character?.name ?? 'Player 1';
    final player2Name = p.runState.coop?.character?.name ?? 'Player 2';
    final mpSession = context.watch<MultiplayerSession>();
    final mpActive = mpSession.isActive;
    final flair = AppTheme.flair;

    return ListenableBuilder(
      listenable: VisualPrefs.notifier,
      builder: (context, _) {
        final prefs = VisualPrefs.notifier.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── DICE STYLE ──
              _sectionHeader('DICE STYLE', flair),
              _buildDicePanel(flair, prefs),
              const SizedBox(height: 20),

              // ── MULTIPLAYER ──
              _sectionHeader('MULTIPLAYER', flair),
              _buildMpStatusBar(context, p, hasCoop, player2Name, mpActive),
              if (mpActive) ...[
                const SizedBox(height: 10),
                _buildGrid([
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
                  _TileData(
                    icon: mpSession.isPaused
                        ? Icons.play_circle_fill_rounded
                        : Icons.pause_circle_filled_rounded,
                    label: mpSession.isPaused ? 'Resume Run' : 'Pause Run',
                    color: mpSession.isPaused ? Colors.greenAccent : Colors.orangeAccent,
                    onTap: () {
                      unawaited(
                        (mpSession.isPaused ? mpSession.resumeRun() : mpSession.pauseRun()).then((_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: GoopText(
                                  mpSession.isPaused
                                      ? 'MP run resumed — searching for peer...'
                                      : 'MP run paused — tap Resume when back in range.',
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }),
                      );
                    },
                  ),
                  if (mpSession.myRole == MpRole.sidekick)
                    _TileData(
                      icon: Icons.bluetooth_disabled,
                      label: 'Leave MP',
                      color: Colors.lightBlueAccent,
                      onTap: () => _confirmLeaveMp(context, mpSession),
                    ),
                ]),
              ],
              const SizedBox(height: 20),

              // ── ACCOUNT & DATA ──
              _sectionHeader('ACCOUNT & DATA', flair),
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
              ]),
              const SizedBox(height: 20),

              // ── DEVELOPER ──
              _sectionHeader('DEVELOPER', flair),
              _buildGrid([
                _TileData(
                  icon: Icons.grid_view_rounded,
                  label: 'Dev Tools',
                  color: Colors.amber,
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
              const SizedBox(height: 20),

              // ── DANGER ZONE ──
              _sectionHeader('DANGER ZONE', flair),
              _buildEndRunButton(context, p),
              const SizedBox(height: 10),
              _buildGrid([
                _TileData(
                  icon: Icons.restart_alt,
                  label: 'Reset All Data',
                  color: Colors.deepOrange,
                  isDanger: true,
                  onTap: () => _confirmResetAppData(context),
                ),
              ]),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  Widget _sectionHeader(String label, ThemeFlair flair) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: flair.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          GoopText(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: flair.primary.withValues(alpha: 0.9),
              letterSpacing: 1.4,
            ),
          ),
        ],
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
            SwipePicker<CustomDiceType>(
              items: CustomDiceType.values,
              value: prefs.customDiceType,
              onChanged: (t) => VisualPrefs.setCustomDiceType(t),
              height: 56,
              itemBuilder: (type, isSelected) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? flair.card.withValues(alpha: 0.9)
                      : flair.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
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
                      color: isSelected ? Colors.white : Colors.white54,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(child: _dicePreview(type: prefs.customDiceType, flair: flair)),
          ],
        ),
      ),
    );
  }

  Widget _dicePreview({required CustomDiceType type, required ThemeFlair flair, int value = 5}) {
    final colors = _diceColors(type, flair);
    return Container(
      width: 120,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.$2, width: 3),
        boxShadow: [BoxShadow(color: colors.$4, blurRadius: 12, spreadRadius: 3)],
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

  (Color, Color, Color, Color) _diceColors(CustomDiceType type, ThemeFlair flair) {
    switch (type) {
      case CustomDiceType.classicWhite:
        return (const Color(0xFFFAFAFA), const Color(0xFF90A4AE), const Color(0xFF263238), Colors.white24);
      case CustomDiceType.goldGlimmer:
        return (const Color(0xFF2C2210), const Color(0xFFFFD54F), const Color(0xFFFFD54F), const Color(0x33FFD54F));
      case CustomDiceType.frostShard:
        return (const Color(0xFF101C2C), const Color(0xFF00E5FF), const Color(0xFF00E5FF), const Color(0x3300E5FF));
      case CustomDiceType.moltenAmber:
        return (const Color(0xFF2C1010), const Color(0xFFFF3D00), const Color(0xFFFF3D00), const Color(0x33FF3D00));
      case CustomDiceType.voidPurple:
        return (const Color(0xFF1F102C), const Color(0xFFD500F9), const Color(0xFFD500F9), const Color(0x33D500F9));
      case CustomDiceType.toxicOoze:
        return (const Color(0xFF102C13), const Color(0xFF00E676), const Color(0xFF00E676), const Color(0x3300E676));
      case CustomDiceType.themeDefault:
        return (const Color(0xFF161413), flair.primary, flair.primary, flair.primary.withValues(alpha: 0.3));
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
          borderRadius: BorderRadius.circular(12),
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
              errorBuilder: (_, __, ___) => const Icon(
                Icons.cancel_presentation_rounded,
                size: 28,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 12),
            const GoopText(
              'END RUN',
              style: TextStyle(
                fontSize: 16,
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

  Widget _buildMpStatusBar(
    BuildContext context,
    RunProvider p,
    bool hasCoop,
    String player2Name,
    bool mpActive,
  ) {
    final iconColor = mpActive
        ? Colors.greenAccent
        : (hasCoop ? Colors.pinkAccent : Colors.white54);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            iconColor.withValues(alpha: 0.12),
            iconColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
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
                fontSize: 14,
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
    final flair = AppTheme.flair;
    return Material(
      color: flair.card.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(8),
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
                    color: Colors.white.withValues(alpha: 0.8),
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
