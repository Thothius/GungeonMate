import 'package:flutter/widgets.dart';

/// Ambient LEB-simulation context for item detail screens.
///
/// ItemDetailScreen wraps its body in this widget with the RESOLVED
/// `lebView` value, so synergy chips / rich links / peek sheets living
/// inside the detail subtree can push the next detail screen in the
/// same mode (`ItemDetailScreen(lebView: LebViewScope.maybeOf(context))`).
///
/// Catalog surfaces (browse, Ammonomicon) pass an explicit `lebView`
/// on the pushed route; run surfaces leave it null and the ownerSlot /
/// prefs fallback applies.
class LebViewScope extends InheritedWidget {
  /// Resolved simulation flag for the detail subtree.
  final bool lebView;

  const LebViewScope({
    super.key,
    required this.lebView,
    required super.child,
  });

  /// Nearest scope value, or null outside a detail screen.
  static bool? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LebViewScope>()
        ?.lebView;
  }

  @override
  bool updateShouldNotify(LebViewScope old) => old.lebView != lebView;
}
