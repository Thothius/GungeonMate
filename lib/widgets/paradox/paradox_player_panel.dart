import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_sheet.dart';

import '../../models/multiplayer_messages.dart';
import '../../models/player.dart' show PlayerSlot;
import '../../providers/run_provider.dart';
import '../../screens/codex_screen.dart';
import '../../screens/cool_curse_screen.dart';
import '../../screens/experience_studio_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/shrine_picker_screen.dart';
import '../../services/goop_talk_engine.dart';
import '../../services/haptics.dart';
import '../../services/app_theme.dart';
import '../../services/mp_session.dart';
import '../../utils/fast_route.dart';
import '../../utils/responsive.dart';
import '../../models/gun.dart';
import '../../screens/all_synergies_screen.dart';
import '../sheets/damage_calc_sheet.dart';
import '../active_run/dice_roll.dart';
import 'avatar_frame.dart';

/// Paradox per-page player panel — the compact info strip replacing
/// [GungeoneerHeader] in Paradox sessions:
///
///   [avatar]  MSG  COOL  CURSE              [chat]  [⋮ menu]
///
/// MSG opens the messages sheet (unread count shown inline).
/// ⋮ menu: INFO — Shrines, Codex · GAME — Reset items, Diceroller ·
/// bottom — END RUN. On the peer's page "Reset items" sends an
/// [MpPeerEdit] clear (co-op trust model).
class ParadoxPlayerPanel extends StatelessWidget {
  final PlayerSlot slot;
  final VoidCallback onTapMsg;

