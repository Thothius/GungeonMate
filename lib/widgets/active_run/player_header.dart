import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../glass_container.dart';
import '../../services/app_theme.dart';
import '../../services/multiplayer_session.dart';
import '../../models/multiplayer_messages.dart';
import '../../services/goop_talk_engine.dart';
import 'summary_tab.dart';

/// Two-up player switcher used when local co-op is active (not MP).
/// Each tab is equal-width, large enough to read at a glance, and shows
/// the slot label (P1 / P2) above the character's name.
class PlayerSwitcher extends StatelessWidget {
  final int currentPage;
  final String mainName;
  final String coopName;
  final void Function(int) onPick;
  const PlayerSwitcher({super.key, 
    required this.currentPage,
    required this.mainName,
    required this.coopName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: BigPlayerTab(
                active: currentPage == 0,
                slotLabel: 'P1',
                characterName: mainName,
                onTap: () => onPick(0),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BigPlayerTab(
                active: currentPage == 1,
                slotLabel: 'P2',
                characterName: coopName,
                onTap: () => onPick(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sleek tall pill used by both local-coop and MP player switchers.
/// Two-line layout: slot/role label on top, name on bottom. Active state
/// fills with primary tint; inactive is a hairline outline on near-black.
class BigPlayerTab extends StatelessWidget {
  final bool active;
  final String slotLabel;
  final String characterName;
  final VoidCallback onTap;
  /// Optional leading green dot ("you are this player on this device"
  /// indicator for MP).
  final bool showYouDot;
  /// Optional opacity multiplier for showing a peer tab as stale.
  final double opacity;
  const BigPlayerTab({super.key, 
    required this.active,
    required this.slotLabel,
    required this.characterName,
    required this.onTap,
    this.showYouDot = false,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: active
                  ? primary.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? primary.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.06),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showYouDot)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GoopText(
                        slotLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                          color: active
                              ? primary
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: GoopText(
                          characterName,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight:
                                active ? FontWeight.w800 : FontWeight.w600,
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.82),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Unified MP header shown when a multiplayer session is active.
/// Replaces both the generic PlayerSwitcher and the old status bar:
///
///  ΓöîΓöÇ slim status strip ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ session name ΓöÇΓöÉ
///  Γöé ΓùÅ Connected                               BraveWolf          Γöé
///  ΓööΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÿ
///  ΓöîΓöÇ nick tab ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÉ ΓöîΓöÇ nick tab ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÉ ΓöîΓöÇ Summary ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÉ
///  Γöé ΓùÅ YourNick        Γöé Γöé   PeerNick           Γöé Γöé  Γëí Summary    Γöé
///  ΓööΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÿ ΓööΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÿ ΓööΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÿ
///
/// The peer tab dims when disconnected to signal stale data.
class MpHeader extends StatelessWidget {
  final int currentPage;
  final bool hasCoop;
  final MultiplayerSession session;
  final void Function(int) onPick;
  const MpHeader({super.key, 
    required this.currentPage,
    required this.hasCoop,
    required this.session,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flair;
    final isConnected = session.isConnected;
    final isSearching = session.status == MpStatus.searching;
    final isReconnecting = isSearching && session.canReconnect;
    final isAutoRetrying = session.isAutoReconnecting;
    final statusColor = isConnected
        ? const Color(0xFF00E676) // vibrant green
        : (isSearching || session.status == MpStatus.handshaking)
            ? const Color(0xFFFF9100) // warm orange
            : const Color(0xFFFF1744); // sharp red

    final showManualReconnect = session.canReconnect &&
        (session.status == MpStatus.disconnected ||
            session.status == MpStatus.error) &&
        !session.isAutoReconnecting;

    String statusText;
    if (isConnected) {
      statusText = 'Connected';
    } else if (isReconnecting) {
      final att = session.autoReconnectAttempts;
      statusText = att > 0 ? 'Reconnecting (attempt $att)ΓÇª' : 'ReconnectingΓÇª';
    } else if (isSearching) {
      statusText = 'SearchingΓÇª';
    } else if (session.status == MpStatus.handshaking) {
      statusText = 'ConnectingΓÇª';
    } else if (isAutoRetrying) {
      statusText = 'Retrying (attempt ${session.autoReconnectAttempts})ΓÇª';
    } else {
      statusText = 'Offline';
    }

    // Tab 0 = main slot, Tab 1 = coop slot.
    // Show the lobby nickname of whoever owns that slot.
    final myRole = session.myRole;
    final iAmMain = myRole == MpRole.main;
    final tab0Nick =
        iAmMain ? session.myNickname : (session.peerNickname ?? 'Main');
    final tab1Nick =
        !iAmMain ? session.myNickname : (session.peerNickname ?? 'Cultist');
    // "You" indicator: green dot on the tab that belongs to this device.
    final tab0IsYou = iAmMain;
    final tab1IsYou = !iAmMain;
    // Dim the peer tab when disconnected so it's clear their data may be stale.
    final peerDimmed = !isConnected && !isSearching &&
        session.status != MpStatus.handshaking;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ΓöÇΓöÇ Status strip (Clickable & Taller) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
            InkWell(
              onTap: () => _showMpDiagnosticsDialog(context),
              borderRadius: BorderRadius.circular(f.chipRadius),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(f.chipRadius),
                  border:
                      Border.all(color: statusColor.withValues(alpha: 0.25), width: 1.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GoopText(
                            statusText.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: statusColor,
                            ),
                          ),
                          if (session.error != null && !isConnected) ...[
                            const SizedBox(height: 2),
                            GoopText(
                              session.error!,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showManualReconnect)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 24),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Colors.lightBlueAccent,
                        ),
                        icon: const Icon(Icons.bluetooth_searching, size: 13),
                        label: const GoopText('Reconnect',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700)),
                        onPressed: () => session.reconnect(),
                      )
                    else
                      // Session name ΓÇö stays constant across reconnects so
                      // both players can verbally confirm they're paired.
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GoopText(
                            session.sessionName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: isConnected
                                  ? Colors.amber
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.settings_outlined,
                            size: 14,
                            color: isConnected ? Colors.amber : Colors.white30,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // ΓöÇΓöÇ Player tabs (only when the coop slot exists) ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
            // P1 + P2 equal-width tabs, plus a compact Summary tab.
            // The peer tab dims when disconnected.
            if (hasCoop) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: BigPlayerTab(
                      active: currentPage == 0,
                      slotLabel: 'P1',
                      characterName: tab0Nick,
                      onTap: () => onPick(0),
                      showYouDot: tab0IsYou,
                      opacity: peerDimmed && !tab0IsYou ? 0.45 : 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: BigPlayerTab(
                      active: currentPage == 1,
                      slotLabel: 'P2',
                      characterName: tab1Nick,
                      onTap: () => onPick(1),
                      showYouDot: tab1IsYou,
                      opacity: peerDimmed && !tab1IsYou ? 0.45 : 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SummaryTab(
                      active: currentPage == 2,
                      onTap: () => onPick(2),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showMpDiagnosticsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121214),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final f = AppTheme.flair;
        return Consumer<MultiplayerSession>(
          builder: (context, liveSession, _) {
            final isConnected = liveSession.isConnected;
            final isMain = liveSession.myRole == MpRole.main;
            final code = liveSession.pinCode ?? 'N/A';
            final lastTouch = liveSession.lastPeerTouchMs;
            final now = DateTime.now().millisecondsSinceEpoch;
            final diff = lastTouch > 0 ? (now - lastTouch) : 999999;

            String strengthText;
            Color strengthColor;
            IconData strengthIcon;
            if (!isConnected) {
              strengthText = 'Offline';
              strengthColor = const Color(0xFFEF5350);
              strengthIcon = Icons.signal_cellular_off;
            } else if (diff <= 3500) {
              strengthText = 'Excellent';
              strengthColor = const Color(0xFF66BB6A);
              strengthIcon = Icons.signal_cellular_alt;
            } else if (diff <= 7500) {
              strengthText = 'Good';
              strengthColor = const Color(0xFF9CCC65);
              strengthIcon = Icons.signal_cellular_alt;
            } else if (diff <= 15000) {
              strengthText = 'Fair';
              strengthColor = const Color(0xFFFFB74D);
              strengthIcon = Icons.signal_cellular_alt;
            } else {
              strengthText = 'Poor';
              strengthColor = const Color(0xFFEF5350);
              strengthIcon = Icons.signal_cellular_alt;
            }

            return SafeArea(
              child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upper drag bar indicator for premium panel feel
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with pulsing terminal indicator
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                          boxShadow: [
                            BoxShadow(
                              color: (isConnected ? const Color(0xFF66BB6A) : const Color(0xFFEF5350)).withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const GoopText(
                        'GUNFORTUNA LINK PANEL',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.white54),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Overview grid: connection type, strength, role
                  Row(
                    children: [
                      Expanded(
                        child: _buildPanelMetric(
                          label: 'CONN TYPE',
                          value: isConnected ? 'Wi-Fi / BT P2P' : 'None',
                          icon: Icons.wifi_tethering_rounded,
                          color: isConnected ? Colors.cyanAccent : Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPanelMetric(
                          label: 'STRENGTH',
                          value: strengthText,
                          icon: strengthIcon,
                          color: strengthColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPanelMetric(
                          label: 'MY ROLE',
                          value: isMain ? 'Main Host' : 'Sidekick',
                          icon: isMain ? Icons.star_rounded : Icons.handshake_rounded,
                          color: isMain ? Colors.amber : Colors.purpleAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Connection Code block
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const GoopText(
                                'SESSION PIN CODE',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GoopText(
                                isMain ? 'Share with your Sidekick player' : 'Connected to host session',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                          ),
                          child: GoopText(
                            code,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Simplified stream-lined log console
                  Row(
                    children: [
                      Icon(Icons.terminal_rounded, size: 14, color: Colors.greenAccent),
                      const SizedBox(width: 6),
                      GoopText(
                        'CONSOLE LOGS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.greenAccent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 110,
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0F),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: liveSession.connectionLogs.isEmpty
                        ? const Center(
                            child: GoopText(
                              'CONSOLE IDLE',
                              style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )
                        : ListView.builder(
                            itemCount: liveSession.connectionLogs.length,
                            reverse: true, // Newest logs on top
                            itemBuilder: (context, idx) {
                              final log = liveSession.connectionLogs[liveSession.connectionLogs.length - 1 - idx];
                              // Streamline and make them shorter & direct
                              final cleanLog = log
                                  .replaceAll('[SYSTEM]', '[SYS]')
                                  .replaceAll('Nearby Connections', 'Nearby')
                                  .replaceAll('established', 'OK')
                                  .replaceAll('successfully', 'OK')
                                  .replaceAll('Advertising failed: ', 'ERR: ')
                                  .replaceAll('Discovery failed: ', 'ERR: ')
                                  .replaceAll('Initiating reconnection sequence...', '[SYS] Reconnecting...')
                                  .replaceAll('Disconnecting from active peer by user request.', '[SYS] Disconnected by user.')
                                  .replaceAll('Drop detected during active run! Starting automatic reconnect sequence...', '[SYS] Link lost! Auto-retrying...')
                                  .replaceAll('Starting advertising/discovery...', '[SYS] Starting search...')
                                  .replaceAll('Connected to peer:', 'Connected:')
                                  .replaceAll('Disconnected from peer:', 'Disconnected:')
                                  .replaceAll('Sending handshake snapshot...', 'Handshake sent.')
                                  .replaceAll('Received handshake snapshot...', 'Handshake received.');

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: GoopText(
                                  cleanLog,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 10.5,
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 18),

                  // Actions row
                  Row(
                    children: [
                      // Reconnect / Fix
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: f.primary,
                            side: BorderSide(color: f.primary.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.sync_problem_rounded, size: 16),
                          label: const GoopText('FIX LINK', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                          onPressed: isConnected ? null : () {
                            liveSession.requestReconnectHub();
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Save Session
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: f.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.save_rounded, size: 16),
                          label: const GoopText('SAVE RUN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                          onPressed: () async {
                            await liveSession.saveCurrentSession();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: GoopText('Run saved'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPanelMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final flair = AppTheme.flair;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: flair.card,
      opacity: 0.85, // perfect balance of see-through & readability
      border: Border.all(color: color.withValues(alpha: 0.24), width: 1.2),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              GoopText(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.65),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GoopText(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}