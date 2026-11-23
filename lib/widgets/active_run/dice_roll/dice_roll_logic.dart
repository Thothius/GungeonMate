part of '../dice_roll.dart';

// Dice-roll game logic extracted from DiceRollDialogState (Phase 5f) —
// same library; on-clause gives setState/context/widget/mounted/vsync.
//
// Single-die duel (reworked): one d6 per round. Ties auto-reroll —
// both sides detect the tie from the same two round-N results and
// independently schedule round N+1, so no extra wire message is
// needed. `MpDiceResult.round` keeps stale-round results from
// comparing against the live round.

mixin _DiceRollLogic on TickerProviderStateMixin<DiceRollDialog> {
  late final AnimationController _infiniteController;

  bool _still = false;

  late final MpSession _mp;

  DiceStatus _status = DiceStatus.idle;

  /// Current duel round — 1 for the opening roll, +1 per tie reroll.
  int _round = 1;

  /// My die face for the current round (0 = not rolled yet).
  int _myValue = 0;

  /// Peer's die face for [_round] — stored with its round so a stale
  /// result can't satisfy the comparison.
  int? _peerValue;
  int _peerRound = 0;

  /// Die is mid-spin (auto-stops on a timer — no tap-to-stop).
  bool _rolling = false;
  Timer? _rollTimer;

  /// True when a connected player chose "or roll solo" — the result
  /// must NOT be sent to the peer as a duel roll.
  bool _soloRoll = false;

  /// Scheduled auto-reroll after a tie — cancelled if the user rolls
  /// manually inside the window or the dialog closes.
  Timer? _rerollTimer;

  /// Test-only deterministic rolls (see [DiceRollDialog.debugRollValues]).
  late final List<int> _debugRolls = List.of(
    widget.debugRollValues ?? const [],
  );

  final GlobalKey _particleKey = GlobalKey();

  String _announcement = '';

  final List<DialogParticle> _particles = [];

  late final AnimationController _particleController;

  void Function(String challengerName)? _prevChallenge;

  void Function()? _prevAccept;

  void Function()? _prevDecline;

  void Function()? _prevCancel;

  void Function(int peerScore, List<int> peerDice, int round)? _prevResult;

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
        if (_status == DiceStatus.rollingScreen && _myValue == 0) {
          // Duel active but this round not rolled — back to idle.
          _status = DiceStatus.idle;
          _announcement = 'Challenge cancelled.';
        } else if (_status == DiceStatus.challenging ||
            _status == DiceStatus.rolling) {
          _status = DiceStatus.idle;
          _announcement = 'Challenge cancelled.';
        } else if (_status == DiceStatus.rollingScreen &&
            _myValue != 0 &&
            _peerValue == null) {
          // Already rolled and waiting for peer result — treat as
          // finished with our roll only.
          _status = DiceStatus.finished;
          _announcement = 'Partner cancelled the duel.';
        }
        // If already finished or idle, ignore.
      });
    };

    _mp.onDiceResult = (peerScore, peerDice, round) {
      if (!mounted || round != _round) return;
      setState(() {
        _peerValue = peerScore;
        _peerRound = round;
      });
      _evaluateRound();
    };

    // Listen for disconnects so we don't sit waiting forever.
    _mp.addListener(_onSessionChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = ReduceMotion.of(context);
    if (still == _still) return;
    _still = still;
    for (final c in [_infiniteController, _particleController]) {
      if (still) {
        c.stop();
      } else if (!c.isAnimating) {
        c.repeat();
      }
    }
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
            _myValue != 0 &&
            _peerValue == null) {
          _status = DiceStatus.finished;
          _announcement =
              'Partner disconnected. GUNFORTUNA DECLARES YOU VICTORIOUS BY DEFAULT!';
        }
      });
    }
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    _rerollTimer?.cancel();
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
    // Reduced-motion: no particle bursts — the stopped
    // _particleController would leave them frozen mid-air.
    if (ReduceMotion.of(context)) return;
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
    _soloRoll = false;
    setState(() {
      _status = DiceStatus.challenging;
    });
    _mp.sendDiceChallenge(_mp.myNickname);
  }

  void _cancelChallenge() {
    _mp.sendDiceCancel();
    if (mounted) Navigator.of(context).pop();
  }

  /// "Or roll solo" from the connected idle state — marks the roll
  /// so the result stays local instead of going to the peer.
  void _rollSolo() {
    _soloRoll = true;
    _startRolling();
  }

  /// Roll the single die. Auto-stops after the spin — no tap needed.
  /// Allowed from idle (solo) and rollingScreen (duel, once per round).
  void _startRolling() {
    if (_rolling || _myValue != 0) return;
    if (_status != DiceStatus.idle && _status != DiceStatus.rollingScreen) {
      return;
    }
    setState(() {
      _status = DiceStatus.rolling;
      _rolling = true;
      _myValue = 0;
    });
    _rollTimer?.cancel();
    _rollTimer = Timer(const Duration(milliseconds: 1100), _landDie);
  }

  void _landDie() {
    if (!mounted) return;
    final v = _debugRolls.isNotEmpty
        ? _debugRolls.removeAt(0)
        : math.Random().nextInt(6) + 1;
    final duel = _mp.isActive && _mp.isConnected && !_soloRoll;
    setState(() {
      _myValue = v;
      _rolling = false;
      if (duel) {
        _status = DiceStatus.rollingScreen;
        _mp.sendDiceResult(v, [v], round: _round);
      } else {
        _status = DiceStatus.finished;
        _announcement = 'GUNFORTUNA HAS DECIDED YOUR FATE!';
      }
    });
    // Sparkles at the dialog's center on landing.
    final particleBox =
        _particleKey.currentContext?.findRenderObject() as RenderBox?;
    if (particleBox != null) {
      _spawnSparkles(
        particleBox.size.width / 2,
        particleBox.size.height / 2,
        AppTheme.flair.primary,
      );
    }
    Haptics.heavy();
    _evaluateRound();
  }

  /// Compare both round-N results. Tie → schedule the auto-reroll;
  /// different → declare the winner.
  void _evaluateRound() {
    if (_status == DiceStatus.finished) return;
    if (!(_mp.isActive && _mp.isConnected)) return;
    if (_myValue == 0 || _peerValue == null || _peerRound != _round) return;

    if (_myValue == _peerValue) {
      // TIE — both sides see the same two results and independently
      // schedule round N+1, so the duel always produces a winner.
      setState(() {
        _round++;
        _myValue = 0;
        _peerValue = null;
        _peerRound = 0;
        _announcement = 'TIE! ROUND $_round — Gunfortuna rerolls…';
      });
      _rerollTimer?.cancel();
      _rerollTimer = Timer(
        const Duration(milliseconds: 1000),
        _startRolling,
      );
      return;
    }

    setState(() {
      _status = DiceStatus.finished;
      _announcement =
          _myValue > _peerValue!
              ? 'GUNFORTUNA DECLARES YOU VICTORIOUS!'
              : 'GUNFORTUNA DECLARES ${_mp.peerNickname?.toUpperCase() ?? "PEER"} VICTORIOUS!';
    });
  }

  void _resetSolo() {
    _rollTimer?.cancel();
    _rerollTimer?.cancel();
    _soloRoll = false;
    setState(() {
      _round = 1;
      _myValue = 0;
      _peerValue = null;
      _peerRound = 0;
      _rolling = false;
      _status = DiceStatus.idle;
      _announcement = '';
      _particles.clear();
    });
  }
}
