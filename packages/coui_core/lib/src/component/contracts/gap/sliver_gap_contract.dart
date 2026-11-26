/// Platform-agnostic contract for `SliverGap`.
///
/// Flutter-first sliver gap: takes a fixed main-axis extent inside a
/// `CustomScrollView` / sliver list. Web does not have a sliver
/// protocol, so its `SliverGap` renders identically to `Gap`
/// (flex-basis along the parent's main axis) so the API stays
/// symmetric.
library;

import 'package:coui_core/src/color/core_color.dart';

/// Contract for the sliver variant of `Gap`.
abstract interface class CoreSliverGapContract {
  /// Gap size along the sliver's main axis (logical px).
  ///
  /// When null, falls back to `CoreSliverGapTheme.style?.size` or
  /// the component default (`CoreGapStyle.defaultSize` =
  /// `CoreSpace.space4`).
  double? get size;

  /// Fill colour painted across the gap. `null` is transparent.
  CoreColor? get color;
}
