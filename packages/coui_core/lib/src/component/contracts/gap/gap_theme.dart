/// Theme data for `Gap` customisation.
library;

import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:meta/meta.dart';

/// Theme overrides for `Gap`.
///
/// Exposes a single `{ style: CoreGapStyle? }` slot that participates
/// in the merge chain (`design-system default` → `style` →
/// `widget.gapStyle`). Project-wide gap defaults live here.
@immutable
class CoreGapTheme {
  /// Creates a [CoreGapTheme].
  const CoreGapTheme({this.style});

  /// Per-theme default gap style (folded into the resolver chain
  /// before the per-instance `widget.gapStyle`).
  final CoreGapStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreGapTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
