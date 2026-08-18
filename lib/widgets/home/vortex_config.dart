import 'dart:math' as math;

/// Central configuration for the home-screen vortex animation system.
///
/// All vortex motion parameters in one documented place — the gungeoneer
/// sprite, junk particles, and any future vortex elements read from a
/// single [VortexConfig] instance. Tweak any value here to adjust the
/// simulation without hunting through widget code.
///
/// **Physics summary:**
/// The vortex is a swirling column of energy at the screen center. Objects
/// caught in it (gungeoneer, junk) orbit the center while the vortex
/// rhythmically sucks them in (radius shrinks, scale shrinks, opacity dims)
/// and releases them (radius grows, scale grows, opacity brightens). All
/// motion is always-forward — controllers use `repeat()` (never `reverse`),
/// and oscillation is achieved via sine/cosine mapping of a linearly
/// progressing value. This produces organic, non-repeating-feeling motion
/// that never visibly "bounces back."
///
/// **Bounding box model:**
/// Each object's orbit is bounded by a square box centered on screen.
///   • [boxFarFraction] — box size when object is farthest/smallest.
///   • [boxNearFraction] — box size when object is nearest/largest.
/// The orbit radius = boxSize / 2, so the object traces the box edge.
/// Per user spec: far = 15% screen width, near = 30% screen width.
class VortexConfig {
  // ── Bounding box (orbit area) ──

  /// Box size as a fraction of screen width when the object is at its
  /// farthest/smallest depth. User spec: 0.15 (15%).
  final double boxFarFraction;

  /// Box size as a fraction of screen width when the object is at its
  /// nearest/largest depth. User spec: 0.30 (30%).
  final double boxNearFraction;

  // ── Gungeoneer sprite ──

  /// Base display size of the gungeoneer sprite in logical px (at
  /// nearest/largest depth). At farthest depth it's ~55% of this.
  final double gungeoneerSize;

  /// Gungeoneer scale at farthest depth (depth=0). Range 0.0–1.0.
  final double gungeoneerScaleFar;

  /// Gungeoneer scale at nearest depth (depth=1). Range 0.0–1.5.
  final double gungeoneerScaleNear;

  /// Gungeoneer opacity at farthest depth. Never fully invisible.
  final double gungeoneerOpacityFar;

  /// Gungeoneer opacity at nearest depth.
  final double gungeoneerOpacityNear;

  /// Slight blur applied to the gungeoneer sprite (sigma in logical px).
  /// 0.0 = no blur. 0.5–1.5 = subtle dreamy blur. Uses ImageFiltered
  /// (not BackdropFilter) for performance — blurs only the sprite, not
  /// the background. Per Flutter 2026 guidance: ImageFiltered is
  /// dramatically cheaper than BackdropFilter for single-widget blur.
  final double gungeoneerBlurSigma;

  // ── Gungeoneer motion pacing (durations in seconds) ──

  /// Duration of the descent — the sprite falls from the top of the
  /// vortex to the bottom. This is the dominant phase: slow, deliberate,
  /// cinematic. 30s = a solid, unhurried descent. Lower = faster fall.
  ///
  /// The descent uses an ease-in curve (accelerating fall) so the sprite
  /// starts slow at the top and speeds up as it drops — like real
  /// gravity in a viscous medium.
  final double gungeoneerDescentDuration;

  /// Duration of the ascent — the sprite floats back up from the bottom
  /// to the top. Slower than the descent (floating up against gravity
  /// is languid). 25s = a gentle, drifting rise. Lower = faster rise.
  ///
  /// The ascent uses an ease-out curve (decelerating rise) so the sprite
  /// starts fast at the bottom and slows as it nears the top — like a
  /// bubble rising through water.
  final double gungeoneerAscentDuration;

  /// Duration of one full 360° spin of the gungeoneer sprite itself
  /// (rotateZ, 2D-safe — keeps sprite face-on, no edge-on flicker).
  /// The spin speed is modulated by the descent/ascent phase — faster
  /// while descending (tumbling through the vortex), slower while
  /// ascending (gently rotating as it floats up).
  /// 12s = base spin speed. Lower = faster spin.
  final double gungeoneerSpinDuration;

  /// Spin speed multiplier during descent. 2.0 = spins twice as fast
  /// while falling (tumbling). 1.0 = same speed as ascent.
  final double gungeoneerSpinDescentMultiplier;

