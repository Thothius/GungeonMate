import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../services/haptics.dart';
import '../utils/responsive.dart';
import '../widgets/scale_button.dart';
import '../widgets/particle_engine.dart'
    show
        ParticlePreset,
        ParticlePresetX,
        ParticleColorSchema,
        ParticleColorSchemaX,
        ParticleSpeed,
        ParticleSpeedX,
        GlowEffect,
        GlowEffectX,
        ParticleField;

/// Experience Studio — a step-by-step wizard for creating your Gungeon
/// Mate experience. A persistent live preview at the top shows exactly
/// how your choices look together. Five focused steps:
///
/// 1. Theme — base palette (10 themes)
/// 2. Palette — variants (Unicorn/remix/custom colors)
/// 3. Particles — preset, color schema, speed, studio controls
/// 4. Typography — font family, base size, inventory size, weight
/// 5. Ambiance — glow, dialogue haptics, text speed
///
/// Changes preview instantly. Apply commits everything at the end.
class ExperienceStudioScreen extends StatefulWidget {
  const ExperienceStudioScreen({super.key});

  @override
  State<ExperienceStudioScreen> createState() => _ExperienceStudioScreenState();
}

class _ExperienceStudioScreenState extends State<ExperienceStudioScreen> {
  int _step = 0;
  late AppThemeMode _previewMode;
  // Store original state so Reset restores to what the user had, not
  // to hardcoded defaults. Prevents data loss if Reset is tapped by
  // accident.
  late final AppThemeMode _originalMode;

  @override
  void initState() {
    super.initState();
    _previewMode = AppTheme.mode;
    _originalMode = AppTheme.mode;
    AppTheme.previewNotifier.value = _previewMode;
  }

  @override
  void dispose() {
    AppTheme.previewNotifier.value = null;
    super.dispose();
  }

  static const _stepLabels = [
    'Theme',
    'Palette',
    'Particles',
    'Typography',
    'Ambiance',
  ];

  static const _stepDescriptions = [
    'Pick your base palette',
    'Fine-tune color variants',
    'Ambient particle effects',
    'Fonts and text sizing',
    'Screen glow and feel',
  ];

  void _applyAndClose() {
    Haptics.success();
    AppTheme.previewNotifier.value = null;
    AppTheme.setMode(_previewMode);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cleanTextTheme =
        GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme);
    final cleanTheme = Theme.of(context).copyWith(textTheme: cleanTextTheme);

