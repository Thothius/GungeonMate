import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../scale_button.dart';
import '../../services/haptics.dart';
import '../../services/app_theme.dart';
import '../../services/multiplayer_session.dart';
import '../../services/goop_talk_engine.dart';

// =============================================================================
// Gunfortuna Dice Roll dialog / challenge
// =============================================================================

void showDiceRollDialog(BuildContext context, {bool isChallenged = false}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
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

class DiceRollDialogState extends State<DiceRollDialog> with TickerProviderStateMixin {
  late final AnimationController _infiniteController;
  late final MultiplayerSession _mp;
  DiceStatus _status = DiceStatus.idle;

  // Actual secret results rolled at the start of rolling
  final List<int> _actualDice = [1, 1, 1];
  final List<int> _myDice = [1, 1, 1];
  final List<bool> _diceStopped = [false, false, false];
  final GlobalKey _diceRowKey = GlobalKey();
  int _myScore = 0;
  bool _hasRolled = false;

  List<int>? _peerDice;
  int? _peerScore;

  String _announcement = '';

  // Particles inside the dialog
  final List<DialogParticle> _particles = [];
  late final AnimationController _particleController;

  // To restore callbacks on dispose
  void Function(String challengerName)? _prevChallenge;
  void Function()? _prevAccept;
  void Function()? _prevDecline;
  void Function(int peerScore, List<int> peerDice)? _prevResult;

  @override
  void initState() {
    super.initState();
    _infiniteController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _particleController.addListener(_updateParticles);

    _mp = Provider.of<MultiplayerSession>(context, listen: false);
    _prevChallenge = _mp.onDiceChallenge;
    _prevAccept = _mp.onDiceAccept;
    _prevDecline = _mp.onDiceDecline;
    _prevResult = _mp.onDiceResult;

    if (widget.isChallenged) {
      _status = DiceStatus.rollingScreen;
    }

    _mp.onDiceAccept = () {
      if (mounted) {
        setState(() {
          _status = DiceStatus.rollingScreen;
        });
      }
    };

    _mp.onDiceDecline = () {
      if (mounted) {
        setState(() {
          _status = DiceStatus.idle;
          _announcement = 'Challenge declined.';
        });
      }
    };

    _mp.onDiceResult = (peerScore, peerDice) {
      if (mounted) {
        setState(() {
          _peerScore = peerScore;
          _peerDice = peerDice;
          _checkWinner();
        });
      }
    };
  }

  @override
  void dispose() {
    _infiniteController.dispose();
    _particleController.removeListener(_updateParticles);
    _particleController.dispose();
    _mp.onDiceChallenge = _prevChallenge;
    _mp.onDiceAccept = _prevAccept;
    _mp.onDiceDecline = _prevDecline;
    _mp.onDiceResult = _prevResult;
    super.dispose();
  }

  void _updateParticles() {
    if (!mounted) return;
    setState(() {
      for (int i = _particles.length - 1; i >= 0; i--) {
        final p = _particles[i];
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.15; // Gravity
        p.life -= 0.04;
        if (p.life <= 0) {
          _particles.removeAt(i);
        }
      }
    });
  }

  void _spawnSparkles(double x, double y, Color color) {
    final rand = math.Random();
    for (int i = 0; i < 12; i++) {
      final angle = rand.nextDouble() * 2 * math.pi;
      final speed = 1.0 + rand.nextDouble() * 3.5;
      _particles.add(DialogParticle(
        x: x,
        y: y,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed - 2.0, // slight upward bias
        color: color,
      ));
    }
  }

  void _sendChallenge() {
    setState(() {
      _status = DiceStatus.challenging;
    });
    _mp.sendDiceChallenge(_mp.myNickname);
  }

  void _startRolling() {
    if (_hasRolled) return;
    final rand = math.Random();
    _actualDice[0] = rand.nextInt(6) + 1;
    _actualDice[1] = rand.nextInt(6) + 1;
    _actualDice[2] = rand.nextInt(6) + 1;

    setState(() {
      _status = DiceStatus.rolling;
      _hasRolled = true;
      _diceStopped[0] = false;
      _diceStopped[1] = false;
      _diceStopped[2] = false;
      _myDice[0] = 1;
      _myDice[1] = 1;
      _myDice[2] = 1;
      _myScore = 0;
    });
  }

  void _stopDie(int index, Color particleColor) {
    if (_status != DiceStatus.rolling || _diceStopped[index]) return;

    setState(() {
      _diceStopped[index] = true;
      _myDice[index] = _actualDice[index];
      
      // Update running sum in real-time
      int sum = 0;
      for (int i = 0; i < 3; i++) {
        if (_diceStopped[i]) {
          sum += _myDice[i];
        }
      }
      _myScore = sum;

      // Spawn satisfying sparkles at actual die position
      // ponytail: y is still hardcoded — would need a per-die GlobalKey for exact y.
      // x is now accurate via _diceRowKey RenderBox. Upgrade path: GlobalKey per die.
      final renderBox = _diceRowKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final rowWidth = renderBox.size.width;
        final xPos = rowWidth * (index + 0.5) / 3;
        _spawnSparkles(xPos, 160.0, particleColor);
      }
      Haptics.heavy();

      // Check if all dice have stopped
      if (_diceStopped.every((stopped) => stopped)) {
        // Wait 1.2s then flip to final results
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          setState(() {
            if (_mp.isActive && _mp.isConnected) {
              _status = DiceStatus.rollingScreen; // stay on roll screen but rolled
              _mp.sendDiceResult(_myScore, List<int>.from(_myDice));
            } else {
              _status = DiceStatus.finished;
              _announcement = 'GUNFORTUNA HAS DECLARED YOUR FATE!';
            }
            _checkWinner();
          });
        });
      }
    });
  }

  void _checkWinner() {
    if (_myScore > 0 && _peerScore != null) {
      setState(() {
        _status = DiceStatus.finished;
        if (_myScore > _peerScore!) {
          _announcement = 'GUNFORTUNA DECLARES YOU VICTORIOUS!';
        } else if (_myScore < _peerScore!) {
          _announcement = 'GUNFORTUNA DECLARES ${_mp.peerNickname?.toUpperCase() ?? "PEER"} VICTORIOUS!';
        } else {
          _announcement = "IT'S A DRAW! THE FATES ARE IN PERFECT BALANCE!";
        }
      });
    }
  }

  void _resetSolo() {
    setState(() {
      _myDice[0] = 1;
      _myDice[1] = 1;
      _myDice[2] = 1;
      _diceStopped[0] = false;
      _diceStopped[1] = false;
      _diceStopped[2] = false;
      _myScore = 0;
      _hasRolled = false;
      _status = DiceStatus.idle;
      _announcement = '';
      _particles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final connected = _mp.isActive && _mp.isConnected;
    final f = AppTheme.flair;
    final prefs = VisualPrefs.notifier.value;
    final myDiceStyle = _getDiceStyle(prefs.customDiceType, f);

    return Dialog(
      backgroundColor: const Color(0xFF151211),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: f.primary, width: 2.0),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                          Icon(Icons.casino_rounded, color: f.primary, size: 26),
                          const SizedBox(width: 10),
                          GoopText(
                            'GUNFORTUNA\'S DUEL',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: f.primary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Flavour text (Only show in idle state!)
                  if (_status == DiceStatus.idle) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: const GoopText(
                        'ΓÇ£Gunfortuna, the celestial bullet-goddess of chance, spins the cylinders of fate. When co-op partners clash over loot, let her dice decide who walks away with the prize.ΓÇ¥',
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
                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
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
                  child: CustomPaint(
                    painter: DialogParticlePainter(particles: _particles),
                  ),
                ),
              ),
          ],
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
          const GoopText(
            'Challenge your sidekick or main partner to a high-stakes dice duel! 3x dice will decide who gets Gunfortuna\'s favor!',
            style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
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
                  label: const GoopText('CHALLENGE PARTNER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: f.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ScaleButton(
            onTap: _startRolling,
            child: IgnorePointer(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const GoopText('ROLL SOLO INSTEAD', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_status == DiceStatus.challenging) {
      return const Column(
        key: ValueKey('challenging'),
        children: [
          SizedBox(height: 10),
          CircularProgressIndicator(color: Colors.amberAccent),
          SizedBox(height: 16),
          GoopText('Waiting for partner to accept...', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white70)),
          SizedBox(height: 10),
        ],
      );
    }

    if (_status == DiceStatus.rolling) {
      return Column(
        key: const ValueKey('rolling_active'),
        children: [
          const GoopText(
            'THE CYLINDERS ARE SPINNING!',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white54, letterSpacing: 1.0),
          ),
          const SizedBox(height: 4),
          const GoopText(
            'Tap each die individually to stop its spin!',
            style: TextStyle(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              key: _diceRowKey,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                final isStopped = _diceStopped[index];
                return DiceWidget(
                  value: _myDice[index],
                  isRolling: !isStopped,
                  infiniteController: _infiniteController,
                  index: index,
                  style: diceStyle,
                  onTap: () => _stopDie(index, diceStyle.border),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          GoopText(
            'Current Sum: $_myScore',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
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
          const SizedBox(height: 24),
          const GoopText('ROLLED!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF66E07A))),
          const SizedBox(height: 6),
          GoopText('Your Score: $_myScore', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          if (_peerScore == null)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent)),
                SizedBox(width: 10),
                GoopText('Waiting for partner to finish rolling...', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.cyanAccent)),
              ],
            ),
        ],
      );
    }

    if (_status == DiceStatus.finished) {
      final isMyVictory = _peerScore != null && _myScore > _peerScore!;
      final isDraw = _peerScore != null && _myScore == _peerScore!;
      final isSolo = _peerScore == null;

      final Color bannerColor = isSolo
          ? const Color(0xFFFFD54F) // Majestic Gold for Solo fate
          : (isDraw
              ? Colors.white54
              : (isMyVictory ? Colors.greenAccent : Colors.redAccent));

      return Column(
        key: const ValueKey('finished_results'),
        children: [
          // Flavour Winner announcement
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bannerColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: bannerColor,
                width: 1.5,
              ),
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
                color: bannerColor == Colors.white54 ? Colors.white : bannerColor,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),

          // Side-by-side comparison with character details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Player 1 (You)
              Expanded(
                child: Column(
                  children: [
                    const Icon(Icons.person, color: Colors.cyanAccent, size: 24),
                    const SizedBox(height: 4),
                    GoopText(
                      _mp.myNickname.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_myScore',
                      style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                    ),
                    const SizedBox(height: 4),
                    GoopText('(${_myDice.join("-")})', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                  ],
                ),
              ),
              if (_peerScore != null) ...[
                const GoopText(
                  'VS',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white24),
                ),
                // Player 2 (Peer)
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.person_outline, color: Colors.pinkAccent, size: 24),
                      const SizedBox(height: 4),
                      GoopText(
                        (_mp.peerNickname ?? 'Partner').toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_peerScore',
                        style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white, height: 1.0),
                      ),
                      const SizedBox(height: 4),
                      GoopText('(${_peerDice?.join("-") ?? ""})', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          // Action buttons
          if (!connected)
            ElevatedButton(
              onPressed: _resetSolo,
              style: ElevatedButton.styleFrom(
                backgroundColor: f.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const GoopText('ROLL AGAIN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            )
          else
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const GoopText('CLOSE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
            ),
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
                label: const GoopText('ROLL THE DICE!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: f.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DiceWidget extends StatefulWidget {
  final int value;
  final bool isRolling;
  final AnimationController infiniteController;
  final int index;
  final DiceStyle style;
  final VoidCallback? onTap;

  const DiceWidget({super.key, 
    required this.value,
    required this.isRolling,
    required this.infiniteController,
    required this.index,
    required this.style,
    required this.onTap,
  });

  @override
  State<DiceWidget> createState() => DiceWidgetState();
}

class DiceWidgetState extends State<DiceWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _impactController;

  @override
  void initState() {
    super.initState();
    _impactController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _impactController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRolling && !widget.isRolling) {
      // Play sudden impact expand/pop animation on stop!
      _impactController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.infiniteController, _impactController]),
          builder: (context, child) {
            final t = widget.infiniteController.value;
            final impact = _impactController.value;

            // Compute 3D rotation tumbling
            final rotX = widget.isRolling ? (t * (4 + widget.index * 2) * math.pi) : 0.0;
            final rotY = widget.isRolling ? (t * (3 + widget.index * 3) * math.pi) : 0.0;
            final rotZ = widget.isRolling ? (t * (2 + widget.index * 4) * math.pi) : 0.0;

            // Vertical floating/bobbing during roll to look organic
            final double bobY = widget.isRolling ? (math.sin(t * 2 * math.pi + widget.index * 1.5) * 8.0) : 0.0;

            // Rapid cycling face value while rolling
            final faceVal = widget.isRolling ? ((widget.index + (t * 40).round()) % 6 + 1) : widget.value;

            // Impact pop scale (up to 1.35x and bounces back quickly)
            final double scale = widget.isRolling 
                ? 1.0 
                : 1.0 + math.sin(impact * math.pi) * 0.35;

            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0018) // 3D projection
                ..translate(0.0, bobY)
                ..scale(scale)
                ..rotateX(rotX)
                ..rotateY(rotY)
                ..rotateZ(rotZ),
              alignment: Alignment.center,
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.style.bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.style.border,
                    width: widget.isRolling ? 2.0 : 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.style.glow,
                      blurRadius: widget.isRolling ? 6 : 12,
                      spreadRadius: widget.isRolling ? 1 : 3,
                    ),
                  ],
                ),
                child: Text(
                  '$faceVal',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: widget.style.text,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DialogParticle {
  double x, y;
  double vx, vy;
  Color color;
  double life; // 1.0 down to 0.0
  DialogParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.color,
    // ignore: unused_element_parameter
    this.life = 1.0,
  });
}

class DialogParticlePainter extends CustomPainter {
  final List<DialogParticle> particles;
  DialogParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.life);
      canvas.drawCircle(Offset(p.x, p.y), 3.0 * p.life, paint);
    }
  }

  @override
  bool shouldRepaint(DialogParticlePainter old) => true;
}

class DiceStyle {
  final Color bg;
  final Color border;
  final Color text;
  final Color glow;
  const DiceStyle({
    required this.bg,
    required this.border,
    required this.text,
    required this.glow,
  });
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
