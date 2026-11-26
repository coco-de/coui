/// Theme overrides for the unified Indicator component.
library;

import 'package:coui_core/src/component/contracts/indicator/indicator_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Indicator`.
///
/// Phase 6f shape: a single project-wide [style] slot. All chrome /
/// dimensional values (`offset`) live inside [CoreIndicatorStyle].
@immutable
class CoreIndicatorTheme {
  /// Creates a [CoreIndicatorTheme].
  const CoreIndicatorTheme({this.style});

  /// Project-wide composite style applied to every `Indicator`.
  ///
  /// Resolved before any per-instance `widget.indicatorStyle`.
  final CoreIndicatorStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreIndicatorTheme && other.style == style;

  @override
  int get hashCode => style.hashCode;
}
