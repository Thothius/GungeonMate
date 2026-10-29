import 'package:flutter/widgets.dart';

/// Reduced-motion utility.
///
/// Wraps `MediaQuery.disableAnimationsOf(context)` so widgets with their own
/// animation controllers can respect the platform's "remove animations"
/// accessibility setting without repeating the MediaQuery lookup everywhere.
///
/// Usage in a `State` that owns an `AnimationController`:
/// ```dart
/// late bool _reduceMotion;
///
/// @override
/// Widget build(BuildContext context) {
///   _reduceMotion = ReduceMotion.of(context);
///   if (_reduceMotion) {
///     // render a static snapshot — no controller ticks
///   }
///   // ...normal animated build...
/// }
/// ```
///
/// In `initState`, do NOT read this (no context yet). Instead, start the
/// controller conditionally in `didChangeDependencies` or simply let the
/// build method skip the animated path on the first frame.
class ReduceMotion {
  const ReduceMotion._();

  /// True when the platform has requested reduced animations.
  /// Mirrors `MediaQuery.disableAnimationsOf(context)`.
  static bool of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}
