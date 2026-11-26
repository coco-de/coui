/// Theme data for `SliverGap` customisation.
library;

import 'package:coui_core/src/component/contracts/gap/gap_style.dart';
import 'package:meta/meta.dart';

/// Theme overrides for `SliverGap`.
///
/// Reuses the `CoreGapStyle` shape — `SliverGap` ignores
/// `crossAxisExtent` (the sliver protocol decides the cross axis) but
/// honours `size` and `color`. Keeping the slot type identical to
/// `CoreGapTheme` / `CoreMaxGapTheme` lets the three components share
/// resolver helpers and merge-chain conventions.
@immutable
class CoreSliverGapTheme {
  /// Creates a [CoreSliverGapTheme].
  const CoreSliverGapTheme({this.style});

  /// Per-theme default sliver gap style (folded into the resolver
  /// chain before the per-instance `widget.gapStyle`).
  final CoreGapStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreSliverGapTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
