/// Platform-agnostic contract for `Gap`.
///
/// Adds spacing between children of a flex container (Row/Column on
/// Flutter, flex on Web). The gap automatically orients along the
/// parent's main axis — consumers do not specify the axis manually.
library;

import 'package:coui_core/src/color/core_color.dart';

/// Contract for the unified `Gap` layout primitive.
abstract interface class CoreGapContract {
  /// Gap size along the parent's main axis (logical px).
  ///
  /// When null, falls back to `CoreGapTheme.style?.size` or the
  /// component default (`CoreGapStyle.defaultSize` =
  /// `CoreSpace.space4`).
  double? get size;

  /// Gap size along the parent's cross axis (logical px).
  ///
  /// When null the gap stretches to match the parent's cross-axis
  /// constraint — Flutter's `RenderFlex` passes its cross extent,
  /// Web uses `align-self: stretch`.
  ///
  /// Mirrors `gap_package.Gap.crossAxisExtent`.
  double? get crossAxisExtent;

  /// Fill colour painted across the gap's rectangle.
  ///
  /// When null the gap is transparent. Mirrors
  /// `gap_package.Gap.color`.
  CoreColor? get color;
}
