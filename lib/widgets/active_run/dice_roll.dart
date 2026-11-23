import '../../theme/tokens.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../scale_button.dart';
import '../../services/haptics.dart';
import '../../services/app_theme.dart';
import '../../services/mp_session.dart';
import '../../services/goop_talk_engine.dart';
import '../../utils/reduce_motion.dart';

import '../bug_report/bug_report_sheet.dart';
import '../../models/bug_report.dart';
part 'dice_roll/dice_roll_logic.dart';
part 'dice_roll/dice_roll_parts.dart';

// =============================================================================
// Gunfortuna Dice Roll dialog / challenge
// =============================================================================

void showDiceRollDialog(BuildContext context, {bool isChallenged = false}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    // Named so a peer's cancel can target this route specifically
    // instead of blindly popping whatever is on top.
    routeSettings: const RouteSettings(name: '__dice_roll'),
    builder: (_) => DiceRollDialog(isChallenged: isChallenged),
  );
}

enum DiceStatus { idle, challenging, rollingScreen, rolling, finished }

class DiceRollDialog extends StatefulWidget {
  final bool isChallenged;

  /// Test hook — when non-empty, each entry replaces one random roll
  /// (consumed in order, ties rerolls included). Never set in prod.
  @visibleForTesting
  final List<int>? debugRollValues;

  const DiceRollDialog({
    super.key,
    required this.isChallenged,
    this.debugRollValues,
  });

  @override
  State<DiceRollDialog> createState() => DiceRollDialogState();
}

