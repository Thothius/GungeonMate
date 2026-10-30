part of '../dice_roll.dart';

// Dice-roll game logic extracted from DiceRollDialogState (Phase 5f) —
// same library; on-clause gives setState/context/widget/mounted/vsync.

mixin _DiceRollLogic on TickerProviderStateMixin<DiceRollDialog> {
  late final AnimationController _infiniteController;

  late final MpSession _mp;

  DiceStatus _status = DiceStatus.idle;

  final List<int> _actualDice = [1, 1, 1];

  final List<int> _myDice = [1, 1, 1];

  final List<bool> _diceStopped = [false, false, false];

  final GlobalKey _diceRowKey = GlobalKey();

  final List<GlobalKey> _dieKeys = List.generate(3, (_) => GlobalKey());

  final GlobalKey _particleKey = GlobalKey();

  int _myScore = 0;

  bool _hasRolled = false;

  List<int>? _peerDice;
  int? _peerScore;

  String _announcement = '';

  final List<DialogParticle> _particles = [];

  late final AnimationController _particleController;

  void Function(String challengerName)? _prevChallenge;

  void Function()? _prevAccept;

  void Function()? _prevDecline;

  void Function()? _prevCancel;

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

    _mp = Provider.of<MpSession>(context, listen: false);
    _prevChallenge = _mp.onDiceChallenge;
    _prevAccept = _mp.onDiceAccept;
    _prevDecline = _mp.onDiceDecline;
    _prevCancel = _mp.onDiceCancel;
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

    // Handle cancel from the challenger — the challenged player's
    // dialog must close (or return to idle) so they're not stuck.
    _mp.onDiceCancel = () {
      if (!mounted) return;
      setState(() {
        if (_status == DiceStatus.rollingScreen && !_hasRolled) {
          // Challenged but hadn't started rolling — go back to idle.
          _status = DiceStatus.idle;
          _announcement = 'Challenge cancelled.';
        } else if (_status == DiceStatus.challenging) {
          // Shouldn't happen (challenger cancels their own challenge),
          // but handle gracefully — return to idle.
          _status = DiceStatus.idle;
          _announcement = 'Challenge cancelled.';
        } else if (_status == DiceStatus.rollingScreen && _hasRolled) {
          // Already rolled and waiting for peer result — treat as
          // finished with our score only.
          _status = DiceStatus.finished;
          _announcement = 'Partner cancelled the duel.';
        }
        // If already finished or idle, ignore.
      });
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

    // Listen for disconnects so we don't sit waiting forever.
    _mp.addListener(_onSessionChanged);
  }

  void _onSessionChanged() {
    if (!mounted) return;
    // If the peer disconnects during a challenge or while waiting for
    // their roll result, bail out to a finished state so the user
    // isn't stuck on a "waiting" screen.
    if (!_mp.isActive || !_mp.isConnected) {
      setState(() {
        if (_status == DiceStatus.challenging) {
          _status = DiceStatus.idle;
          _announcement = 'Partner disconnected.';
        } else if (_status == DiceStatus.rollingScreen &&
            _hasRolled &&
            _peerScore == null) {
          _status = DiceStatus.finished;
          _announcement =
              'Partner disconnected. GUNFORTUNA DECLARES YOU VICTORIOUS BY DEFAULT!';
        }
      });
    }
  }

  @override
  void dispose() {
    _mp.removeListener(_onSessionChanged);
    _infiniteController.dispose();
    _particleController.removeListener(_updateParticles);
    _particleController.dispose();
    _mp.onDiceChallenge = _prevChallenge;
    _mp.onDiceAccept = _prevAccept;
    _mp.onDiceDecline = _prevDecline;
    _mp.onDiceCancel = _prevCancel;
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
      _particles.add(
        DialogParticle(
          x: x,
          y: y,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed - 2.0, // slight upward bias
          color: color,
        ),
      );
    }
  }

  void _sendChallenge() {
    setState(() {
      _status = DiceStatus.challenging;
    });
    _mp.sendDiceChallenge(_mp.myNickname);
  }

  void _cancelChallenge() {
    _mp.sendDiceCancel();
    if (mounted) Navigator.of(context).pop();
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

      // Spawn satisfying sparkles at the exact die position.
      final particleBox =
          _particleKey.currentContext?.findRenderObject() as RenderBox?;
      final dieBox =
          _dieKeys[index].currentContext?.findRenderObject() as RenderBox?;
      if (particleBox != null && dieBox != null) {
        final globalCenter = dieBox.localToGlobal(
          dieBox.size.center(Offset.zero),
        );
        final local = particleBox.globalToLocal(globalCenter);
        _spawnSparkles(local.dx, local.dy, particleColor);
      }
      Haptics.heavy();

      // Check if all dice have stopped
      if (_diceStopped.every((stopped) => stopped)) {
        // Wait 1.2s then flip to final results
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          setState(() {
            if (_mp.isActive && _mp.isConnected) {
              _status =
                  DiceStatus.rollingScreen; // stay on roll screen but rolled
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
          _announcement =
              'GUNFORTUNA DECLARES ${_mp.peerNickname?.toUpperCase() ?? "PEER"} VICTORIOUS!';
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
}
