part of '../active_run_screen.dart';

// MP session handlers extracted from _ActiveRunScreenState (Phase 5j) —
// same library; on-clause gives context/widget/mounted/setState.

mixin _ActiveRunMpHandlers on State<ActiveRunScreen> {
  PageController get _page;
  int get _currentPage;

  MpSession? _mpSession;

  String? _lastShownError;

  // Emote overlay state — kiss/slap animations shown via root Overlay.
  Timer? _emoteTimer;

  OverlayEntry? _emoteOverlayEntry;

  void _handleIncomingDiceChallenge(String challengerName) {
    if (!mounted) return;
    _mpSession?.onDiceCancel = _handleIncomingDiceCancel;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      routeSettings: const RouteSettings(name: '__dice_challenge'),
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppTheme.flair.card,
            title: const GoopText(
              '\u{1F3B2} Gunfortuna Challenge! \u{1F3B2}',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFD54F),
                letterSpacing: 1.0,
              ),
            ),
            content: GoopText(
              '$challengerName challenges you to a Gunfortuna Dice Roll! Do you accept the challenge?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _mpSession?.onDiceCancel = null;
                  Navigator.pop(ctx);
                  _mpSession?.sendDiceDecline();
                },
                child: const GoopText(
                  'DECLINE',
                  style: TextStyle(color: Colors.white38),
                ),
              ),
              FilledButton(
                onPressed: () {
                  _mpSession?.onDiceCancel = null;
                  Navigator.pop(ctx);
                  _mpSession?.sendDiceAccept();
                  showDiceRollDialog(context, isChallenged: true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: Colors.black,
                ),
                child: const GoopText(
                  'ACCEPT',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
    );
  }

  void _handleIncomingDiceCancel() {
    if (!mounted) return;
    // Pop ONLY a dice-related route — blindly popping the top route
    // could close an unrelated sheet while leaving the dice dialog
    // stuck open (the reported can't-close bug).
    final navigator = Navigator.of(context);
    navigator.popUntil((route) {
      final name = route.settings.name;
      return name == null || !name.startsWith('__dice');
    });
  }

  /// Tab tap handler for MP — if the user taps their own tab while
  /// already viewing it, open the emote menu. Otherwise navigate.
  void mpTabTap(int i) {
    final session = _mpSession;
    if (session == null) return;
    final myMpPage = session.myRole == MpRole.main ? 0 : 1;
    if (i == myMpPage && _currentPage == myMpPage) {
      _showEmoteMenu();
    } else {
      if (!mounted || !_page.hasClients) return;
      _page.animateToPage(
        i,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  }

  void _showEmoteMenu() {
    final session = _mpSession;
    if (session == null || !session.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: GoopText('Not connected: can\'t send emote'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Haptics.selection();
    final peerName = session.peerNickname ?? 'peer';
    final flair = AppTheme.flair;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: flair.card,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder:
          (ctx) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                GoopText(
                  'Send to $peerName',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMedium,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _EmoteButton(
                      icon: Icons.favorite,
                      label: 'Kiss',
                      color: Colors.pinkAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        session.sendEmote('kiss');
                        Haptics.light();
                      },
                    ),
                    _EmoteButton(
                      icon: Icons.sentiment_very_dissatisfied,
                      label: 'Slap',
                      color: Colors.orangeAccent,
                      onTap: () {
                        Navigator.pop(ctx);
                        session.sendEmote('slap');
                        Haptics.heavy();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 8),
                // Quick session teardown
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmEndSession();
                  },
                  icon: Icon(
                    Icons.logout_rounded,
                    size: 16,
                    color: MpColors.danger.withValues(alpha: 0.7),
                  ),
                  label: GoopText(
                    'End MP Session',
                    style: TextStyle(
                      fontSize: FontSizes.labelMedium,
                      fontWeight: FontWeight.w700,
                      color: MpColors.danger.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _confirmEndSession() {
    Haptics.selection();
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: AppTheme.flair.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radii.lg),
              side: BorderSide(
                color: MpColors.danger.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            icon: const Icon(
              Icons.logout_rounded,
              size: 32,
              color: MpColors.danger,
            ),
            title: const GoopText(
              'End Multiplayer Session?',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: GoopText(
              'This will disconnect from your partner. Your run data is preserved.',
              style: TextStyle(
                fontSize: 12.5 * Responsive.factor(context),
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const GoopText(
                  'CANCEL',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: MpColors.danger,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _mpSession?.cancel();
                },
                child: const GoopText(
                  'END SESSION',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
    );
  }

  void _handleIncomingEmote(String from, String action) {
    if (!mounted) return;
    // Unknown actions from future versions are ignored gracefully.
    final duration = switch (action) {
      'kiss' => const Duration(seconds: 6),
      'slap' => const Duration(seconds: 2),
      _ => null,
    };
    if (duration == null) return;
    Haptics.light();
    // Cancel any previous emote timer + overlay before showing a new one.
    _emoteTimer?.cancel();
    _emoteOverlayEntry?.remove();
    final entry = OverlayEntry(
      builder:
          (_) => IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child:
                  action == 'slap'
                      ? SlapAnimation(from: from)
                      : KissAnimation(from: from),
            ),
          ),
    );
    _emoteOverlayEntry = entry;
    Overlay.of(context).insert(entry);
    _emoteTimer = Timer(duration, () {
      _emoteTimer = null;
      if (!mounted) return;
      entry.remove();
      _emoteOverlayEntry = null;
    });
  }

  void _handleIncomingGift(String kind, String name) {
    if (!mounted) return;
    Haptics.success();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final icon = kind == 'gun' ? Icons.gps_fixed : Icons.inventory_2_rounded;
    final label = kind == 'gun' ? 'Received gun' : 'Received item';
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: MpColors.connected, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: GoopText(
                '$label: $name',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.flair.card,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radii.md),
          side: const BorderSide(color: MpColors.connected, width: 1.5),
        ),
      ),
    );
  }

  void _onMpSessionChanged() {
    if (!mounted || _mpSession == null) return;
    final phase = _mpSession!.phase;
    final error = _mpSession!.error;

    // Reset error tracking when leaving the error phase so the
    // same error can be re-shown after a retry.
    if (phase != MpPhase.error) {
      _lastShownError = null;
    }

    if (phase == MpPhase.error && error != null && error != _lastShownError) {
      _lastShownError = error;
      _showErrorDialog(error);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent),
                SizedBox(width: 12),
                GoopText('Connection Error'),
              ],
            ),
            content: GoopText(message),
            actions: [
              TextButton(
                onPressed: () {
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
                child: const GoopText('Save Session'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const GoopText('Dismiss'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const GoopText('Retry Reconnect'),
                onPressed: () {
                  Navigator.pop(context);
                  _mpSession?.reconnect();
                },
              ),
            ],
          ),
    );
  }
}
