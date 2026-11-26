/// Theme overrides for the unified Divider component.
library;

import 'package:coui_core/src/component/contracts/divider/divider_style.dart';
import 'package:meta/meta.dart';

/// Project-level style overrides for a unified Divider.
///
/// All chrome / dimensional overrides flow through the composite
/// [style] slot — there are no flat chrome fields (Epic #1543 / 7-6 (i)).
@immutable
class CoreDividerTheme {
  /// Creates a [CoreDividerTheme].
  const CoreDividerTheme({this.style});

  /// Project-wide composite style applied to every `Divider`.
  ///
  /// Resolved before any per-instance `widget.dividerStyle`.
  final CoreDividerStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreDividerTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
