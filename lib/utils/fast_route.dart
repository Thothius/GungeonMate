import 'package:flutter/material.dart';

import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';
import '../theme/tokens.dart';

/// Snappy page route with a fade + subtle upward slide.
///
/// Uses [Motion.enter] duration (400ms) with [Easing.emphasizedDecelerate]
/// for the enter, and [Motion.exit] duration (250ms) with
/// [Easing.emphasizedAccelerate] for the exit — per the motion-design
/// skill's canonical duration/curve table.
///
/// Each route is wrapped in a [ColoredBox] using the current theme's
/// scaffold color so the new route has an opaque background during the
/// transition — no see-through to the previous screen.
/// Also re-triggers the Goop sponge animation so new views show the
/// cool Goopian→English text scramble when sponge is active.
PageRoute<T> fastRoute<T>(Widget child) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) {
    GoopAnimationManager.instance.pulse();
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.notifier,
      builder:
          (_, __, ___) =>
              ColoredBox(color: AppTheme.flair.scaffold, child: child),
    );
  },
  transitionsBuilder: (_, anim, __, child) {
    // Fade + subtle 16dp upward slide. The slide is small enough
    // to feel native, not gimmicky — it communicates spatial
    // direction (forward = up/over) without ghosting.
    final curved = CurvedAnimation(
      parent: anim,
      curve: Easing.emphasizedDecelerate,
      reverseCurve: Easing.emphasizedAccelerate,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
  transitionDuration: Motion.enter,
  reverseTransitionDuration: Motion.exit,
);
