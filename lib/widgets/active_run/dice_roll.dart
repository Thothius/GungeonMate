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
import '../skeuo/skeuo_tokens.dart';
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
  const DiceRollDialog({super.key, required this.isChallenged});

  @override
  State<DiceRollDialog> createState() => DiceRollDialogState();
}

class DiceRollDialogState extends State<DiceRollDialog>
    with TickerProviderStateMixin, _DiceRollLogic {
  // Actual secret results rolled at the start of rolling

  // Particles inside the dialog

  // To restore callbacks on dispose

  @override
  @override
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
              Padding(
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
                        Row(
                          children: [
                            Icon(
                              Icons.casino_rounded,
                              color: f.primary,
                              size: 26,
                            ),
                            SizedBox(width: 10),
                            GoopText(
                              'GUNFORTUNA\'S DUEL',
                              style: TextStyle(
                                fontSize: FontSizes.titleMedium,
                                fontWeight: FontWeight.w900,
                                color: f.primary,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: Icon(
                            Icons.close,
                            color: Skeuo.collapse(Colors.white38),
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
                    SizedBox(height: 14),

                    // Flavour text (Only show in idle state!)
                    if (_status == DiceStatus.idle) ...[
                      Container(
                        padding: const EdgeInsets.all(Insets.md),
                        decoration: BoxDecoration(
                          color: Skeuo.collapse(
                            Colors.white,
                          ).withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Skeuo.collapse(
                              Colors.white,
                            ).withValues(alpha: 0.06),
                          ),
                        ),
                        child: GoopText(
                          '“Gunfortuna, the celestial bullet-goddess of chance, spins the cylinders of fate. When co-op partners clash over loot, let her dice decide who walks away with the prize.”',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Skeuo.collapse(Colors.white54),
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

  Widget _buildCurrentBody(bool connected, DiceStyle diceStyle, ThemeFlair f) {
    if (_status == DiceStatus.idle && connected) {
      return Column(
        key: const ValueKey('idle_connected'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GoopText(
            'Challenge your sidekick or main partner to a high-stakes dice duel! 3x dice will decide who gets Gunfortuna\'s favor!',
            style: TextStyle(
              fontSize: 12.5,
              color: Skeuo.collapse(Colors.white70),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
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
                    foregroundColor: Skeuo.collapse(Colors.black),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radii.sm),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: ScaleButton(
              onTap: _startRolling,
              child: IgnorePointer(
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: Skeuo.collapse(Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: Insets.sm),
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

    if (_status == DiceStatus.challenging) {
      return Column(
        key: const ValueKey('challenging'),
        children: [
          SizedBox(height: 10),
          CircularProgressIndicator(color: Skeuo.inkIf(Colors.amberAccent)),
          SizedBox(height: 16),
          GoopText(
            'Waiting for partner to accept...',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Skeuo.collapse(Colors.white70),
            ),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: _cancelChallenge,
            style: TextButton.styleFrom(
              foregroundColor: Skeuo.collapse(Colors.white38),
            ),
            child: const GoopText(
              'CANCEL CHALLENGE',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
        ],
      );
    }

    if (_status == DiceStatus.rolling) {
      return Column(
        key: const ValueKey('rolling_active'),
        children: [
          GoopText(
            'THE CYLINDERS ARE SPINNING!',
            style: TextStyle(
              fontSize: FontSizes.labelMedium,
              fontWeight: FontWeight.w900,
              color: Skeuo.collapse(Colors.white54),
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 4),
          GoopText(
            'Tap each die individually to stop its spin!',
            style: TextStyle(
              fontSize: FontSizes.labelSmall,
              color: Skeuo.inkIf(Colors.amberAccent),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              key: _diceRowKey,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                final isStopped = _diceStopped[index];
                return RepaintBoundary(
                  child: DiceWidget(
                    dieKey: _dieKeys[index],
                    value: _myDice[index],
                    isRolling: !isStopped,
                    infiniteController: _infiniteController,
                    index: index,
                    style: diceStyle,
                    onTap: () => _stopDie(index, diceStyle.border),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 20),
          GoopText(
            'Current Sum: $_myScore',
            style: TextStyle(
              fontSize: FontSizes.titleSmall,
              fontWeight: FontWeight.w900,
              color: Skeuo.collapse(Colors.white),
            ),
          ),
        ],
      );
    }

    if (_status == DiceStatus.rollingScreen && _hasRolled) {
      return Column(
        key: const ValueKey('rolled_waiting'),
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                return DiceWidget(
                  dieKey: _dieKeys[index],
                  value: _myDice[index],
                  isRolling: false,
                  infiniteController: _infiniteController,
                  index: index,
                  style: diceStyle,
                  onTap: null,
                );
              }),
            ),
          ),
          SizedBox(height: 24),
          GoopText(
            'ROLLED!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Skeuo.collapse(Color(0xFF66E07A)),
            ),
          ),
          SizedBox(height: 6),
          GoopText(
            'Your Score: $_myScore',
            style: TextStyle(
              fontSize: FontSizes.bodyMedium,
              fontWeight: FontWeight.w900,
              color: Skeuo.collapse(Colors.white),
            ),
          ),
          SizedBox(height: 8),
          if (_peerScore == null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Skeuo.inkIf(Colors.cyanAccent),
                  ),
                ),
                SizedBox(width: 10),
                GoopText(
                  'Waiting for partner to finish rolling...',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Skeuo.inkIf(Colors.cyanAccent),
                  ),
                ),
              ],
            ),
        ],
      );
    }

    if (_status == DiceStatus.finished) {
      final isMyVictory = _peerScore != null && _myScore > _peerScore!;
      final isDraw = _peerScore != null && _myScore == _peerScore!;
      final isSolo = _peerScore == null;

      final Color bannerColor =
          isSolo
              ? Skeuo.collapse(Color(0xFFFFD54F)) // Majestic Gold for Solo fate
              : (isDraw
                  ? Skeuo.collapse(Colors.white54)
                  : (isMyVictory
                      ? Skeuo.inkIf(Colors.greenAccent)
                      : Skeuo.inkIf(Colors.redAccent)));

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
                    bannerColor == Skeuo.collapse(Colors.white54)
                        ? Skeuo.collapse(Colors.white)
                        : bannerColor,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 20),

          // Side-by-side comparison with character details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Player 1 (You)
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.person,
                      color: Skeuo.inkIf(Colors.cyanAccent),
                      size: 24,
                    ),
                    SizedBox(height: 4),
                    GoopText(
                      _mp.myNickname.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: FontSizes.labelSmall,
                        fontWeight: FontWeight.bold,
                        color: Skeuo.collapse(Colors.white70),
                      ),
                    ),
                    SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$_myScore',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Skeuo.collapse(Colors.white),
                          height: 1.0,
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    GoopText(
                      '(${_myDice.join("-")})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Skeuo.collapse(Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),
              if (_peerScore != null) ...[
                GoopText(
                  'VS',
                  style: TextStyle(
                    fontSize: FontSizes.titleSmall,
                    fontWeight: FontWeight.w900,
                    color: Skeuo.collapse(Colors.white24),
                  ),
                ),
                // Player 2 (Peer)
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: Skeuo.inkIf(Colors.pinkAccent),
                        size: 24,
                      ),
                      SizedBox(height: 4),
                      GoopText(
                        (_mp.peerNickname ?? 'Partner').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: FontSizes.labelSmall,
                          fontWeight: FontWeight.bold,
                          color: Skeuo.collapse(Colors.white70),
                        ),
                      ),
                      SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$_peerScore',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Skeuo.collapse(Colors.white),
                            height: 1.0,
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      GoopText(
                        '(${_peerDice?.join("-") ?? ""})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Skeuo.collapse(Colors.white38),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 24),

          // Action buttons
          if (!connected)
            FilledButton(
              onPressed: _resetSolo,
              style: FilledButton.styleFrom(
                backgroundColor: f.primary,
                foregroundColor: Skeuo.collapse(Colors.black),
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
                foregroundColor: Skeuo.collapse(Colors.black),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radii.sm),
                ),
              ),
            ),
            SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                side: BorderSide(color: Skeuo.collapse(Colors.white24)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radii.sm),
                ),
              ),
              child: GoopText(
                'CLOSE',
                style: TextStyle(
                  color: Skeuo.collapse(Colors.white70),
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
        GoopText(
          'Throw Gunfortuna\'s sacred dice to determine your fortune in Gungeon! Spin 3x dice for a rating from 3 to 18.',
          style: TextStyle(
            fontSize: 12.5,
            color: Skeuo.collapse(Colors.white70),
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
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
                  foregroundColor: Skeuo.collapse(Colors.black),
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
      return DiceStyle(
        bg: Skeuo.collapse(Color(0xFFFAFAFA)),
        border: Skeuo.collapse(Color(0xFF90A4AE)),
        text: Skeuo.collapse(Color(0xFF263238)),
        glow: Skeuo.collapse(Colors.white24),
      );
    case CustomDiceType.goldGlimmer:
      return DiceStyle(
        bg: Skeuo.collapse(Color(0xFF2C2210)),
        border: Skeuo.collapse(Color(0xFFFFD54F)),
        text: Skeuo.collapse(Color(0xFFFFD54F)),
        glow: Skeuo.collapse(Color(0x33FFD54F)),
      );
    case CustomDiceType.frostShard:
      return DiceStyle(
        bg: Skeuo.collapse(Color(0xFF101C2C)),
        border: Skeuo.collapse(Color(0xFF00E5FF)),
        text: Skeuo.collapse(Color(0xFF00E5FF)),
        glow: Skeuo.collapse(Color(0x3300E5FF)),
      );
    case CustomDiceType.moltenAmber:
      return DiceStyle(
        bg: Skeuo.collapse(Color(0xFF2C1010)),
        border: Skeuo.collapse(Color(0xFFFF3D00)),
        text: Skeuo.collapse(Color(0xFFFF3D00)),
        glow: Skeuo.collapse(Color(0x33FF3D00)),
      );
    case CustomDiceType.voidPurple:
      return DiceStyle(
        bg: Skeuo.collapse(Color(0xFF1F102C)),
        border: Skeuo.collapse(Color(0xFFD500F9)),
        text: Skeuo.collapse(Color(0xFFD500F9)),
        glow: Skeuo.collapse(Color(0x33D500F9)),
      );
    case CustomDiceType.toxicOoze:
      return DiceStyle(
        bg: Skeuo.collapse(Color(0xFF102C13)),
        border: Skeuo.collapse(Color(0xFF00E676)),
        text: Skeuo.collapse(Color(0xFF00E676)),
        glow: Skeuo.collapse(Color(0x3300E676)),
      );
    case CustomDiceType.themeDefault:
      return DiceStyle(
        bg: Skeuo.collapse(Color(0xFF161413)),
        border: flair.primary,
        text: flair.primary,
        glow: flair.primary.withValues(alpha: 0.3),
      );
  }
}

// _InteractiveDogStrip and DogBehavior/Facing enums removed — Huntress HUD
// simplified to compact single-card layout without animated dog strip.