  const ParadoxPlayerPanel({
    super.key,
    required this.slot,
    required this.onTapMsg,
  });

  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);
    final session = context.watch<MpSession>();
    final p = context.watch<RunProvider>();
    final isMainSlot = slot == PlayerSlot.main;
    final isMyPage =
        (session.myRole == MpRole.main) == isMainSlot;
    final avatarId =
        isMyPage ? session.avatarId : session.peerAvatarId;

    return Container(
      margin: EdgeInsets.fromLTRB(8 * sf, 4 * sf, 8 * sf, 2 * sf),
      padding: EdgeInsets.symmetric(horizontal: 8 * sf, vertical: 6 * sf),
      decoration: BoxDecoration(
        color: const Color(0xFF140B22).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          // Avatar — tap to open SurpriseSheet
          GestureDetector(
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFF140B22),
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(18))),
              builder: (_) => const SurpriseSheet(),
            ),
            child: Container(
              width: 42 * sf,
              height: 42 * sf,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFB388FF).withValues(alpha: 0.55),
                    width: 1.5),
              ),
              child: FramedAvatar(id: avatarId, size: double.infinity, radius: 8),
            ),
          ),
          SizedBox(width: 8 * sf),
          // MSG — messages entry; value shows the unread count.
          ValueListenableBuilder<int>(
            valueListenable: session.unreadChat,
            builder: (_, unread, __) => _PanelStat(
              label: 'MSG',
              value: unread > 0 ? '$unread' : '—',
              color: const Color(0xFF00E676),
              sf: sf,
              onTap: onTapMsg,
            ),
          ),
          // COOL
          _PanelStat(
            label: 'COOL',
            value: p.runState.totalCoolness.toStringAsFixed(0),
            color: const Color(0xFF4DD0E1),
            sf: sf,
            onTap: () => Navigator.push(
                context, fastRoute(const CoolCurseScreen())),
          ),
          // CURSE
          _PanelStat(
            label: 'CURSE',
            value: p.runState.totalCurse.toStringAsFixed(0),
            color: const Color(0xFFBA68C8),
            sf: sf,
            onTap: () => Navigator.push(
                context, fastRoute(const CoolCurseScreen())),
          ),
          // DPS — top gun DPS for this slot
          _PanelStat(
            label: 'DPS',
            value: _slotTopDps(p, slot).toStringAsFixed(1),
            color: const Color(0xFFFFD54F),
            sf: sf,
            onTap: () => _showDamageCalcSheet(context, slot),
          ),
          // SYN — active synergy count (combined)
          _PanelStat(
            label: 'SYN',
            value: p.activeSynergyGlowColors.length.toString(),
            color: const Color(0xFFB388FF),
            sf: sf,
            onTap: () => Navigator.push(
                context, fastRoute(const AllSynergiesScreen())),
          ),
          const Spacer(),
          // Chat lives in the MSG stat (left) — deduped 10-28.
          // Run menu
          PopupMenuButton<String>(
            tooltip: 'Run menu',
            icon: Icon(Icons.more_vert_rounded,
                size: 20 * sf, color: Colors.white.withValues(alpha: 0.7)),
            color: const Color(0xFF1E122E),
            onSelected: (v) => _onMenu(context, v, session),
            itemBuilder: (_) => [
              _header('INFO'),
              _item('shrines', Icons.temple_buddhist_rounded, 'Shrines',
                  Colors.amberAccent),
              _item('codex', Icons.menu_book_rounded, 'Codex',
                  const Color(0xFF4DD0E1)),
              const PopupMenuDivider(),
              _header('GAME'),
              _item('reset_p1', Icons.restart_alt_rounded, 'Reset P1 Items',
                  Colors.cyanAccent),
              _item('reset_p2', Icons.restart_alt_rounded, 'Reset P2 Items',
                  Colors.pinkAccent),
              _item('dice', Icons.casino_rounded, 'Diceroller',
                  const Color(0xFFFFD54F)),
              _item('surprise', Icons.auto_awesome_rounded, 'Surprise',
                  Colors.amberAccent),
              _item(
                  'pause',
                  session.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  session.isPaused ? 'Resume Run' : 'Pause Run',
                  Colors.orangeAccent),
              const PopupMenuDivider(),
              _header('DISPLAY'),
              _toggle('effects', Icons.auto_awesome_rounded, 'Effects',
                  VisualPrefs.notifier.value.showEffectsPanel),
              _toggle('panels', Icons.view_agenda_rounded, 'Panels',
                  VisualPrefs.notifier.value.showDashboards),
              const PopupMenuDivider(),
              _header('SETTINGS'),
              _item('themes', Icons.palette_rounded, 'Themes',
                  Colors.pinkAccent),
              _item('settings', Icons.settings_rounded, 'Settings',
                  Colors.cyanAccent),
              const PopupMenuDivider(),
              if (session.myRole == MpRole.sidekick)
                _item('leave', Icons.bluetooth_disabled, 'Leave Multiplayer',
                    Colors.lightBlueAccent),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmLeave(BuildContext context, MpSession session) {
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E122E),
        title: const GoopText('Leave multiplayer?'),
        content: const GoopText(
            'You disconnect; your partner keeps their run.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: const GoopText('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dctx).pop();
              session.cancel();
            },
            child: const GoopText('LEAVE',
                style: TextStyle(color: Colors.lightBlueAccent)),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _header(String text) => PopupMenuItem<String>(
        enabled: false,
        height: 26,
        child: GoopText(text,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Colors.white.withValues(alpha: 0.35))),
      );

  PopupMenuItem<String> _toggle(
          String v, IconData icon, String label, bool isOn) =>
      PopupMenuItem<String>(
        value: v,
        child: Row(children: [
          Icon(icon, size: 18,
              color: isOn ? AppTheme.flair.primary : Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: GoopText(label,
                style: TextStyle(
                    fontSize: 13,
                    color: isOn ? Colors.white : Colors.white54)),
          ),
          Icon(
              isOn
                  ? Icons.toggle_on_rounded
                  : Icons.toggle_off_outlined,
              size: 20,
              color: isOn ? AppTheme.flair.primary : Colors.white24),
        ]),
      );

  PopupMenuItem<String> _item(
          String v, IconData icon, String label, Color c) =>
      PopupMenuItem<String>(
        value: v,
        child: Row(children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 10),
          GoopText(label),
        ]),
      );

  void _onMenu(BuildContext context, String v, MpSession session) {
    Haptics.selection();
    switch (v) {
      case 'shrines':
        Navigator.push(context, fastRoute(const ShrinePickerScreen()));
      case 'codex':
        Navigator.push(context, fastRoute(const CodexScreen()));
      case 'reset_p1':
        _confirmResetSlot(context, session, PlayerSlot.main);
      case 'reset_p2':
        _confirmResetSlot(context, session, PlayerSlot.coop);
      case 'themes':
        Navigator.push(
            context, fastRoute(const ExperienceStudioScreen()));
      case 'settings':
        Navigator.push(context, fastRoute(const SettingsScreen()));
      case 'leave':
        _confirmLeave(context, session);
      case 'dice':
        showDiceRollDialog(context);
      case 'pause':
        if (session.isPaused) {
          session.resume();
        } else {
          session.pause();
        }
      case 'surprise':
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: const Color(0xFF140B22),
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(18))),
          builder: (_) => const SurpriseSheet(),
        );
      case 'effects':
        VisualPrefs.setShowEffectsPanel(
            !VisualPrefs.notifier.value.showEffectsPanel);
      case 'panels':
        VisualPrefs.setShowDashboards(
            !VisualPrefs.notifier.value.showDashboards);
    }
  }

  void _confirmResetSlot(
      BuildContext context, MpSession session, PlayerSlot target) {
    final isMainSlot = target == PlayerSlot.main;
    final isMyPage = (session.myRole == MpRole.main) == isMainSlot;
    showDialog<void>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E122E),
        title: GoopText(
            isMyPage ? 'Reset your items?' : 'Reset partner items?'),
        content: const GoopText('Clears all guns and items for this player.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(),
            child: const GoopText('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dctx).pop();
              if (isMyPage) {
                context.read<RunProvider>().clearInventory(slot: target);
              } else {
                session.sendPeerClear();
              }
            },
            child: const GoopText('RESET',
                style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  /// Returns the highest DPS among this slot's guns — same
  /// effective-dps rule as the classic header (Gunderfury scales
  /// with its tracked level).
  double _slotTopDps(RunProvider p, PlayerSlot slot) {
    final player =
        slot == PlayerSlot.main ? p.runState.main : p.runState.coop;
    if (player == null || player.guns.isEmpty) return 0.0;
    double effectiveDps(Gun g) => g.name.toLowerCase() == 'gunderfury'
        ? g.getDynamicDps(gunderLevel: p.gunderfuryLevel)
        : g.dpsValue;
    return player.guns.map(effectiveDps).reduce((a, b) => a > b ? a : b);
  }

  void _showDamageCalcSheet(BuildContext context, PlayerSlot slot) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.flair.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => DamageCalcSheet(slot: slot),
    );
  }
}

class _PanelStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double sf;
  final VoidCallback onTap;
  const _PanelStat({
    required this.label,
    required this.value,
    required this.color,
    required this.sf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2 * sf),
        padding:
            EdgeInsets.symmetric(horizontal: 8 * sf, vertical: 5 * sf),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GoopText(label,
                style: TextStyle(
                    fontSize: 7.5 * sf,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: color.withValues(alpha: 0.75))),
            GoopText(value,
                style: TextStyle(
                    fontSize: 14 * sf,
                    fontWeight: FontWeight.w900,
                    color: color)),
          ],
        ),
      ),
    );
  }
}