  /// Horizontal sway amplitude as a fraction of the vertical drift range.
  /// 0.25 = sway is 25% of drift — subtle, not "all around the place."
  /// 0.0 = no sway (purely vertical). 1.0 = sway equals drift (circular).
  final double gungeoneerSwayFraction;

  /// Vertical orbit compression — makes the orbit an ellipse (taller
  /// than wide) to match the vortex's visual shape. 1.0 = perfect
  /// circle. 0.85 = slightly squashed vertically.
  final double gungeoneerOrbitYCompression;

  // ── Junk particle field ──

  /// Minimum orbit radius for junk particles (fraction of max screen
  /// dimension). Particles spread between this and [junkRadiusMax].
  final double junkRadiusMin;

  /// Maximum orbit radius for junk particles (fraction of max screen
  /// dimension).
  final double junkRadiusMax;

  /// Minimum junk sprite size in px.
  final double junkSizeMin;

  /// Maximum junk sprite size in px.
  final double junkSizeMax;

  /// Minimum junk orbital speed (rad/s). Negative = counter-clockwise.
  final double junkOmegaMin;

  /// Maximum junk orbital speed (rad/s).
  final double junkOmegaMax;

  /// Minimum junk opacity.
  final double junkOpacityMin;

  /// Maximum junk opacity.
  final double junkOpacityMax;

  /// Minimum junk sprite spin speed (rad/s).
  final double junkSpinMin;

  /// Maximum junk sprite spin speed (rad/s).
  final double junkSpinMax;

  /// Duration of the junk field controller (visual cycle). The actual
  /// motion is driven by elapsed time, not this controller — it just
  /// triggers repaints. 20s is fine; lower = more frequent repaints
  /// (smoother but more CPU).
  final double junkControllerDuration;

  /// Creates a vortex configuration with the given parameters.
  /// All parameters have sensible defaults — use [VortexConfig()] for
  /// the tuned, shipped values.
  const VortexConfig({
    this.boxFarFraction = 0.15,
    this.boxNearFraction = 0.30,
    this.gungeoneerSize = 220.0,
    this.gungeoneerScaleFar = 0.55,
    this.gungeoneerScaleNear = 1.0,
    this.gungeoneerOpacityFar = 0.72,
    this.gungeoneerOpacityNear = 1.0,
    this.gungeoneerBlurSigma = 0.8,
    this.gungeoneerDescentDuration = 30.0,
    this.gungeoneerAscentDuration = 25.0,
    this.gungeoneerSpinDuration = 12.0,
    this.gungeoneerSpinDescentMultiplier = 2.0,
    this.gungeoneerSwayFraction = 0.25,
    this.gungeoneerOrbitYCompression = 0.85,
    this.junkRadiusMin = 0.18,
    this.junkRadiusMax = 0.52,
    this.junkSizeMin = 22.0,
    this.junkSizeMax = 40.0,
    this.junkOmegaMin = 0.06,
    this.junkOmegaMax = 0.24,
    this.junkOpacityMin = 0.55,
    this.junkOpacityMax = 0.90,
    this.junkSpinMin = -1.2,
    this.junkSpinMax = 1.2,
    this.junkControllerDuration = 20.0,
  });

  /// Default configuration — the tuned, shipped values.
  static const defaultConfig = VortexConfig();

  // ── Computed helpers ──

  /// Bounding box size (px) at a given depth [0..1] for a screen width.
  double boxSizeAt(double depth, double screenWidth) {
    final far = screenWidth * boxFarFraction;
    final near = screenWidth * boxNearFraction;
    return far + (near - far) * depth;
  }

  /// Orbit radius (px) at a given depth for a screen width.
  double orbitRadiusAt(double depth, double screenWidth) =>
      boxSizeAt(depth, screenWidth) / 2;

  /// Gungeoneer scale at a given depth [0..1].
  double gungeoneerScaleAt(double depth) =>
      (gungeoneerScaleFar +
              (gungeoneerScaleNear - gungeoneerScaleFar) * depth)
          .clamp(0.1, 1.5);

  /// Gungeoneer opacity at a given depth [0..1].
  double gungeoneerOpacityAt(double depth) =>
      (gungeoneerOpacityFar +
              (gungeoneerOpacityNear - gungeoneerOpacityFar) * depth)
          .clamp(0.0, 1.0);