    return Theme(
      data: cleanTheme,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── AppBar ──
              _buildTopBar(),
              // ── Live preview (always visible) ──
              _LivePreview(),
              // ── Step header with progress bar ──
              _buildStepHeader(),
              // ── Step content (animated transition between steps) ──
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, anim) {
                    // Slide + fade: incoming slides from right, outgoing fades left
                    final offset = child.key == ValueKey(_step)
                        ? Tween<Offset>(
                            begin: const Offset(0.15, 0),
                            end: Offset.zero,
                          ).animate(anim)
                        : Tween<Offset>(
                            begin: Offset.zero,
                            end: const Offset(-0.15, 0),
                          ).animate(anim);
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: offset,
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStepContent(),
                  ),
                ),
              ),
              // ── Navigation bar ──
              _buildNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final flair = AppTheme.flair;
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 8, top: 4, bottom: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: Colors.white70),
          ),
          const Spacer(),
          GoopText(
            'EXPERIENCE STUDIO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: flair.primary.withValues(alpha: 0.5),
              letterSpacing: 2.5,
            ),
          ),
          const Spacer(),
          ScaleButton(
            onTap: () => _showResetDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 13, color: Colors.white54),
                  const SizedBox(width: 5),
                  GoopText(
                    'RESET',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white54,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build a clear, big step header that shows the current step number,
  /// step name, a one-line description, and a progress bar. This replaces
  /// the old tiny dot indicator — 2026 mobile UX demands the user always
  /// knows where they are and what's next at a glance.
  Widget _buildStepHeader() {
    final flair = AppTheme.flair;
    final visibleIndices = List.generate(_stepLabels.length, (i) => i)
        .where((i) => i != 1 || _hasVariants())
        .toList();
    final visibleStep = visibleIndices.indexOf(_step);
    final totalVisible = visibleIndices.length;
    final progress = (visibleStep + 1) / totalVisible;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step counter + step name
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              GoopText(
                '${visibleStep + 1}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: flair.primary,
                  height: 1.0,
                ),
              ),
              GoopText(
                ' / $totalVisible',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.4),
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GoopText(
                  _stepLabels[_step].toUpperCase(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // One-line description
          GoopText(
            _stepDescriptions[_step],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.45),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar — clean, thick, themed
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(flair.primary),
            ),
          ),
          // Tappable step chips for quick navigation
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visibleIndices.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final stepIdx = visibleIndices[idx];
                final isCurrent = stepIdx == _step;
                final isDone = stepIdx < _step;
                return GestureDetector(
                  onTap: () => _goTo(stepIdx),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? flair.primary.withValues(alpha: 0.2)
                          : isDone
                              ? flair.primary.withValues(alpha: 0.08)
                              : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? flair.primary.withValues(alpha: 0.7)
                            : isDone
                                ? flair.primary.withValues(alpha: 0.25)
                                : Colors.white.withValues(alpha: 0.1),
                        width: isCurrent ? 1.4 : 1.0,
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: flair.primary.withValues(alpha: 0.15),
                                blurRadius: 6,
                                spreadRadius: 0,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: GoopText(
                        _stepLabels[stepIdx],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                          color: isCurrent
                              ? flair.primary
                              : isDone
                                  ? flair.primary.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _ThemeStep(
          previewMode: _previewMode,
          onPreview: (m) {
            setState(() => _previewMode = m);
            AppTheme.previewNotifier.value = m;
          },
          // Long-press a theme card: commit it immediately and close the
          // studio. Skips the rest of the wizard for users who just want
          // to switch themes.
          onQuickApply: (m) {
            setState(() => _previewMode = m);
            AppTheme.previewNotifier.value = m;
            _applyAndClose();
          },
        );
      case 1:
        return _PaletteStep(
          previewMode: _previewMode,
          onRefresh: () => setState(() {}),
        );
      case 2:
        return const _ParticlesStep();
      case 3:
        return const _TypographyStep();
      case 4:
        return const _AmbianceStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNavBar() {
    final isLast = _step == _stepLabels.length - 1;
    final flair = AppTheme.flair;
    final onPrimary = flair.primary.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;

    // Figure out the next step name for context (e.g. "Next: Particles")
    final visibleIndices = List.generate(_stepLabels.length, (i) => i)
        .where((i) => i != 1 || _hasVariants())
        .toList();
    final currentVisibleIdx = visibleIndices.indexOf(_step);
    final hasNext = currentVisibleIdx < visibleIndices.length - 1;
    final nextStepName = hasNext ? _stepLabels[visibleIndices[currentVisibleIdx + 1]] : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary action — big, full-width, clear
          if (isLast)
            // Last step: APPLY is the hero
            ScaleButton(
              onTap: _applyAndClose,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: flair.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: flair.primary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 20, color: onPrimary),
                    const SizedBox(width: 8),
                    GoopText(
                      'APPLY & SAVE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Non-last step: NEXT is the hero, with context label.
            // Extra glow + pulse animation so it's impossible to miss.
            ScaleButton(
              onTap: () => _goTo(_step + 1),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: flair.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: flair.primary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: flair.primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GoopText(
                      'NEXT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: onPrimary,
                        shadows: [
                          Shadow(
                            color: onPrimary.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: onPrimary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: GoopText(
                        nextStepName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: onPrimary.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20, color: onPrimary),
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(
                  duration: 1800.ms,
                  color: onPrimary.withValues(alpha: 0.15),
                ),
          const SizedBox(height: 8),
          // Secondary row: Back (left) + Apply (right, smaller)
          Row(
            children: [
              if (_step > 0)
                ScaleButton(
                  onTap: () => _goTo(_step - 1),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, size: 15, color: Colors.white60),
                        const SizedBox(width: 6),
                        GoopText(
                          'BACK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white60,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const SizedBox(width: 80),
              const Spacer(),
              if (!isLast)
                ScaleButton(
                  onTap: _applyAndClose,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: flair.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: flair.primary.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded, size: 15, color: flair.primary),
                        const SizedBox(width: 6),
                        GoopText(
                          'APPLY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: flair.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.flair.card,
        title: const GoopText('Reset to defaults?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: const GoopText(
          'Reverts your preview back to the theme you started with. Your saved settings won\'t change until you Apply.',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const GoopText('Cancel'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade900),
            onPressed: () {
              Navigator.pop(c);
              _resetAll();
            },
            child: const GoopText('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetAll() {
    Haptics.selection();
    // Restore to the user's original state, not to arbitrary defaults.
    // This prevents accidental data loss from the Reset button.
    setState(() {
      _previewMode = _originalMode;
      AppTheme.previewNotifier.value = _originalMode;
    });
  }

  /// Check if the current preview theme has palette variants (Step 2).
  bool _hasVariants() {
    return _previewMode == AppThemeMode.unicorn ||
        kThemeRemixes.containsKey(_previewMode) ||
        _previewMode == AppThemeMode.custom;
  }

  /// Navigate to a step, auto-skipping Step 2 (Palette) when the
  /// current theme has no variants. Prevents the dead-end "no variants"
  /// screen from being shown.
  void _goTo(int i) {
    if (i < 0 || i >= _stepLabels.length) return;
    // Skip Step 2 (Palette) if no variants available
    if (i == 1 && !_hasVariants()) {
      // Skip forward or backward past it
      if (i > _step) {
        i = 2; // skip to Particles
      } else {
        i = 0; // skip back to Theme
      }
    }
    Haptics.selection();
    setState(() => _step = i);
  }
}

// =============================================================================
// LIVE PREVIEW — mini app scene with card, text, particles, button
// =============================================================================

class _LivePreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sf = Responsive.factor(context);

    // Listen to BOTH previewNotifier (theme changes) and VisualPrefs
    // (particle/font/glow changes) so the preview updates instantly on
    // any setting change. Uses displayedFlair (preview mode) not flair
    // (committed mode) so the preview reflects the un-applied theme.
    return ValueListenableBuilder<AppThemeMode?>(
      valueListenable: AppTheme.previewNotifier,
      builder: (context, previewMode, _) {
        final flair = AppTheme.displayedFlair;
        return ValueListenableBuilder<VisualPrefs>(
          valueListenable: VisualPrefs.notifier,
          builder: (context, prefs, _) {
            return _buildPreview(flair, prefs, sf);
          },
        );
      },
    );
  }

  Widget _buildPreview(ThemeFlair flair, VisualPrefs prefs, double sf) {
    // Resolve particle colors — mirrors ThemeOverlay's logic so the
    // preview shows the same colors as the real background.
    List<Color>? particleColors;
    if (prefs.particleColorSchema != ParticleColorSchema.presetDefault) {
      if (prefs.particleColorSchema == ParticleColorSchema.themeMatch) {
        particleColors = [flair.primary, flair.secondary, flair.glowPrimary, flair.headlineStat];
      } else {
        particleColors = prefs.particleColorSchema.colors;
      }
    }

    // Determine if particles should show: either explicitly enabled or
    // the theme has an auto-on default (non-gungeonDust themes).
    final themeDefault = kThemeParticleDefaults[AppTheme.displayedMode] ??
        ParticlePreset.gungeonDust;
    final themeAutoOn = themeDefault != ParticlePreset.gungeonDust;
    final particlesOn = prefs.particlesEnabled || themeAutoOn;

    return Container(
          height: 160 * sf,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          decoration: BoxDecoration(
            color: flair.scaffold.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: flair.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: flair.primary.withValues(alpha: 0.08),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // ── "LIVE PREVIEW" label badge (top-left corner) ──
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: flair.primary.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(8),
                    ),
                    border: Border(
                      right: BorderSide(color: flair.primary.withValues(alpha: 0.3), width: 1),
                      bottom: BorderSide(color: flair.primary.withValues(alpha: 0.3), width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_rounded, size: 10, color: flair.primary),
                      const SizedBox(width: 4),
                      GoopText(
                        'LIVE PREVIEW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: flair.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Mini particle engine (behind everything) ──
              if (particlesOn)
                Positioned.fill(
                  child: ParticleField(
                    preset: prefs.particlePreset,
                    count: (prefs.particleCount * 0.5).round().clamp(4, 16),
                    sizeScale: prefs.particleSizeScale * 0.7,
                    opacity: prefs.particleOpacity,
                    glowOverride: prefs.particleGlowEffect,
                    lineLinksOverride: prefs.particleLineLinks ? true : null,
                    colorsOverride: particleColors,
                    bounce: prefs.particleBounce,
                    speedMultiplier: prefs.particleSpeed.multiplier,
                  ),
                ),
              // Glow overlay
              if (prefs.glowIntensity > 0)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.2,
                        colors: [
                          VisualPrefs.glowColors[prefs.glowColorIndex]
                              .withValues(alpha: prefs.glowIntensity * 0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              // Subtle scrim behind content for readability over particles
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        flair.scaffold.withValues(alpha: 0.3),
                        flair.scaffold.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Sample item card
                    Row(
                      children: [
                        // Mini card with quality badge
                        Container(
                          width: 48 * sf,
                          height: 48 * sf,
                          decoration: BoxDecoration(
                            color: flair.card,
                            borderRadius: BorderRadius.circular(flair.chipRadius),
                            border: Border.all(
                              color: flair.primary.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(Icons.gps_fixed,
                                    size: 22 * sf,
                                    color: flair.primary.withValues(alpha: 0.6)),
                              ),
                              Positioned(
                                top: 3,
                                right: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: GoopText('A',
                                      style: TextStyle(
                                        fontSize: 7 * sf,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      )),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Sample text in selected font + size
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GoopText(
                                'Sample Gun Name',
                                style: prefs.font.textStyle.copyWith(
                                  fontSize: (prefs.fontSize * 0.7 * sf)
                                      .clamp(8.0, 16.0),
                                  fontWeight: FontWeight.w800,
                                  color: flair.headlineStat,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              GoopText(
                                'A semiautomatic pistol with decent damage',
                                style: prefs.font.textStyle.copyWith(
                                  fontSize: (prefs.fontSize * 0.55 * sf)
                                      .clamp(7.0, 12.0),
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Sample button + chip row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: flair.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: GoopText(
                            'Sample Button',
                            style: TextStyle(
                              fontSize: 9 * sf,
                              fontWeight: FontWeight.w800,
                              color: flair.primary.computeLuminance() > 0.5
                                  ? Colors.black87
                                  : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: flair.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: flair.secondary.withValues(alpha: 0.4)),
                          ),
                          child: GoopText(
                            '✓ Chip',
                            style: TextStyle(
                              fontSize: 8 * sf,
                              fontWeight: FontWeight.w700,
                              color: flair.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Stat row
                    Row(
                      children: [
                        _miniStat('DMG', '56.0', flair, sf),
                        const SizedBox(width: 6),
                        _miniStat('DPS', '168', flair, sf),
                        const SizedBox(width: 6),
                        _miniStat('AMMO', '300', flair, sf),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
  }

  Widget _miniStat(String label, String value, ThemeFlair flair, double sf) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: flair.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoopText('$label ',
              style: TextStyle(
                  fontSize: 7 * sf,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.4))),
          GoopText(value,
              style: TextStyle(
                  fontSize: 8 * sf,
                  fontWeight: FontWeight.w900,
                  color: flair.headlineStat)),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 1 — THEME (grid of 10 themes)
// =============================================================================

class _ThemeStep extends StatelessWidget {
  final AppThemeMode previewMode;
  final ValueChanged<AppThemeMode> onPreview;
  final ValueChanged<AppThemeMode> onQuickApply;

  const _ThemeStep({
    required this.previewMode,
    required this.onPreview,
    required this.onQuickApply,
  });

  @override
  Widget build(BuildContext context) {
    final modes = kVisibleThemes;
    final activeMode = AppTheme.mode;

    return Column(
      children: [
        // Discoverability hint — tells users the long-press shortcut
        // exists so they don't have to traverse the full wizard just to
        // switch themes.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: GoopText(
            'Tap to preview  ·  Long-press to apply instantly',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.45),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: modes.length,
            itemBuilder: (context, i) {
              final m = modes[i];
              final f = AppTheme.flairFor(m);
              final isPreview = m == previewMode;
              final isActive = m == activeMode;

              return GestureDetector(
                onTap: () {
                  onPreview(m);
                  Haptics.selection();
                },
                onLongPress: () {
                  // _applyAndClose (called inside onQuickApply) already
                  // fires Haptics.success() — no duplicate haptic here.
                  onQuickApply(m);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: f.scaffold.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPreview ? f.primary : Colors.white.withValues(alpha: 0.08),
                width: isPreview ? 2.0 : 1.0,
              ),
              boxShadow: isPreview
                  ? [BoxShadow(color: f.primary.withValues(alpha: 0.2), blurRadius: 10)]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Color swatches
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _swatch(f.scaffold, true, false),
                    _swatch(f.primary, false, false),
                    _swatch(f.secondary, false, false),
                    _swatch(f.headlineStat, false, true),
                  ],
                ),
                const SizedBox(height: 6),
                GoopText(
                  m.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isPreview ? f.headlineStat : Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1.0,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 3),
                  GoopText('ACTIVE',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: f.primary,
                          letterSpacing: 0.8)),
                ],
              ],
            ),
          ),
        ).animate().fadeIn(duration: 200.ms, delay: (i * 40).ms);
            },
          ),
        ),
      ],
    );
  }

  Widget _swatch(Color color, bool left, bool right) {
    return Container(
      width: 24,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(
          left: left ? const Radius.circular(5) : Radius.zero,
          right: right ? const Radius.circular(5) : Radius.zero,
        ),
      ),
    );
  }
}

// =============================================================================
// STEP 2 — PALETTE (variants / custom colors)
// =============================================================================

class _PaletteStep extends StatelessWidget {
  final AppThemeMode previewMode;
  final VoidCallback onRefresh;

  const _PaletteStep({required this.previewMode, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final hasVariants = previewMode == AppThemeMode.unicorn ||
        kThemeRemixes.containsKey(previewMode);
    final isCustom = previewMode == AppThemeMode.custom;

    if (!hasVariants && !isCustom) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.palette_outlined,
                  size: 48, color: Colors.white.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              GoopText(
                'This theme has no palette variants.\n\nPick a different theme in Step 1, or use the Custom theme to define your own colors.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                    height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    if (isCustom) {
      return _CustomColorsStep(onRefresh: onRefresh);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoopText(
            'PALETTE VARIANTS',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppTheme.flair.primary.withValues(alpha: 0.8),
                letterSpacing: 1.5),
          ),
          const SizedBox(height: 14),
          if (previewMode == AppThemeMode.unicorn)
            _UnicornPalettes(onRefresh: onRefresh)
          else
            _RemixPalettes(mode: previewMode, onRefresh: onRefresh),
        ],
      ),
    );
  }
}

class _UnicornPalettes extends StatelessWidget {
  final VoidCallback onRefresh;
  const _UnicornPalettes({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppTheme.unicornPaletteNotifier,
      builder: (context, _) {
        final active = AppTheme.unicornPalette;
        final palettes = UnicornPalette.values;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: palettes.length,
          itemBuilder: (context, i) {
            final p = palettes[i];
            final pf = p.flair;
            final isSelected = p == active;
            return GestureDetector(
              onTap: () {
                AppTheme.setUnicornPalette(p);
                Haptics.selection();
                onRefresh();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? pf.primary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? pf.primary : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: pf.primary.withValues(alpha: 0.15), blurRadius: 8)]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Color swatches row
                    Row(
                      children: [
                        _miniSwatch(pf.scaffold, true, false),
                        _miniSwatch(pf.primary, false, false),
                        _miniSwatch(pf.headlineStat, false, true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GoopText(p.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected ? pf.primary : Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RemixPalettes extends StatelessWidget {
  final AppThemeMode mode;
  final VoidCallback onRefresh;
  const _RemixPalettes({required this.mode, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppTheme.remixNotifier,
      builder: (context, _) {
        final remixes = kThemeRemixes[mode]!;
        final active = AppTheme.remixFor(mode);
        final f = AppTheme.flairFor(mode);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: remixes.length,
          itemBuilder: (context, i) {
            final r = remixes[i];
            final rf = r.flair;
            final colors = rf != null
                ? [rf.scaffold, rf.primary, rf.headlineStat]
                : [f.scaffold, f.primary, f.headlineStat];
            final isSelected = i == active;
            return GestureDetector(
              onTap: () {
                AppTheme.setRemix(mode, i);
                Haptics.selection();
                onRefresh();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? f.primary.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? f.primary : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: f.primary.withValues(alpha: 0.15), blurRadius: 8)]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        for (int c = 0; c < colors.length; c++) ...[
                          if (c > 0) const SizedBox(width: 1),
                          _miniSwatch(colors[c], c == 0, c == colors.length - 1),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    GoopText(r.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected ? f.primary : Colors.white.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CustomColorsStep extends StatefulWidget {
  final VoidCallback onRefresh;
  const _CustomColorsStep({required this.onRefresh});

  @override
  State<_CustomColorsStep> createState() => _CustomColorsStepState();
}

class _CustomColorsStepState extends State<_CustomColorsStep> {
  late CustomThemeData _data;
  bool _loaded = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // Flush any pending save on dispose
    if (_loaded) {
      CustomThemeData.save(_data);
      AppTheme.setCustomThemeData(_data);
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    _data = await CustomThemeData.loadAsync();
    if (mounted) setState(() => _loaded = true);
  }

  /// Debounced save — updates in-memory data instantly for live preview,
  /// but only writes to disk 500ms after the last change. Prevents
  /// excessive SharedPreferences writes when rapidly tapping colors.
  void _scheduleSave() {
    AppTheme.setCustomThemeData(_data);
    AppTheme.refresh();
    widget.onRefresh();
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      CustomThemeData.save(_data);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GoopText('CUSTOM THEME COLORS',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Colors.white54)),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  setState(() => _data = CustomThemeData.random());
                  _scheduleSave();
                  Haptics.selection();
                },
                icon: const Icon(Icons.casino, size: 14),
                label: const GoopText('Randomize',
                    style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ColorSlot('Background', _data.scaffold,
              (c) { setState(() => _data = _data.copyWith(scaffold: c)); _scheduleSave(); }),
          _ColorSlot('Card', _data.card,
              (c) { setState(() => _data = _data.copyWith(card: c)); _scheduleSave(); }),
          _ColorSlot('Primary', _data.primary,
              (c) { setState(() => _data = _data.copyWith(primary: c)); _scheduleSave(); }),
          _ColorSlot('Secondary', _data.secondary,
              (c) { setState(() => _data = _data.copyWith(secondary: c)); _scheduleSave(); }),
          _ColorSlot('Accent / Headline', _data.headlineStat,
              (c) { setState(() => _data = _data.copyWith(headlineStat: c)); _scheduleSave(); }),
          _ColorSlot('Bullet', _data.bulletColor,
              (c) { setState(() => _data = _data.copyWith(bulletColor: c)); _scheduleSave(); }),
        ],
      ),
    );
  }
}

const _kColorPalette = <Color>[
  Color(0xFF0D0C0B), Color(0xFF1A1A1A), Color(0xFF1A101F), Color(0xFF0F0A14),
  Color(0xFF0A030C), Color(0xFF080510), Color(0xFF050308), Color(0xFF0A0F0E),
  Color(0xFF0E1018), Color(0xFF120D0A), Color(0xFF0D110E), Color(0xFF0A1118),
  Color(0xFFFF69B4), Color(0xFFFF1493), Color(0xFFE91E63), Color(0xFFFF4500),
  Color(0xFFFFD700), Color(0xFF00E5FF), Color(0xFF00E676), Color(0xFF7C4DFF),
  Color(0xFFB71C1C), Color(0xFF1B5E20), Color(0xFF1A237E), Color(0xFF4A148C),
];

class _ColorSlot extends StatelessWidget {
  final String label;
  final Color current;
  final ValueChanged<Color> onPicked;
  const _ColorSlot(this.label, this.current, this.onPicked);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GoopText(label,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white60)),
              const SizedBox(width: 8),
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                    color: current,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: Colors.white24, width: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _kColorPalette.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                if (i == _kColorPalette.length) {
                  return GestureDetector(
                    onTap: () async {
                      final picked = await showDialog<Color>(
                        context: context,
                        builder: (_) => _HsvPicker(initial: current),
                      );
                      if (picked != null) {
                        onPicked(picked);
                        Haptics.selection();
                      }
                    },
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white30, width: 1.5)),
                      child: const Icon(Icons.add, size: 16, color: Colors.white60),
                    ),
                  );
                }
                final c = _kColorPalette[i];
                final selected = c.toARGB32() == current.toARGB32();
                return GestureDetector(
                  onTap: () { onPicked(c); Haptics.selection(); },
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: selected ? Colors.white : Colors.white12,
                            width: selected ? 2.0 : 1.0)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HsvPicker extends StatefulWidget {
  final Color initial;
  const _HsvPicker({required this.initial});

  @override
  State<_HsvPicker> createState() => _HsvPickerState();
}

class _HsvPickerState extends State<_HsvPicker> {
  late double _h, _s, _v;

  @override
  void initState() {
    super.initState();
    final hsv = HSVColor.fromColor(widget.initial);
    _h = hsv.hue; _s = hsv.saturation; _v = hsv.value;
  }

  Color get _color => HSVColor.fromAHSV(1.0, _h, _s, _v).toColor();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.flair.card,
      title: const Text('Pick Color', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity, height: 40,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1.5)),
          ),
          _slider('Hue', _h, 0, 360, (v) => setState(() => _h = v),
              HSVColor.fromAHSV(1.0, _h, 1.0, 1.0).toColor()),
          _slider('Saturation', _s, 0, 1, (v) => setState(() => _s = v),
              HSVColor.fromAHSV(1.0, _h, _s, 1.0).toColor()),
          _slider('Lightness', _v, 0, 1, (v) => setState(() => _v = v), _color),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _color), child: const Text('OK')),
      ],
    );
  }

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white60)),
        Slider(value: value, min: min, max: max, activeColor: color, onChanged: onChanged),
      ],
    );
  }
}

Widget _miniSwatch(Color color, bool left, bool right) {
  return Container(
    width: 14, height: 26,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.horizontal(
        left: left ? const Radius.circular(3) : Radius.zero,
        right: right ? const Radius.circular(3) : Radius.zero,
      ),
    ),
  );
}

// =============================================================================
// STEP 3 — PARTICLES (preset + schema + speed + studio)
// =============================================================================

class _ParticlesStep extends StatelessWidget {
  const _ParticlesStep();

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enable toggle
              _ToggleRow(
                icon: Icons.auto_awesome_outlined,
                label: 'Enable Particles',
                value: prefs.particlesEnabled,
                onChanged: (v) { VisualPrefs.setParticles(v); Haptics.selection(); },
              ),
              const SizedBox(height: 18),
              if (prefs.particlesEnabled) ...[
                _StepLabel('PRESET'),
                const SizedBox(height: 10),
                _PresetGrid(current: prefs.particlePreset),
                const SizedBox(height: 18),
                _StepLabel('COLOR SCHEMA'),
                const SizedBox(height: 10),
                _SchemaGrid(current: prefs.particleColorSchema),
                const SizedBox(height: 18),
                _StepLabel('SPEED'),
                const SizedBox(height: 10),
                _SpeedRow(current: prefs.particleSpeed),
                const SizedBox(height: 18),
                _StepLabel('STUDIO'),
                const SizedBox(height: 10),
                _StudioSlider('Count', '${prefs.particleCount}', prefs.particleCount.toDouble(),
                    1, 32, 31, flair.headlineStat, (v) => VisualPrefs.setParticleCount(v.toInt())),
                const SizedBox(height: 10),
                _StudioSlider('Size', '${prefs.particleSizeScale.toStringAsFixed(1)}x',
                    prefs.particleSizeScale, 0.3, 2.0, 17, flair.headlineStat,
                    (v) => VisualPrefs.setParticleSizeScale(v)),
                const SizedBox(height: 10),
                _StudioSlider('Opacity', '${(prefs.particleOpacity * 100).toStringAsFixed(0)}%',
                    prefs.particleOpacity, 0.0, 1.0, 20, flair.headlineStat,
                    (v) => VisualPrefs.setParticleOpacity(v)),
                const SizedBox(height: 18),
                _StepLabel('GLOW EFFECT'),
                const SizedBox(height: 10),
                _GlowRow(current: prefs.particleGlowEffect),
                const SizedBox(height: 14),
                _ToggleRow(icon: Icons.timeline_outlined, label: 'Line Links',
                    value: prefs.particleLineLinks, onChanged: (v) { VisualPrefs.setParticleLineLinks(v); Haptics.selection(); }),
                const SizedBox(height: 10),
                _ToggleRow(icon: Icons.sports_baseball_outlined, label: 'Edge Bounce',
                    value: prefs.particleBounce, onChanged: (v) { VisualPrefs.setParticleBounce(v); Haptics.selection(); }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PresetGrid extends StatelessWidget {
  final ParticlePreset current;
  const _PresetGrid({required this.current});

  @override
  Widget build(BuildContext context) {
    final presets = [
      ParticlePreset.gungeonDust, ParticlePreset.cosmicStars,
      ParticlePreset.forgeEmbers, ParticlePreset.frostShards,
      ParticlePreset.unicornSparkles, ParticlePreset.goldenSparkle,
      ParticlePreset.cursedSmoke, ParticlePreset.bulletHell,
    ];
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: presets.map((p) {
        final isActive = p == current;
        final flair = AppTheme.flair;
        return GestureDetector(
          onTap: () { VisualPrefs.setParticlePreset(p); Haptics.selection(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? flair.primary.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? flair.primary.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.1),
                width: isActive ? 1.5 : 1.0,
              ),
              boxShadow: isActive
                  ? [BoxShadow(color: flair.primary.withValues(alpha: 0.1), blurRadius: 6)]
                  : null,
            ),
            child: GoopText(p.label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                    color: isActive ? flair.primary : Colors.white.withValues(alpha: 0.55))),
          ),
        );
      }).toList(),
    );
  }
}

class _SchemaGrid extends StatelessWidget {
  final ParticleColorSchema current;
  const _SchemaGrid({required this.current});

  @override
  Widget build(BuildContext context) {
    final schemas = ParticleColorSchema.values;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: schemas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final s = schemas[i];
          final isActive = s == current;
          final colors = s.colors;
          return GestureDetector(
            onTap: () { VisualPrefs.setParticleColorSchema(s); Haptics.selection(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? Colors.white.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
                  width: isActive ? 1.4 : 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (colors != null)
                    ...colors.take(3).map((c) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        width: 9, height: 9,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                      ),
                    ))
                  else
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.auto_awesome, size: 12, color: Colors.white54),
                    ),
                  GoopText(s.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                          color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.55))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpeedRow extends StatelessWidget {
  final ParticleSpeed current;
  const _SpeedRow({required this.current});

  @override
  Widget build(BuildContext context) {
    final speeds = ParticleSpeed.values;
    return Row(
      children: speeds.map((s) {
        final isActive = s == current;
        return Expanded(
          child: GestureDetector(
            onTap: () { VisualPrefs.setParticleSpeed(s); Haptics.selection(); },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? Colors.white.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Center(
                child: GoopText(s.label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.55))),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GlowRow extends StatelessWidget {
  final GlowEffect current;
  const _GlowRow({required this.current});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: GlowEffect.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final e = GlowEffect.values[i];
          final isActive = e == current;
          final flair = AppTheme.flair;
          return GestureDetector(
            onTap: () { VisualPrefs.setParticleGlowEffect(e); Haptics.selection(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? flair.card.withValues(alpha: 0.9) : flair.card.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                  width: isActive ? 1.5 : 1.0,
                ),
              ),
              child: Center(
                child: GoopText(e.label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isActive ? Colors.white : Colors.white54)),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// STEP 4 — TYPOGRAPHY (font family + sizes + weight)
// =============================================================================

class _TypographyStep extends StatelessWidget {
  const _TypographyStep();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepLabel('FONT FAMILY'),
              const SizedBox(height: 10),
              _FontFamilyGrid(current: prefs.font),
              const SizedBox(height: 18),
              _StepLabel('BASE FONT SIZE'),
              const SizedBox(height: 10),
              _FontSizeSlider(
                current: prefs.fontSize,
                onChanged: (v) => VisualPrefs.setFontSize(v),
              ),
              const SizedBox(height: 18),
              _StepLabel('INVENTORY FONT SIZE'),
              const SizedBox(height: 10),
              _FontSizeSlider(
                current: prefs.inventoryFontSize,
                onChanged: (v) => VisualPrefs.setInventoryFontSize(v),
              ),
              const SizedBox(height: 18),
              _StepLabel('WEIGHT BIAS'),
              const SizedBox(height: 10),
              _WeightRow(current: prefs.fontWeightBias),
            ],
          ),
        );
      },
    );
  }
}

class _FontFamilyGrid extends StatelessWidget {
  final AppFont current;
  const _FontFamilyGrid({required this.current});

  // Font categories for organized browsing. The first category
  // ("Featured") pins the two Gungeon-defining fonts at the top so
  // they're always easy to find: the official Gungeon pixel font and
  // Megrim (the app's signature thin-wire display font).
  static const _categories = <_FontCategory>[
    _FontCategory('Featured', [
      AppFont.gungeon,
      AppFont.megrim,
    ]),
    _FontCategory('Pixel & Retro', [
      AppFont.pressStart2p,
      AppFont.silkscreen,
      AppFont.vt323,
      AppFont.pixelifySans,
      AppFont.bungee,
      AppFont.bungeeShade,
      AppFont.rubik8bit,
      AppFont.dotgothic16,
    ]),
    _FontCategory('Sci-Fi & Tech', [
      AppFont.monoton,
      AppFont.blackOpsOne,
      AppFont.orbitron,
      AppFont.shareTechMono,
      AppFont.syncopate,
      AppFont.rajdhani,
      AppFont.audiowide,
      AppFont.russoOne,
      AppFont.fasterOne,
      AppFont.spaceGrotesk,
      AppFont.jetBrainsMono,
    ]),
    _FontCategory('Display & Impact', [
      AppFont.archivoBlack,
      AppFont.anton,
      AppFont.rowdies,
      AppFont.righteous,
      AppFont.teko,
      AppFont.fjallaOne,
      AppFont.bebasNeue,
      AppFont.kanit,
    ]),
    _FontCategory('Casual & Fun', [
      AppFont.comicNeue,
      AppFont.fredoka,
      AppFont.sniglet,
      AppFont.lemon,
      AppFont.lilitaOne,
      AppFont.spicyRice,
      AppFont.chewy,
      AppFont.boogaloo,
      AppFont.carterOne,
      AppFont.permanentMarker,
    ]),
    _FontCategory('Clean & Modern', [
      AppFont.dmSans,
      AppFont.outfit,
      AppFont.syne,
      AppFont.montserrat,
      AppFont.lexend,
      AppFont.comfortaa,
      AppFont.alata,
    ]),
    _FontCategory('Gothic & Fantasy', [
      AppFont.medievalSharp,
      AppFont.cinzelDecorative,
      AppFont.almendra,
      AppFont.metalMania,
      AppFont.unifrakturMaguntia,
      AppFont.newRocker,
      AppFont.rye,
      AppFont.nosifer,
      AppFont.cinzel,
    ]),
    _FontCategory('Serif & Editorial', [
      AppFont.playfairDisplay,
      AppFont.ebGaramond,
      AppFont.merriweather,
      AppFont.libreBaskerville,
      AppFont.specialElite,
      AppFont.coustard,
    ]),
    _FontCategory('Handwritten & Script', [
      AppFont.architectsDaughter,
      AppFont.rockSalt,
      AppFont.shadowsIntoLight,
      AppFont.lobster,
      AppFont.caveat,
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _categories.map((cat) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category header
              GoopText(cat.name.toUpperCase(),
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: flair.primary.withValues(alpha: 0.6),
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              // Font chips in this category
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cat.fonts.map((font) {
                  final isSelected = font == current;
                  return GestureDetector(
                    onTap: () { VisualPrefs.setFont(font); Haptics.selection(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? flair.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? flair.primary.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: flair.primary.withValues(alpha: 0.1), blurRadius: 6)]
                            : null,
                      ),
                      child: GoopText(font.label,
                          style: font.textStyle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.white54)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FontCategory {
  final String name;
  final List<AppFont> fonts;
  const _FontCategory(this.name, this.fonts);
}

class _FontSizeSlider extends StatelessWidget {
  final double current;
  final ValueChanged<double> onChanged;
  const _FontSizeSlider({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    final steps = VisualPrefs.fontSizeSteps;
    final activeStep = steps.indexOf(current);
    final stepLabel = current == 0 ? 'Auto' : '${current.toStringAsFixed(0)}pt';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live preview text in the actual size
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: flair.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: flair.primary.withValues(alpha: 0.12)),
          ),
          child: GoopText(
            'The quick brown fox jumps over the lazy dog. 1234567890',
            style: TextStyle(
              fontSize: current.clamp(6.0, 32.0),
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.3,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GoopText('Size', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white60)),
            GoopText(stepLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: flair.headlineStat)),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
            activeTrackColor: flair.primary,
            inactiveTrackColor: Colors.white12,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: activeStep >= 0 ? activeStep.toDouble() : 3.0,
            min: 0,
            max: (steps.length - 1).toDouble(),
            divisions: steps.length - 1,
            label: stepLabel,
            onChanged: (v) => onChanged(steps[v.toInt()]),
          ),
        ),
        // Step dots
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (i) {
            final on = i == (activeStep >= 0 ? activeStep : 3);
            return GoopText(steps[i].toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 7,
                    fontWeight: on ? FontWeight.w900 : FontWeight.w400,
                    color: on ? flair.primary : Colors.white.withValues(alpha: 0.3)));
          }),
        ),
      ],
    );
  }
}

class _WeightRow extends StatelessWidget {
  final int current;
  const _WeightRow({required this.current});

  @override
  Widget build(BuildContext context) {
    final options = [-2, -1, 0, 1, 2];
    final labels = ['Lighter', 'Light', 'Normal', 'Bold', 'Bolder'];
    final flair = AppTheme.flair;
    return Row(
      children: List.generate(options.length, (i) {
        final isActive = options[i] == current;
        return Expanded(
          child: GestureDetector(
            onTap: () { VisualPrefs.setFontWeightBias(options[i]); Haptics.selection(); },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: isActive ? flair.primary.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? flair.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Center(
                child: GoopText(labels[i],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        color: isActive ? flair.primary : Colors.white.withValues(alpha: 0.55))),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// =============================================================================
// STEP 5 — AMBIANCE (glow + dialogue haptics + text speed)
// =============================================================================

class _AmbianceStep extends StatelessWidget {
  const _AmbianceStep();

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return ValueListenableBuilder<VisualPrefs>(
      valueListenable: VisualPrefs.notifier,
      builder: (context, prefs, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StepLabel('SCREEN GLOW'),
              const SizedBox(height: 10),
              _StudioSlider('Glow Intensity',
                  '${(prefs.glowIntensity * 100).toStringAsFixed(0)}%',
                  prefs.glowIntensity, 0.0, 1.0, 20, flair.headlineStat,
                  (v) => VisualPrefs.setGlow(v)),
              const SizedBox(height: 18),
              _StepLabel('GLOW COLOR'),
              const SizedBox(height: 10),
              _GlowColorRow(currentIndex: prefs.glowColorIndex),
              const SizedBox(height: 18),
              _StepLabel('DIALOGUE'),
              const SizedBox(height: 10),
              _ToggleRow(
                icon: Icons.vibration,
                label: 'Dialogue Haptics',
                value: prefs.dialogueHapticsEnabled,
                onChanged: (v) { VisualPrefs.setDialogueHapticsEnabled(v); Haptics.selection(); },
              ),
              const SizedBox(height: 12),
              _StudioSlider('Text Speed', '${prefs.dialogueTextSpeedMs}ms',
                  prefs.dialogueTextSpeedMs.toDouble(), 5, 80, 75, flair.headlineStat,
                  (v) => VisualPrefs.setDialogueTextSpeedMs(v.toInt())),
            ],
          ),
        );
      },
    );
  }
}

class _GlowColorRow extends StatelessWidget {
  final int currentIndex;
  const _GlowColorRow({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final colors = VisualPrefs.glowColors;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = colors[i];
          final isSelected = i == currentIndex;
          return GestureDetector(
            onTap: () { VisualPrefs.setGlowColorIndex(i); Haptics.selection(); },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.15),
                  width: isSelected ? 2.5 : 1.0,
                ),
                boxShadow: isSelected ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)] : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Shared widgets
// =============================================================================

class _StepLabel extends StatelessWidget {
  final String text;
  const _StepLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return GoopText(text,
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppTheme.flair.primary.withValues(alpha: 0.85),
            letterSpacing: 1.5));
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final flair = AppTheme.flair;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: flair.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: flair.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 10),
          Expanded(
            child: GoopText(label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70)),
          ),
          Switch(
            value: value,
            activeColor: flair.primary,
            activeTrackColor: flair.primary.withValues(alpha: 0.25),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _StudioSlider extends StatelessWidget {
  final String label, displayValue;
  final double value, min, max;
  final int divisions;
  final Color color;
  final ValueChanged<double> onChanged;
  const _StudioSlider(this.label, this.displayValue, this.value, this.min, this.max,
      this.divisions, this.color, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GoopText(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
              GoopText(displayValue, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          SizedBox(
            height: 28,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                activeTrackColor: color,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
              ),
              child: Slider(value: value, min: min, max: max, divisions: divisions, onChanged: onChanged),
            ),
          ),
        ],
      ),
    );
  }
}
