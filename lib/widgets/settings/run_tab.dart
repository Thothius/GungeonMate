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
import 'run_log_screen.dart';

/// App settings tab — MP status, run session, inventory reset, changelog,
/// dev tools, danger zone. Part of the 3-tab settings reorganization
/// (Appearance / Gameplay / App).
class AppTab extends StatefulWidget {
  const AppTab({super.key});

  @override
  State<AppTab> createState() => _AppTabState();
}

class _AppTabState extends State<AppTab> {
  // ── Confirm dialogs (lifted from old RunTab + AppTab) ──────────────

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
    } catch (e) { debugPrint('[RunTab] prefs clear error: $e'); }
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── MP & Co-op status bar (slim full-width) ──
          _buildMpStatusBar(context, p, hasCoop, player2Name, mpActive),
          const SizedBox(height: 16),

          // ── MP SESSION grid (only when MP active) ──
          if (mpActive) ...[
            _groupLabel('MP SESSION'),
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
            const SizedBox(height: 16),
          ],

          // ── ACCOUNT & DATA grid ──
          _groupLabel('ACCOUNT & DATA'),
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
              icon: Icons.receipt_long_rounded,
              label: 'Event Log',
              color: const Color(0xFFFFD740),
              onTap: () => Navigator.push(context, fastRoute(const RunLogScreen())),
            ),
          ]),
          const SizedBox(height: 16),

          // ── DEVELOPER grid ──
          _groupLabel('DEVELOPER'),
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
          const SizedBox(height: 16),

          // ── DANGER ZONE ──
          _groupLabel('DANGER ZONE'),
          // End Run — full-width prominent button with Lord of the Jammed icon
          _buildEndRunButton(context, p),
          const SizedBox(height: 8),
          _buildGrid([
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
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppTheme.flair.primary.withValues(alpha: 0.8),
          letterSpacing: 0.8,
        ),
      ),
    );
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