  /// Total cycle duration (descent + ascent) in seconds.
  double get gungeoneerCycleDuration =>
      gungeoneerDescentDuration + gungeoneerAscentDuration;

  /// Vertical position from elapsed time, given the drift range (px).
  ///
  /// Returns a value in [-range, +range] where -range = top of vortex
  /// and +range = bottom. The motion is:
  ///   • Descent phase (0 → descentDuration): ease-in fall from top to
  ///     bottom. Starts slow, accelerates (gravity in viscous medium).
  ///   • Ascent phase (descentDuration → cycleDuration): ease-out rise
  ///     from bottom to top. Starts fast, decelerates (bubble rising).
  ///
  /// The cycle repeats seamlessly — the sprite arrives at the top just
  /// as the next descent begins.
  double verticalFromElapsed(double elapsed, double range) {
    final cycle = gungeoneerCycleDuration;
    if (cycle <= 0) return 0; // degenerate config guard
    final t = elapsed % cycle; // time within current cycle
    if (t < gungeoneerDescentDuration) {
      // Descent: 0 → 1 (top → bottom), ease-in (accelerating fall).
      // ease-in = p² (quadratic) — starts slow, accelerates.
      final p = gungeoneerDescentDuration > 0
          ? t / gungeoneerDescentDuration
          : 1.0;
      final eased = p * p;
      return (-range + 2 * range * eased); // -range → +range
    } else {
      // Ascent: 1 → 0 (bottom → top), ease-out (decelerating rise).
      // ease-out = 1 - (1-p)² — starts fast, decelerates.
      final p = gungeoneerAscentDuration > 0
          ? (t - gungeoneerDescentDuration) / gungeoneerAscentDuration
          : 1.0;
      final eased = 1 - (1 - p) * (1 - p);
      return (range - 2 * range * eased); // +range → -range
    }
  }

  /// Depth (0=far/small at bottom, 1=near/large at top) from elapsed time.
  /// Tied to vertical position: top = near/large, bottom = far/small.
  double depthFromElapsed(double elapsed) {
    final cycle = gungeoneerCycleDuration;
    if (cycle <= 0) return 0; // degenerate config guard
    final t = elapsed % cycle;
    if (t < gungeoneerDescentDuration) {
      // Descent: depth 1 → 0 (near → far), ease-in.
      final p = gungeoneerDescentDuration > 0
          ? t / gungeoneerDescentDuration
          : 1.0;
      return 1.0 - (p * p);
    } else {
      // Ascent: depth 0 → 1 (far → near), ease-out.
      final p = gungeoneerAscentDuration > 0
          ? (t - gungeoneerDescentDuration) / gungeoneerAscentDuration
          : 1.0;
      return 1 - (1 - p) * (1 - p);
    }
  }

  /// Spin angle (radians) from elapsed time. The spin is continuous and
  /// always forward, but faster during descent (tumbling) and slower
  /// during ascent (gentle rotation).
  double spinFromElapsed(double elapsed) {
    final cycle = gungeoneerCycleDuration;
    if (cycle <= 0 || gungeoneerSpinDuration <= 0) return 0;
    final t = elapsed % cycle;
    final baseOmega = 2 * math.pi / gungeoneerSpinDuration; // rad/s
    if (t < gungeoneerDescentDuration) {
      // Descent: faster spin (tumbling).
      final descentSpin =
          baseOmega * gungeoneerSpinDescentMultiplier * t;
      return descentSpin;
    } else {
      // Ascent: normal spin. Continue from where descent left off.
      final descentSpin =
          baseOmega * gungeoneerSpinDescentMultiplier * gungeoneerDescentDuration;
      final ascentSpin =
          baseOmega * (t - gungeoneerDescentDuration);
      return descentSpin + ascentSpin;
    }
  }

  /// Horizontal sway from elapsed time, given the sway range (px).
  /// Uses a sine driven by elapsed time at a frequency that produces
  /// ~3 sway cycles per descent and ~2 per ascent — gives a gentle
  /// drifting spiral without being "all around the place."
  double swayFromElapsed(double elapsed, double range) {
    // Sway frequency: ~3 full cycles during descent, ~2 during ascent.
    final swayFreq = 3.0 / gungeoneerDescentDuration; // cycles per second
    return math.sin(elapsed * swayFreq * 2 * math.pi) * range;
  }
}