class DiceRollDialogState extends State<DiceRollDialog>
    with TickerProviderStateMixin, _DiceRollLogic {
  @override
  Widget build(BuildContext context) {
    final connected = _mp.isActive && _mp.isConnected;
    final f = AppTheme.flair;
    final prefs = VisualPrefs.notifier.value;
    final myDiceStyle = _getDiceStyle(prefs.customDiceType, f);
    // Close is ALWAYS available — closing during an active challenge
    // or roll sends a cancel to the peer so they're never stuck on a
    // "waiting" screen they can't dismiss (the old stuck-popup bug).

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        // System-back dismiss during an active flow also notifies the
        // peer — same guarantee as the close button.
        if (didPop &&
            (_status == DiceStatus.challenging ||
                _status == DiceStatus.rollingScreen ||
                _status == DiceStatus.rolling)) {
          _mp.sendDiceCancel();
        }
      },
      child: Dialog(
        backgroundColor: f.card.withValues(alpha: 0.98),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.xl,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radii.lg),
          side: BorderSide(color: f.primary, width: 2.0),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.casino_rounded,
                                color: f.primary,
                                size: 26,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: GoopText(
                                  'GUNFORTUNA\'S DUEL',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: FontSizes.titleMedium,
                                    fontWeight: FontWeight.w900,
                                    color: f.primary,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Report a bug',
                              icon: Icon(
                                Icons.bug_report_outlined,
                                color: Colors.deepOrangeAccent,
                                size: 20,
                              ),
                              onPressed: () {
                                BugReportSheet.show(
                                  context,
                                  const BugReportContext(
                                    kind: BugReportKind.bug,
                                    screen: 'Dice Roller',
                                  ),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Close',
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white38,
                                size: 20,
                              ),
                              onPressed: () {
                                // Any mid-flow close notifies the peer so
                                // their dialog resolves instead of hanging.
                                if (_status == DiceStatus.challenging ||
                                    _status == DiceStatus.rollingScreen ||
                                    _status == DiceStatus.rolling) {
                                  _mp.sendDiceCancel();
                                }
                                Navigator.pop(context);
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Flavour text (Only show in idle state!)
                    if (_status == DiceStatus.idle) ...[
                      Container(
                        padding: const EdgeInsets.all(Insets.md),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: const GoopText(
                          '“Gunfortuna, the celestial bullet-goddess of chance, spins the cylinders of fate. When co-op partners clash over loot, let her dice decide who walks away with the prize.”',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.white54,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Content body
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                          child: child,
                        );
                      },
                      child: _buildCurrentBody(connected, myDiceStyle, f),
                    ),
                    ],
                  ),
                ),
              ),
              // Particle Layer Paint
              if (_particles.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        key: _particleKey,
                        painter: DialogParticlePainter(particles: _particles),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _die(DiceStyle style, {required int value, required bool rolling}) {
    return DiceWidget(
      value: value,
      isRolling: rolling,
      infiniteController: _infiniteController,
      style: style,
      size: 104,
    );
  }

  Widget _rollButton(ThemeFlair f, {String label = 'ROLL'}) {
    return ScaleButton(
      onTap: _startRolling,
      child: IgnorePointer(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.casino_outlined, size: 18),
            label: GoopText(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: f.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radii.sm),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _announcementText() {
    if (_announcement.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: GoopText(
        _announcement,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.amberAccent,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCurrentBody(bool connected, DiceStyle diceStyle, ThemeFlair f) {
    // ── Idle: solo entry or connected pre-choice ──────────────────
    if (_status == DiceStatus.idle) {
      if (connected) {
        return Column(
          key: const ValueKey('idle_connected'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GoopText(
              'Challenge your partner to a duel of fate — one sacred die decides who walks away with Gunfortuna\'s favor. Ties reroll automatically!',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.white70,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ScaleButton(
              onTap: _sendChallenge,
              child: IgnorePointer(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    label: const GoopText(
                      'CHALLENGE PARTNER',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: f.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radii.sm),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: ScaleButton(
                onTap: _rollSolo,
                child: IgnorePointer(
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(
                        vertical: Insets.sm,
                      ),
                    ),
                    child: const GoopText(
                      'or roll solo',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
      // Solo idle
      return Column(
        key: const ValueKey('solo_initial'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _die(diceStyle, value: 0, rolling: false)),
          const SizedBox(height: 18),
          const GoopText(
            'Throw Gunfortuna\'s sacred die to determine your fortune in Gungeon — one roll, fate revealed.',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white70,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _rollButton(f, label: 'ROLL THE DIE!'),
        ],
      );
    }

    // ── Challenge in flight ───────────────────────────────────────
    if (_status == DiceStatus.challenging) {
      return Column(
        key: const ValueKey('challenging'),
        children: [
          const SizedBox(height: 10),
          CircularProgressIndicator(color: Colors.amberAccent),
          const SizedBox(height: 16),
          const GoopText(
            'Waiting for partner to accept...',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _cancelChallenge,
            style: TextButton.styleFrom(foregroundColor: Colors.white38),
            child: const GoopText(
              'CANCEL CHALLENGE',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
        ],
      );
    }

    // ── Die spinning (auto-stops — no tap needed) ─────────────────
    if (_status == DiceStatus.rolling || _rolling) {
      return Column(
        key: const ValueKey('rolling_active'),
        children: [
          Center(child: _die(diceStyle, value: 0, rolling: true)),
          const SizedBox(height: 20),
          const GoopText(
            'THE DIE IS SPINNING!',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w900,
              color: Colors.white54,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          GoopText(
            _round > 1 ? 'Round $_round — fate rerolls!' : 'Fate decides…',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    // ── Duel screen: rolled and waiting for the peer ──────────────
    if (_status == DiceStatus.rollingScreen &&
        _myValue != 0 &&
        _peerValue == null) {
      return Column(
        key: const ValueKey('rolled_waiting'),
        children: [
          Center(child: _die(diceStyle, value: _myValue, rolling: false)),
          const SizedBox(height: 20),
          const GoopText(
            'ROLLED!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF66E07A),
            ),
          ),
          const SizedBox(height: 6),
          GoopText(
            'Your roll: $_myValue',
            style: const TextStyle(
              fontSize: FontSizes.bodyMedium,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.cyanAccent,
                ),
              ),
              const SizedBox(width: 10),
              GoopText(
                'Waiting for partner…',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),
          _announcementText(),
        ],
      );
    }

    // ── Duel screen: your roll — ready to roll (or tie-reroll) ────
    if (_status == DiceStatus.rollingScreen) {
      return Column(
        key: const ValueKey('rolling_screen'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _die(diceStyle, value: _myValue, rolling: false)),
          if (_round > 1) ...[
            const SizedBox(height: 10),
            GoopText(
              'ROUND $_round',
              style: const TextStyle(
                fontSize: FontSizes.labelSmall,
                fontWeight: FontWeight.w900,
                color: Colors.white38,
                letterSpacing: 2.0,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _rollButton(f),
          _announcementText(),
        ],
      );
    }

    // ── Finished: winner decided (or solo fate) ───────────────────
    if (_status == DiceStatus.finished) {
      final isMyVictory = _peerValue != null && _myValue > _peerValue!;
      final isPeerOnly = _peerValue != null && _myValue == 0;
      final isDraw = _peerValue != null && _myValue == _peerValue;
      final isSolo = _peerValue == null;

      final Color bannerColor =
          isSolo || isPeerOnly
              ? const Color(0xFFFFD54F) // Majestic Gold for solo fate
              : (isDraw
                  ? Colors.white54
                  : (isMyVictory ? Colors.greenAccent : Colors.redAccent));

      return Column(
        key: const ValueKey('finished_results'),
        children: [
          // Flavour Winner announcement
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Insets.lg,
              vertical: Insets.md,
            ),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: bannerColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: bannerColor.withValues(alpha: 0.08),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: GoopText(
              _announcement,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color:
                    bannerColor == Colors.white54 ? Colors.white : bannerColor,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Side-by-side die comparison
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Player 1 (You)
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.person, color: Colors.cyanAccent, size: 24),
                    const SizedBox(height: 4),
                    GoopText(
                      _mp.myNickname.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _die(diceStyle, value: _myValue, rolling: false),
                    const SizedBox(height: 6),
                    GoopText(
                      '$_myValue',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (_peerValue != null) ...[
                const GoopText(
                  'VS',
                  style: TextStyle(
                    fontSize: FontSizes.titleSmall,
                    fontWeight: FontWeight.w900,
                    color: Colors.white24,
                  ),
                ),
                // Player 2 (Peer)
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: Colors.pinkAccent,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      GoopText(
                        (_mp.peerNickname ?? 'Partner').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: FontSizes.labelSmall,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _die(diceStyle, value: _peerValue!, rolling: false),
                      const SizedBox(height: 6),
                      GoopText(
                        '$_peerValue',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (_round > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GoopText(
                'Decided on round $_round',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Action buttons
          if (!connected)
            FilledButton(
              onPressed: _resetSolo,
              style: FilledButton.styleFrom(
                backgroundColor: f.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radii.sm),
                ),
              ),
              child: const GoopText(
                'ROLL AGAIN',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else ...[
            // Rematch — send a new challenge to the same partner.
            FilledButton.icon(
              onPressed: () {
                _resetSolo();
                _sendChallenge();
              },
              icon: const Icon(Icons.casino_outlined, size: 18),
              label: const GoopText(
                'REMATCH',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: f.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radii.sm),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radii.sm),
                ),
              ),
              child: const GoopText(
                'CLOSE',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      );
    }

    // Solo play initial state
    return Column(
      key: const ValueKey('solo_initial'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GoopText(
          'Throw Gunfortuna\'s sacred dice to determine your fortune in Gungeon! Spin 3x dice for a rating from 3 to 18.',
          style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.45),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ScaleButton(
          onTap: _startRolling,
          child: IgnorePointer(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.casino_outlined, size: 20),
                label: const GoopText(
                  'ROLL THE DICE!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: f.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radii.sm),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

DiceStyle _getDiceStyle(CustomDiceType type, ThemeFlair flair) {
  switch (type) {
    case CustomDiceType.classicWhite:
      return const DiceStyle(
        bg: Color(0xFFFAFAFA),
        border: Color(0xFF90A4AE),
        text: Color(0xFF263238),
        glow: Colors.white24,
      );
    case CustomDiceType.goldGlimmer:
      return const DiceStyle(
        bg: Color(0xFF2C2210),
        border: Color(0xFFFFD54F),
        text: Color(0xFFFFD54F),
        glow: Color(0x33FFD54F),
      );
    case CustomDiceType.frostShard:
      return const DiceStyle(
        bg: Color(0xFF101C2C),
        border: Color(0xFF00E5FF),
        text: Color(0xFF00E5FF),
        glow: Color(0x3300E5FF),
      );
    case CustomDiceType.moltenAmber:
      return const DiceStyle(
        bg: Color(0xFF2C1010),
        border: Color(0xFFFF3D00),
        text: Color(0xFFFF3D00),
        glow: Color(0x33FF3D00),
      );
    case CustomDiceType.voidPurple:
      return const DiceStyle(
        bg: Color(0xFF1F102C),
        border: Color(0xFFD500F9),
        text: Color(0xFFD500F9),
        glow: Color(0x33D500F9),
      );
    case CustomDiceType.toxicOoze:
      return const DiceStyle(
        bg: Color(0xFF102C13),
        border: Color(0xFF00E676),
        text: Color(0xFF00E676),
        glow: Color(0x3300E676),
      );
    case CustomDiceType.themeDefault:
      return DiceStyle(
        bg: const Color(0xFF161413),
        border: flair.primary,
        text: flair.primary,
        glow: flair.primary.withValues(alpha: 0.3),
      );
  }
}

// _InteractiveDogStrip and DogBehavior/Facing enums removed — Huntress HUD
// simplified to compact single-card layout without animated dog strip.
