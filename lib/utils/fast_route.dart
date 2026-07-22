import 'package:flutter/material.dart';

/// Snappy page route: 180ms fade + slight scale-up, no ghosting of previous screen.
PageRoute<T> fastRoute<T>(Widget child) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, anim, __, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curve),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 150),
    );
