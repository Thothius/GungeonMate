import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Winchester's trickshot gallery: a 2D billiard-physics shooting
/// minigame. 4 shots, 4 targets. Blue blocks bounce (max 4 bounces),
/// green blocks bounce once then shatter, red blocks swallow bullets.
/// Drag to aim with a laser sight; release to fire.
class WinchesterMinigameScreen extends StatefulWidget {
  const WinchesterMinigameScreen({super.key});

  @override
  State<WinchesterMinigameScreen> createState() => _WinchesterMinigameScreenState();
}

enum _BlockType { blue, green, red }

class _Block {
  final double col; // base col
  final int row;
  final _BlockType type;
  bool destroyed = false;
  double opacity = 1.0;

  // Sinusoidal movement parameters
  final double moveAmp;
  final double movePhase;

  _Block(this.col, this.row, this.type, {this.moveAmp = 0, this.movePhase = 0});

  double liveCol(double t) =>
      moveAmp == 0 ? col : col + math.sin(t * 2 * math.pi + movePhase) * moveAmp;
}

class _Target {
  final double x; // normalized 0..1
  final double y;
  bool hit = false;
  // Optional horizontal ping-pong movement amplitude (normalized).
  final double moveAmp;
  final double movePhase;
  _Target(this.x, this.y, {this.moveAmp = 0, this.movePhase = 0});

  double liveX(double t) =>
      moveAmp == 0 ? x : x + math.sin(t * 2 * math.pi + movePhase) * moveAmp;
}

class _Particle {
  Offset pos; // normalized
  Offset vel; // normalized velocity
  Color color;
  double size;
  double life; // 1.0 down to 0.0
  double decay;
  _Particle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.size,
    required this.life,
    required this.decay,
  });
}

class _Portal {
  final Offset enter; // normalized 0..1
  final Offset exit;  // normalized 0..1
  final Color enterColor;
  final Color exitColor;
  _Portal({required this.enter, required this.exit, required this.enterColor, required this.exitColor});
}

