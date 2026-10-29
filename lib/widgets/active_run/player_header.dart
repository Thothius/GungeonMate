import '../../theme/tokens.dart';
import 'package:flutter/material.dart';
import '../../services/app_theme.dart';
import '../../services/haptics.dart';
import '../../services/mp_session.dart';
import '../paradox/chat_sheet.dart';
import '../paradox/avatar_frame.dart';
import '../../models/multiplayer_messages.dart';
import '../../services/goop_talk_engine.dart';
import '../../utils/asset_paths.dart';

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
  /// Optional opacity multiplier for showing a peer tab as stale.
  final double opacity;
  /// Gungeoneer name used for the map icon lookup. In local co-op this
  /// is the same as [characterName]. In MP, [characterName] is the
  /// lobby nickname (shown as text) while [gungeoneerName] is the
  /// actual character (used for the map icon). Falls back to
  /// [characterName] when null.
  final String? gungeoneerName;
  /// Custom avatar (`id` or `id:frame`) — replaces the gungeoneer map
  /// icon when set, matching the paradox panel's FramedAvatar.
  final String? avatarId;
  const BigPlayerTab({super.key,
    required this.active,
    required this.slotLabel,
    required this.characterName,
    required this.onTap,
    this.opacity = 1.0,
    this.gungeoneerName,
    this.avatarId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final onSurface = colorScheme.onSurface;
    return Opacity(
      opacity: opacity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.all(Radii.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.all(Radii.sm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: active
                  ? primary.withValues(alpha: 0.15)
                  : onSurface.withValues(alpha: 0.02),
              borderRadius: BorderRadius.all(Radii.sm),
              border: Border.all(
                color: active
                    ? primary.withValues(alpha: 0.5)
                    : onSurface.withValues(alpha: 0.06),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gungeoneer map icon (9x9px pixel art, scaled up crisp).
                // Use gungeoneerName for the icon lookup (falls back to
                // characterName for local co-op where they're the same).
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: avatarId != null && avatarId!.isNotEmpty
                      ? FramedAvatar(id: avatarId!, size: 36, radius: 8)
                      : () {
                    final iconName = gungeoneerName ?? characterName;
                    return Image.asset(
                      gungeoneerMapIconPath(iconName) ??
                          localGungeoneerIcon(iconName),
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      cacheWidth: 72,
                      cacheHeight: 72,
                      errorBuilder: (_, __, ___) => Image.asset(
                        localGungeoneerIcon(iconName),
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        cacheWidth: 72,
                        cacheHeight: 72,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    );
                  }(),
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
                              : onSurface.withValues(alpha: 0.55),
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
                                ? onSurface
                                : onSurface.withValues(alpha: 0.82),
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
/// Replaces both the generic PlayerSwitcher and the old status bar.
///
/// The peer tab dims when disconnected to signal stale data.
/// The status strip pulses when reconnecting and is tappable to
/// cancel the session when disconnected.
class MpHeader extends StatefulWidget {
  final int currentPage;
  final bool hasCoop;
  final MpSession session;
  final void Function(int) onPick;
  const MpHeader({super.key,
    required this.currentPage,
    required this.hasCoop,
    required this.session,
    required this.onPick,
  });

  @override
  State<MpHeader> createState() => _MpHeaderState();
}

class _MpHeaderState extends State<MpHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  MpPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    widget.session.addListener(_onSessionChanged);
    _lastPhase = widget.session.phase;
    _syncPulse(widget.session.phase);
  }

  @override
  void didUpdateWidget(MpHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_onSessionChanged);
      widget.session.addListener(_onSessionChanged);
      _syncPulse(widget.session.phase);
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) return;
    final phase = widget.session.phase;
    if (phase != _lastPhase) {
      _lastPhase = phase;
      _syncPulse(phase);
      setState(() {});
    }
  }

  void _syncPulse(MpPhase phase) {
    final shouldPulse =
        phase == MpPhase.connecting || phase == MpPhase.disconnected;
    if (shouldPulse) {
      if (!_pulseCtrl.isAnimating) _pulseCtrl.repeat(reverse: true);
    } else {
      if (_pulseCtrl.isAnimating) _pulseCtrl.stop();
      _pulseCtrl.value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = AppTheme.flair;
    final session = widget.session;
    final isConnected = session.isConnected;
    final isDisconnected = session.phase == MpPhase.disconnected;
    final isConnecting = session.phase == MpPhase.connecting;
    final statusColor = isConnected
        ? MpColors.connected
        : isConnecting || isDisconnected
            ? MpColors.reconnecting
            : MpColors.danger;

    String statusText;
    if (isConnected) {
      statusText = 'Connected';
    } else if (isDisconnected) {
      statusText = 'Reconnecting…';
    } else if (isConnecting) {
      statusText = 'Connecting…';
    } else {
      statusText = 'Offline';
    }

    // Tab 0 = main slot, Tab 1 = coop slot.
    final myRole = session.myRole;
    final iAmMain = myRole == MpRole.main;
    final tab0Nick =
        iAmMain ? session.myNickname : (session.peerNickname ?? 'Main');
    final tab1Nick =
        !iAmMain ? session.myNickname : (session.peerNickname ?? 'Cultist');
    final tab0Char =
        iAmMain ? session.myCharacterName : (session.peerCharacterName ?? 'The Cultist');
    final tab1Char =
        !iAmMain ? session.myCharacterName : (session.peerCharacterName ?? 'The Cultist');
    final peerDimmed = !isConnected && !isConnecting;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Status strip ──────────────────────────────────────────
            // Tappable when disconnected — opens a cancel/retry dialog.
            GestureDetector(
              onTap: isDisconnected ? () => _showDisconnectedOptions(context) : null,
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
                    // Pulsing status dot
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        final scale = 0.7 + _pulseCtrl.value * 0.3;
                        final glowAlpha = 0.2 + _pulseCtrl.value * 0.3;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: glowAlpha),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GoopText(
                        statusText.toUpperCase(),
                        style: TextStyle(
                          fontSize: FontSizes.labelSmall,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: statusColor,
                        ),
                      ),
                    ),
                    // Run timer + health — hidden under ~460px (the
                    // strip's trailing cluster would overflow; the
                    // paradox bar compresses the same way).
                    if (MediaQuery.sizeOf(context).width > 460) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.timer_outlined,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GoopText(_fmtElapsed(session.runElapsedMs),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.55))),
                    ),
                    // Health chip — paradox bar parity.
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ValueListenableBuilder<int>(
                        valueListenable: session.healthListenable,
                        builder: (_, health, __) => Icon(
                            Icons.favorite_rounded,
                            size: 14,
                            color: health > 4
                                ? Colors.redAccent.withValues(alpha: 0.9)
                                : health > 0
                                    ? Colors.redAccent.withValues(alpha: 0.6)
                                    : Colors.white24),
                      ),
                    ),
                    ],
                    // MSG entry — parity with the paradox panel. Tap
                    // opens the shared convo sheet; badge shows unread.
                    ValueListenableBuilder<int>(
                      valueListenable: session.unreadChat,
                      builder: (_, unread, __) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Badge(
                          isLabelVisible: unread > 0,
                          label: Text('$unread',
                              style: const TextStyle(fontSize: 9)),
                          child: GestureDetector(
                            onTap: () => showParadoxChatSheet(context),
                            child: Icon(Icons.forum_rounded,
                                size: 18,
                                color: unread > 0
                                    ? const Color(0xFF00E676)
                                    : Colors.white.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                    ),
                    // Show a cancel hint when disconnected
                    if (isDisconnected)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: statusColor.withValues(alpha: 0.6)),
                      ),
                  ],
                ),
              ),
            ),
            // ── Player tabs (only when the coop slot exists) ──────────
            if (widget.hasCoop) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: BigPlayerTab(
                      active: widget.currentPage == 0,
                      slotLabel: 'P1',
                      characterName: tab0Nick,
                      gungeoneerName: tab0Char,
                      avatarId: iAmMain
                          ? session.avatarId
                          : session.peerAvatarId,
                      onTap: () => widget.onPick(0),
                      opacity: peerDimmed && !iAmMain ? 0.45 : 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: BigPlayerTab(
                      active: widget.currentPage == 1,
                      slotLabel: 'P2',
                      characterName: tab1Nick,
                      gungeoneerName: tab1Char,
                      avatarId: iAmMain
                          ? session.peerAvatarId
                          : session.avatarId,
                      onTap: () => widget.onPick(1),
                      opacity: peerDimmed && iAmMain ? 0.45 : 1.0,
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

  String _fmtElapsed(int ms) {
    final s = ms ~/ 1000;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  void _showDisconnectedOptions(BuildContext context) {
    Haptics.selection();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.flair.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radii.lg),
          side: BorderSide(
              color: MpColors.reconnecting.withValues(alpha: 0.3),
              width: 1.5),
        ),
        icon: const Icon(Icons.wifi_off_rounded,
            size: 32, color: MpColors.reconnecting),
        title: const GoopText('Reconnecting…',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: GoopText(
          'Trying to reconnect to your partner automatically.\n\n'
          'Your run is preserved. You can keep playing — '
          'changes will sync when the connection returns.',
          style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const GoopText('DISMISS',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: MpColors.danger,
              side: const BorderSide(color: MpColors.danger, width: 1.5),
            ),
            icon: const Icon(Icons.close, size: 16),
            label: const GoopText('END SESSION',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              widget.session.cancel();
            },
          ),
        ],
      ),
    );
  }
}
