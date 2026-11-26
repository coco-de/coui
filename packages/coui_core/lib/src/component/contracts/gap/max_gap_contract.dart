/// Platform-agnostic contract for `MaxGap`.
///
/// Like `Gap`, but wrapped in `Flexible` on Flutter so the gap
/// takes at most `size` on the main axis and shrinks when the parent
/// is too small.
library;

import 'package:coui_core/src/color/core_color.dart';

/// Contract for the flexible `MaxGap` layout primitive.
abstract interface class CoreMaxGapContract {
  /// Maximum gap size along the parent's main axis (logical px).
  ///
  /// When null, falls back to `CoreMaxGapTheme.style?.size` or the
  /// component default (`CoreGapStyle.defaultSize` =
  /// `CoreSpace.space4`).
  double? get size;

  /// Gap size along the parent's cross axis (logical px). `null`
  /// stretches to the parent's cross constraint.
  double? get crossAxisExtent;

  /// Fill colour for the gap rectangle. `null` is transparent.
  CoreColor? get color;
}
