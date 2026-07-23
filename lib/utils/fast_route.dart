import 'package:flutter/material.dart';

import '../services/app_theme.dart';
import '../services/goop_talk_engine.dart';

/// Snappy page route: 150ms pure fade, no scale or slide ghosting.
/// Each route is wrapped in a [ColoredBox] using the current theme's
/// scaffold color so the new route has an opaque background during the
/// fade transition — no see-through to the previous screen.
/// Also re-triggers the Goop sponge animation so new views show the
/// cool Goopian→English text scramble when sponge is active.
PageRoute<T> fastRoute<T>(Widget child) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) {
        GoopAnimationManager.instance.pulse();
        return ValueListenableBuilder<AppThemeMode>(
          valueListenable: AppTheme.notifier,
          builder: (_, __, ___) => ColoredBox(
            color: AppTheme.flair.scaffold,
            child: child,
          ),
        );
      },
      transitionsBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 150),
      reverseTransitionDuration: const Duration(milliseconds: 120),
    );
