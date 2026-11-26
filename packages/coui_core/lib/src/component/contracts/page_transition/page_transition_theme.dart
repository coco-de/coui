/// Theme overrides for the page transition.
library;

import 'package:coui_core/src/component/contracts/page_transition/page_transition_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for the page transition — how every new
/// screen of the app arrives and leaves.
///
/// Platform-neutral — no generic parameters.
@immutable
class CorePageTransitionTheme {
  /// Creates a [CorePageTransitionTheme].
  const CorePageTransitionTheme({this.style});

  /// Project-level base style. `null` → no project override.
  final CorePageTransitionStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CorePageTransitionTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