class _WinchesterMinigameScreenState extends State<WinchesterMinigameScreen>
    with SingleTickerProviderStateMixin {
  static const int cols = 16;
  static const int rows = 22;

  late final AnimationController _ticker;
  final math.Random _rng = math.Random();

  // Game state
  int _shotsLeft = 4;
  int _hits = 0;
  bool _gameOver = false;
  late List<_Block> _blocks;
  late List<_Target> _targets;
  List<_Portal> _portals = [];
  int _currentLevel = 1;
  int _portalCooldown = 0;

  // Dual-control mobile inputs
  Offset _knobOffset = Offset.zero;

  // Juice & Particles
  double _shakeAmount = 0.0;
  final List<_Particle> _particles = [];

  // Aiming
  double _aimAngle = -math.pi / 2; // straight up
  bool _aiming = false;

  // Live projectile (null when not simulating)
  Offset? _bullet;
  Offset _bulletVel = Offset.zero;
  int _bounces = 0;
  double _lastTick = 0;

  // Cannon position (normalized)
  static const Offset _cannon = Offset(0.5, 0.96);

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..addListener(_onTick)
      ..repeat();
    _buildStage();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _buildStage() {
    _blocks = [];
    _targets = [];
    _portals = [];
    _particles.clear();
    _shotsLeft = 4;
    _hits = 0;
    _gameOver = false;
    _bullet = null;
    _shakeAmount = 0.0;
    _portalCooldown = 0;

    void addRow(int row, int from, int to, _BlockType t, {double moveAmp = 0, double movePhase = 0}) {
      for (var c = from; c <= to; c++) {
        _blocks.add(_Block(c.toDouble(), row, t, moveAmp: moveAmp, movePhase: movePhase));
      }
    }

    if (_currentLevel == 1) {
      // --- Level 1: Chamber 1 (Var A - Keep It Simple) ---
      addRow(6, 2, 6, _BlockType.blue);
      addRow(6, 10, 14, _BlockType.blue);
      addRow(11, 4, 11, _BlockType.green);
      addRow(16, 5, 10, _BlockType.blue);
      _targets = [
        _Target(0.2, 0.14),
        _Target(0.4, 0.12),
        _Target(0.6, 0.12),
        _Target(0.8, 0.14),
      ];
    } else if (_currentLevel == 2) {
      // --- Level 2: Chamber 1 (Var B - Diagonal Columns) ---
      addRow(5, 1, 3, _BlockType.blue);
      addRow(8, 4, 6, _BlockType.green);
      addRow(11, 7, 9, _BlockType.blue);
      addRow(14, 10, 12, _BlockType.green);
      addRow(17, 13, 15, _BlockType.blue);
      _targets = [
        _Target(0.15, 0.15),
        _Target(0.35, 0.12),
        _Target(0.65, 0.12),
        _Target(0.85, 0.15),
      ];
    } else if (_currentLevel == 3) {
      // --- Level 3: Chamber 1 (Var C - Split Blockades) ---
      addRow(6, 0, 3, _BlockType.blue);
      addRow(6, 12, 15, _BlockType.blue);
      addRow(11, 3, 5, _BlockType.green);
      addRow(11, 10, 12, _BlockType.green);
      addRow(16, 6, 9, _BlockType.blue);
      _targets = [
        _Target(0.25, 0.12),
        _Target(0.45, 0.15),
        _Target(0.55, 0.15),
        _Target(0.75, 0.12),
      ];
    } else if (_currentLevel == 4) {
      // --- Level 4: Chamber 2 (Var A - Hazard Grid) ---
      addRow(7, 1, 4, _BlockType.blue);
      addRow(7, 5, 6, _BlockType.red);
      addRow(7, 7, 8, _BlockType.blue);
      addRow(7, 9, 10, _BlockType.red);
      addRow(7, 11, 14, _BlockType.blue);
      addRow(13, 3, 12, _BlockType.green, moveAmp: 1.5, movePhase: 0);
      addRow(17, 5, 10, _BlockType.blue);
      _targets = [
        _Target(0.2, 0.15, moveAmp: 0.06),
        _Target(0.5, 0.11, moveAmp: 0.14, movePhase: math.pi),
        _Target(0.8, 0.15, moveAmp: 0.06, movePhase: math.pi / 2),
        _Target(0.5, 0.35),
      ];
    } else if (_currentLevel == 5) {
      // --- Level 5: Chamber 2 (Var B - Red Maze) ---
      addRow(6, 2, 4, _BlockType.red);
      addRow(6, 11, 13, _BlockType.red);
      addRow(10, 5, 10, _BlockType.blue, moveAmp: 1.8, movePhase: 0);
      addRow(15, 3, 12, _BlockType.green);
      _targets = [
        _Target(0.12, 0.15, moveAmp: 0.04),
        _Target(0.38, 0.12, moveAmp: 0.08, movePhase: math.pi),
        _Target(0.62, 0.12, moveAmp: 0.08),
        _Target(0.88, 0.15, moveAmp: 0.04, movePhase: math.pi / 2),
      ];
    } else if (_currentLevel == 6) {
      // --- Level 6: Chamber 2 (Var C - Corner Sinks) ---
      addRow(5, 0, 2, _BlockType.red);
      addRow(5, 13, 15, _BlockType.red);
      addRow(10, 3, 6, _BlockType.blue);
      addRow(10, 9, 12, _BlockType.blue);
      addRow(15, 5, 10, _BlockType.red, moveAmp: 1.5, movePhase: math.pi / 4);
      _targets = [
        _Target(0.2, 0.14, moveAmp: 0.08),
        _Target(0.4, 0.11, moveAmp: 0.08, movePhase: math.pi),
        _Target(0.6, 0.11, moveAmp: 0.08),
        _Target(0.8, 0.14, moveAmp: 0.08, movePhase: math.pi / 2),
      ];
    } else if (_currentLevel == 7) {
      // --- Level 7: Chamber 3 (Var A - Portal Loop) ---
      addRow(8, 0, 4, _BlockType.red);
      addRow(8, 11, 15, _BlockType.red);
      addRow(14, 5, 10, _BlockType.blue);
      _portals = [
        _Portal(
          enter: const Offset(0.18, 0.60),
          exit: const Offset(0.82, 0.25),
          enterColor: Colors.cyanAccent,
          exitColor: Colors.orangeAccent,
        ),
        _Portal(
          enter: const Offset(0.82, 0.60),
          exit: const Offset(0.18, 0.25),
          enterColor: Colors.pinkAccent,
          exitColor: Colors.purpleAccent,
        ),
      ];
      _targets = [
        _Target(0.15, 0.14),
        _Target(0.35, 0.12),
        _Target(0.65, 0.12),
        _Target(0.85, 0.14),
      ];
    } else if (_currentLevel == 8) {
      // --- Level 8: Chamber 3 (Var B - Double Tunnel) ---
      addRow(7, 2, 13, _BlockType.red);
      addRow(13, 4, 11, _BlockType.blue, moveAmp: 1.5, movePhase: 0);
      _portals = [
        _Portal(
          enter: const Offset(0.15, 0.85),
          exit: const Offset(0.35, 0.15),
          enterColor: Colors.tealAccent,
          exitColor: Colors.yellowAccent,
        ),
        _Portal(
          enter: const Offset(0.85, 0.85),
          exit: const Offset(0.65, 0.15),
          enterColor: Colors.deepPurpleAccent,
          exitColor: Colors.greenAccent,
        ),
      ];
      _targets = [
        _Target(0.25, 0.22, moveAmp: 0.05),
        _Target(0.5, 0.12),
        _Target(0.75, 0.22, moveAmp: 0.05, movePhase: math.pi),
        _Target(0.5, 0.35),
      ];
    } else if (_currentLevel == 9) {
      // --- Level 9: Chamber 3 (Var C - The Portal Cross) ---
      addRow(6, 4, 11, _BlockType.red);
      addRow(12, 1, 5, _BlockType.blue);
      addRow(12, 10, 14, _BlockType.blue);
      _portals = [
        _Portal(
          enter: const Offset(0.12, 0.50),
          exit: const Offset(0.50, 0.15),
          enterColor: Colors.lightBlueAccent,
          exitColor: Colors.pinkAccent,
        ),
        _Portal(
          enter: const Offset(0.88, 0.50),
          exit: const Offset(0.50, 0.30),
          enterColor: Colors.amberAccent,
          exitColor: Colors.lightGreenAccent,
        ),
      ];
      _targets = [
        _Target(0.15, 0.22),
        _Target(0.35, 0.11, moveAmp: 0.06),
        _Target(0.65, 0.11, moveAmp: 0.06, movePhase: math.pi),
        _Target(0.85, 0.22),
      ];
    } else {
      // --- Level 10: Chamber 4 (The Ultimate Boss Level!) ---
      addRow(6, 3, 7, _BlockType.blue, moveAmp: 2.2, movePhase: 0);
      addRow(11, 8, 12, _BlockType.red, moveAmp: 2.2, movePhase: math.pi);
      addRow(16, 2, 5, _BlockType.green);
      addRow(16, 10, 13, _BlockType.green);
      _portals = [
        _Portal(
          enter: const Offset(0.15, 0.72),
          exit: const Offset(0.85, 0.32),
          enterColor: Colors.cyanAccent,
          exitColor: Colors.orangeAccent,
        ),
      ];
      _targets = [
        _Target(0.2, 0.15, moveAmp: 0.14, movePhase: 0),
        _Target(0.5, 0.11, moveAmp: 0.20, movePhase: math.pi),
        _Target(0.8, 0.15, moveAmp: 0.14, movePhase: math.pi / 2),
        _Target(0.5, 0.28, moveAmp: 0.08, movePhase: 0),
      ];
    }
    setState(() {});
  }

  // ---- Particles & Juice generator ----------------------------------------

  void _spawnParticles(Offset pos, Color color, int count, {double speed = 0.2, double size = 4.0}) {
    for (var i = 0; i < count; i++) {
      final angle = _rng.nextDouble() * 2 * math.pi;
      final mag = (0.3 + 0.7 * _rng.nextDouble()) * speed;
      _particles.add(_Particle(
        pos: pos,
        vel: Offset(math.cos(angle) * mag, math.sin(angle) * mag),
        color: color,
        size: (0.4 + 0.6 * _rng.nextDouble()) * size,
        life: 1.0,
        decay: 1.6 + _rng.nextDouble() * 2.2, // fades out in ~0.3 - 0.6 seconds
      ));
    }
  }

  // ---- Physics tick ------------------------------------------------------

  void _onTick() {
    final t = _ticker.value;
    double dt = t - _lastTick;
    if (dt < 0) dt += 1.0; // controller wrapped
    _lastTick = t;

    final seconds = dt * 8.0;

    // Shake decay
    if (_shakeAmount > 0) {
      _shakeAmount -= 24.0 * seconds;
      if (_shakeAmount < 0) _shakeAmount = 0;
    }

    // Handle fading green block opacities
    for (final b in _blocks) {
      if (b.destroyed && b.opacity > 0) {
        b.opacity -= 4.0 * seconds;
        if (b.opacity < 0) b.opacity = 0;
      }
    }

    // Update particle states
    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.pos += p.vel * seconds;
      p.life -= p.decay * seconds;
      if (p.life <= 0) {
        _particles.removeAt(i);
      }
    }

    if (_portalCooldown > 0) {
      _portalCooldown--;
    }

    if (_bullet == null) {
      if (mounted) setState(() {});
      return;
    }

    // Step physics multiple times per frame for precision & high speeds (Sub-stepping)
    const substeps = 3;
    final stepSeconds = seconds / substeps;

    for (var step = 0; step < substeps; step++) {
      if (_bullet == null) break;

      var pos = _bullet! + _bulletVel * stepSeconds;

      // Portal teleportation check
      if (_portalCooldown == 0 && _portals.isNotEmpty) {
        for (final p in _portals) {
          if ((pos - p.enter).distance < 0.045) {
            pos = p.exit;
            _portalCooldown = 12;
            _spawnParticles(p.enter, p.enterColor, 14, speed: 0.15, size: 3.5);
            _spawnParticles(p.exit, p.exitColor, 14, speed: 0.15, size: 3.5);
            break;
          }
          if ((pos - p.exit).distance < 0.045) {
            pos = p.enter;
            _portalCooldown = 12;
            _spawnParticles(p.exit, p.exitColor, 14, speed: 0.15, size: 3.5);
            _spawnParticles(p.enter, p.enterColor, 14, speed: 0.15, size: 3.5);
            break;
          }
        }
      }

      // Wall bounces (outer borders).
      if (pos.dx <= 0.015 || pos.dx >= 0.985) {
        _bulletVel = Offset(-_bulletVel.dx, _bulletVel.dy);
        pos = Offset(pos.dx.clamp(0.015, 0.985), pos.dy);
        _bounces++;
        _spawnParticles(pos, Colors.cyanAccent.withValues(alpha: 0.7), 4, speed: 0.12, size: 2.5);
        if (_bounces >= 5) {
          _killBullet();
          break;
        }
      }
      if (pos.dy <= 0.015 || pos.dy >= 0.985) {
        _bulletVel = Offset(_bulletVel.dx, -_bulletVel.dy);
        pos = Offset(pos.dx, pos.dy.clamp(0.015, 0.985));
        _bounces++;
        _spawnParticles(pos, Colors.cyanAccent.withValues(alpha: 0.7), 4, speed: 0.12, size: 2.5);
        if (_bounces >= 5) {
          _killBullet();
          break;
        }
      }

      // Block collisions (grid cells based on active liveCol location).
      final cellW = 1.0 / cols;
      final cellH = 1.0 / rows;
      for (final b in _blocks) {
        if (b.destroyed) continue;
        final liveC = b.liveCol(t);
        final bx = liveC * cellW;
        final by = b.row * cellH;

        if (pos.dx >= bx && pos.dx <= bx + cellW && pos.dy >= by && pos.dy <= by + cellH) {
          if (b.type == _BlockType.red) {
            _spawnParticles(pos, Colors.deepOrangeAccent, 10, speed: 0.18, size: 3.5);
            _killBullet();
            break;
          }

          // Reflect off nearest face: compare penetration depths.
          final cx = bx + cellW / 2;
          final cy = by + cellH / 2;
          final dx = (pos.dx - cx) / cellW;
          final dy = (pos.dy - cy) / cellH;

          if (dx.abs() > dy.abs()) {
            _bulletVel = Offset(-_bulletVel.dx, _bulletVel.dy);
            pos = Offset(dx > 0 ? bx + cellW + 0.005 : bx - 0.005, pos.dy);
          } else {
            _bulletVel = Offset(_bulletVel.dx, -_bulletVel.dy);
            pos = Offset(pos.dx, dy > 0 ? by + cellH + 0.005 : by - 0.005);
          }

          _bounces++;

          if (b.type == _BlockType.blue) {
            // Spark splash
            _spawnParticles(pos, const Color(0xFF6F8DF5), 6, speed: 0.16, size: 3.0);
          } else if (b.type == _BlockType.green) {
            b.destroyed = true;
            _shakeAmount = 4.0;
            // Shattering glass splash
            _spawnParticles(pos, const Color(0xFF1FB94C), 15, speed: 0.22, size: 4.0);
          }

          if (_bounces >= 5) {
            _killBullet();
            break;
          }
          break;
        }
      }

      // Target hits (FORGIVING HITBOX: check distance < 0.068 instead of 0.058!)
      for (final tg in _targets) {
        if (tg.hit) continue;
        final tx = tg.liveX(t);
        if ((pos - Offset(tx, tg.y)).distance < 0.068) {
          tg.hit = true;
          _hits++;
          _shakeAmount = 14.0; // Trigger micro-shake!
          _spawnParticles(Offset(tx, tg.y), const Color(0xFFFFD54F), 22, speed: 0.3, size: 5.0);
          _spawnParticles(Offset(tx, tg.y), const Color(0xFFD32F2F), 10, speed: 0.2, size: 3.5);
          _killBullet();
          break;
        }
      }

      if (_bounces >= 5) {
        _killBullet();
        break;
      }

      _bullet = pos;
    }

    if (mounted) setState(() {});
  }

  void _killBullet() {
    _bullet = null;
    _bounces = 0;
    if (_shotsLeft == 0 || _hits == 4) {
      _gameOver = true;
    }
  }

  void _fire() {
    if (_bullet != null || _gameOver || _shotsLeft <= 0) return;
    _shotsLeft--;
    _bounces = 0;
    _bullet = _cannon;
    _bulletVel = Offset(math.cos(_aimAngle), math.sin(_aimAngle)) * 0.55;
    _spawnParticles(_cannon, Colors.yellow, 6, speed: 0.15, size: 2.5);
  }

  void _updateAim(Offset local, Size size) {
    final n = Offset(local.dx / size.width, local.dy / size.height);
    final d = n - _cannon;
    var ang = math.atan2(d.dy, d.dx);
    if (ang > -0.15 && ang < math.pi / 2) ang = -0.15;
    if (ang < -math.pi + 0.15 || (ang > math.pi / 2)) ang = -math.pi + 0.15;
    setState(() => _aimAngle = ang);
  }

  (String, Color) get _rewardTier => switch (_hits) {
        4 => ('BLACK CHEST (S-TIER) — ACE!', Colors.white),
        3 => ('RED CHEST (A-TIER)', Colors.redAccent),
        2 => ('BLUE / GREEN CHEST (B/C-TIER)', Colors.lightBlueAccent),
        1 => ('BROWN CHEST (D-TIER)', const Color(0xFFB07B4F)),
        _ => ('NO REWARD — PRACTICE MORE!', Colors.white38),
      };

  @override
  Widget build(BuildContext context) {
    final (tierLabel, tierColor) = _rewardTier;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0908),
      appBar: AppBar(
        title: const Text("WINCHESTER'S GALLERY",
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset Campaign to Lvl 1',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _currentLevel = 1;
                _buildStage();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // HUD strip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _hudChip('SHOTS: $_shotsLeft / 4', Colors.amberAccent),
                    const SizedBox(width: 8),
                    _hudChip('HITS: $_hits / 4', Colors.greenAccent),
                    const SizedBox(width: 8),
                    _hudChip(tierLabel.split(' ').take(2).join(' '), tierColor),
                  ],
                ),
              ),
            ),
            
            // Visual Campaign Progress Bar
            _buildCampaignProgress(),
            
            // Game canvas (Fixed viewport size, direct non-touch input)
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _GalleryPainter(
                  blocks: _blocks,
                  targets: _targets,
                  particles: _particles,
                  portals: _portals,
                  cannon: _cannon,
                  aimAngle: _aimAngle,
                  bullet: _bullet,
                  time: _ticker.value,
                  showLaser: _bullet == null && !_gameOver,
                  aiming: _aiming,
                  shakeAmount: _shakeAmount,
                  cols: cols,
                  rows: rows,
                ),
              ),
            ),

            // Footer / game-over campaign ceremony
            if (_gameOver)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hits >= 3 ? Colors.greenAccent.withValues(alpha: 0.08) : Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hits >= 3 ? Colors.greenAccent.withValues(alpha: 0.6) : Colors.redAccent.withValues(alpha: 0.6),
                    width: 1.4,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _hits >= 3 
                          ? (_currentLevel == 10 ? '🏆 CAMPAIGN VICTOR!' : '🎉 STAGE PASSED!')
                          : '💀 STAGE FAILED!',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w900, 
                        color: _hits >= 3 ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _hits >= 3
                          ? (_currentLevel == 10 
                              ? 'Incredible trickshooting! You are a Gungeon Legend.' 
                              : 'Awesome trickshooting! Hit $_hits / 4 targets and earned $tierLabel!')
                          : 'Hit only $_hits / 4 targets. Resetting back to Level 1!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _hits >= 3 ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        side: BorderSide(color: _hits >= 3 ? Colors.greenAccent : Colors.redAccent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(_hits >= 3 
                          ? (_currentLevel == 10 ? Icons.emoji_events : Icons.arrow_forward_rounded)
                          : Icons.replay_rounded),
                      label: Text(_hits >= 3 
                          ? (_currentLevel == 10 ? 'Restart Campaign' : 'Next Level: Level ${_currentLevel + 1}')
                          : 'Restart from Level 1'),
                      onPressed: () {
                        setState(() {
                          if (_hits >= 3) {
                            if (_currentLevel == 10) {
                              _currentLevel = 1;
                            } else {
                              _currentLevel++;
                            }
                          } else {
                            _currentLevel = 1;
                          }
                          _buildStage();
                        });
                      },
                    ),
                  ],
                ),
              )
            else
              // DUAL-THUMB ARCADE CONTROLS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF14110F),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LEFT SIDE: Retro BAM! Fire button
                    GestureDetector(
                      onTapDown: (_) {
                        _fire();
                      },
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _shotsLeft > 0 ? const Color(0xFFD32F2F) : Colors.grey.shade800,
                          border: Border.all(color: Colors.white30, width: 3.0),
                          boxShadow: [
                            BoxShadow(
                              color: _shotsLeft > 0 ? Colors.redAccent.withValues(alpha: 0.35) : Colors.transparent,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'BAM!',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // RIGHT SIDE: PlayStation Analog Aiming Stick Pad
                    GestureDetector(
                      onPanStart: (details) {
                        setState(() => _aiming = true);
                        _updateAnalogAim(details.localPosition);
                      },
                      onPanUpdate: (details) {
                        _updateAnalogAim(details.localPosition);
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _aiming = false;
                          _knobOffset = Offset.zero;
                        });
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF231E1B),
                          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.25), width: 2.0),
                        ),
                        child: Stack(
                          children: [
                            // Outer ring markings
                            Center(
                              child: Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white10, width: 1.5),
                                ),
                              ),
                            ),
                            // Center track stick knob
                            Positioned(
                              left: 50 + _knobOffset.dx - 18,
                              top: 50 + _knobOffset.dy - 18,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF424242), Color(0xFF212121)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(color: Colors.amberAccent, width: 1.5),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.gps_fixed_rounded,
                                    size: 14,
                                    color: Colors.amberAccent.withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _updateAnalogAim(Offset localPosition) {
    // Pad center is at (50, 50) since pad size is 100x100.
    final dx = localPosition.dx - 50;
    final dy = localPosition.dy - 50;
    if (dx != 0 || dy != 0) {
      final angle = math.atan2(dy, dx);
      setState(() {
        _aimAngle = angle;
        _knobOffset = Offset(dx, dy);
        final dist = _knobOffset.distance;
        if (dist > 30) {
          _knobOffset = Offset(dx / dist * 30, dy / dist * 30);
        }
      });
    }
  }

  Widget _buildCampaignProgress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CAMPAIGN MODE: LEVEL $_currentLevel / 10',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.amberAccent, letterSpacing: 0.8),
              ),
              Text(
                _currentLevel == 10 ? 'FINAL BOSS STAGE' : 'CHAMBER ${((_currentLevel - 1) / 3).floor() + 1} - VAR ${String.fromCharCode(65 + (_currentLevel - 1) % 3)}',
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(10, (index) {
              final lvl = index + 1;
              final isCurrent = lvl == _currentLevel;
              final isPassed = lvl < _currentLevel;
              Color color;
              if (isCurrent) {
                color = Colors.amberAccent;
              } else if (isPassed) {
                color = Colors.greenAccent;
              } else {
                color = Colors.white12;
              }
              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: index == 9 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isCurrent ? [
                      BoxShadow(color: Colors.amberAccent.withValues(alpha: 0.5), blurRadius: 4, spreadRadius: 1),
                    ] : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _hudChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}

// =============================================================================
// Painter
// =============================================================================

class _GalleryPainter extends CustomPainter {
  final List<_Block> blocks;
  final List<_Target> targets;
  final List<_Particle> particles;
  final List<_Portal> portals;
  final Offset cannon;
  final double aimAngle;
  final Offset? bullet;
  final double time;
  final bool showLaser;
  final bool aiming;
  final double shakeAmount;
  final int cols;
  final int rows;

  final math.Random _rng = math.Random();

  _GalleryPainter({
    required this.blocks,
    required this.targets,
    required this.particles,
    required this.portals,
    required this.cannon,
    required this.aimAngle,
    required this.bullet,
    required this.time,
    required this.showLaser,
    required this.aiming,
    required this.shakeAmount,
    required this.cols,
    required this.rows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Micro viewport screen shake
    if (shakeAmount > 0) {
      final dx = (_rng.nextDouble() * 2 - 1) * shakeAmount;
      final dy = (_rng.nextDouble() * 2 - 1) * shakeAmount;
      canvas.translate(dx, dy);
    }

    // Dungeon backdrop with subtle vignette.
    paint.shader = RadialGradient(
      colors: [const Color(0xFF18120C), const Color(0xFF080605)],
      radius: 1.2,
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);
    paint.shader = null;

    // Outer wall frame.
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFF3A2E22);
    canvas.drawRect(Rect.fromLTWH(2, 2, size.width - 4, size.height - 4), paint);
    paint.style = PaintingStyle.fill;

    final cellW = size.width / cols;
    final cellH = size.height / rows;

    // Blocks
    for (final b in blocks) {
      if (b.destroyed && b.opacity <= 0) continue;

      final liveC = b.liveCol(time);
      final rect = Rect.fromLTWH(liveC * cellW + 1, b.row * cellH + 1, cellW - 2, cellH - 2);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));

      switch (b.type) {
        case _BlockType.blue:
          paint.color = const Color(0xFF2B4FD8).withValues(alpha: b.opacity);
          canvas.drawRRect(rrect, paint);
          paint.color = const Color(0xFF6F8DF5).withValues(alpha: 0.7 * b.opacity);
          canvas.drawRRect(
              RRect.fromRectAndRadius(rect.deflate(rect.width * 0.28), const Radius.circular(2)), paint);
        case _BlockType.green:
          paint.color = const Color(0xFF1FB94C).withValues(alpha: b.opacity);
          canvas.drawRRect(rrect, paint);
          paint.color = Colors.white.withValues(alpha: 0.35 * b.opacity);
          canvas.drawLine(rect.topLeft + Offset(rect.width * 0.3, 2),
              rect.bottomRight - Offset(rect.width * 0.3, 2), paint..strokeWidth = 1);
        case _BlockType.red:
          final pulse = 0.75 + 0.25 * math.sin(time * 10 * math.pi);
          paint.color = Color.lerp(const Color(0xFFB71C1C), const Color(0xFFFF5722), pulse)!.withValues(alpha: b.opacity);
          canvas.drawRRect(rrect, paint);
          paint.color = const Color(0xFFFFAB91).withValues(alpha: 0.8 * pulse * b.opacity);
          canvas.drawCircle(rect.center, rect.width * 0.18, paint);
      }
    }

    // Portals — energy gateways.
    for (final p in portals) {
      final p1 = Offset(p.enter.dx * size.width, p.enter.dy * size.height);
      final p2 = Offset(p.exit.dx * size.width, p.exit.dy * size.height);
      final r = size.width * 0.040;
      final pulse = 1.0 + 0.12 * math.sin(time * 8 * math.pi);

      // Portal 1 (Entrance)
      paint.style = PaintingStyle.fill;
      paint.color = p.enterColor.withValues(alpha: 0.15);
      canvas.drawCircle(p1, r * pulse, paint);

      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.0;
      paint.color = p.enterColor;
      canvas.drawCircle(p1, r * pulse, paint);
      paint.color = Colors.white;
      canvas.drawCircle(p1, r * 0.4, paint);

      // Portal 2 (Exit)
      paint.style = PaintingStyle.fill;
      paint.color = p.exitColor.withValues(alpha: 0.15);
      canvas.drawCircle(p2, r * pulse, paint);

      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.0;
      paint.color = p.exitColor;
      canvas.drawCircle(p2, r * pulse, paint);
      paint.color = Colors.white;
      canvas.drawCircle(p2, r * 0.4, paint);
    }
    paint.style = PaintingStyle.fill;

    // Targets — bullseye boards.
    for (final t in targets) {
      final cx = t.liveX(time) * size.width;
      final cy = t.y * size.height;
      final r = size.width * 0.035;
      if (t.hit) {
        paint.color = Colors.white12;
        canvas.drawCircle(Offset(cx, cy), r * 0.6, paint);
        continue;
      }
      paint.color = Colors.white;
      canvas.drawCircle(Offset(cx, cy), r, paint);
      paint.color = const Color(0xFFD32F2F);
      canvas.drawCircle(Offset(cx, cy), r * 0.68, paint);
      paint.color = Colors.white;
      canvas.drawCircle(Offset(cx, cy), r * 0.38, paint);
      paint.color = const Color(0xFFD32F2F);
      canvas.drawCircle(Offset(cx, cy), r * 0.15, paint);
    }

    // Particles Render
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.life);
      canvas.drawCircle(Offset(p.pos.dx * size.width, p.pos.dy * size.height), p.size, paint);
    }

    // Laser sight: raycast to first collision.
    if (showLaser) {
      final start = Offset(cannon.dx * size.width, cannon.dy * size.height);
      final dir = Offset(math.cos(aimAngle), math.sin(aimAngle));
      final end = _raycast(start, dir, size, cellW, cellH);
      paint
        ..color = Colors.redAccent.withValues(alpha: aiming ? 0.9 : 0.55)
        ..strokeWidth = aiming ? 2.0 : 1.4;

      const dash = 8.0;
      final total = (end - start).distance;
      final n = (total / dash).floor();
      for (var i = 0; i < n; i += 2) {
        final a = start + dir * (i * dash);
        final b = start + dir * math.min((i + 1) * dash, total);
        canvas.drawLine(a, b, paint);
      }
    }

    // Cannon.
    final cpos = Offset(cannon.dx * size.width, cannon.dy * size.height);
    paint.color = const Color(0xFF8D6E63);
    canvas.drawCircle(cpos, 13, paint);
    paint.color = const Color(0xFFFFD54F);
    canvas.save();
    canvas.translate(cpos.dx, cpos.dy);
    canvas.rotate(aimAngle);
    canvas.drawRect(const Rect.fromLTWH(0, -3.5, 24, 7), paint);
    canvas.restore();

    // Bullet.
    if (bullet != null) {
      final bp = Offset(bullet!.dx * size.width, bullet!.dy * size.height);
      paint.color = Colors.amberAccent;
      canvas.drawCircle(bp, 6, paint);
      paint.color = Colors.white;
      canvas.drawCircle(bp, 2.5, paint);
    }
  }

  /// March the laser ray until it hits a wall, block, or target.
  Offset _raycast(Offset start, Offset dir, Size size, double cellW, double cellH) {
    var p = start;
    const step = 6.0;
    int laserPortalCooldown = 0;

    for (var i = 0; i < 400; i++) {
      p += dir * step;
      if (p.dx <= 4 || p.dx >= size.width - 4 || p.dy <= 4 || p.dy >= size.height - 4) return p;

      // Portal teleportation check in raycast tracing
      if (laserPortalCooldown > 0) {
        laserPortalCooldown--;
      } else if (portals.isNotEmpty) {
        final normPos = Offset(p.dx / size.width, p.dy / size.height);
        for (final port in portals) {
          if ((normPos - port.enter).distance < 0.045) {
            p = Offset(port.exit.dx * size.width, port.exit.dy * size.height);
            laserPortalCooldown = 12;
            break;
          }
          if ((normPos - port.exit).distance < 0.045) {
            p = Offset(port.enter.dx * size.width, port.enter.dy * size.height);
            laserPortalCooldown = 12;
            break;
          }
        }
      }

      final col = (p.dx / cellW).floor();
      final row = (p.dy / cellH).floor();

      // Check moving block collision in raycast too!
      for (final b in blocks) {
        if (b.destroyed) continue;
        final liveC = b.liveCol(time);
        final bx = liveC * cellW;
        final by = b.row * cellH;
        if (p.dx >= bx && p.dx <= bx + cellW && p.dy >= by && p.dy <= by + cellH) {
          return p;
        }
      }

      // Check targets with their visual radius (raycast is strict, bullet hit is generous)
      for (final t in targets) {
        if (!t.hit &&
            (p - Offset(t.liveX(time) * size.width, t.y * size.height)).distance <
                size.width * 0.035) {
          return p;
        }
      }
    }
    return p;
  }

  @override
  bool shouldRepaint(_GalleryPainter old) => true;
}
