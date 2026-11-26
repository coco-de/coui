/// Platform-independent contract for unified star rating components.
///
/// Defines the interface that all StarRating implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';
import 'package:coui_core/src/component/contracts/star_rating/star_rating_style.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Contract for a unified star rating component.
///
/// Displays interactive star-based rating with fractional support.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the
/// single [starRatingStyle] slot. Behavioural / semantic fields
/// (`value`, `max`, `step`, `enabled`) stay flat on the widget.
abstract interface class CoreStarRatingContract {
  /// Current rating value.
  double get value;

  /// Maximum rating value.
  double get max;

  /// Step increment for rating changes.
  double get step;

  /// Whether the rating is interactive.
  bool get enabled;

  /// Axis the stars are laid out along.
  ///
  /// Also decides which way an individual star fills: along the axis for
  /// [CoreAxis.horizontal] (left to right), and bottom-up for
  /// [CoreAxis.vertical] — a partly-filled vertical rating reads as a
  /// level, not as a sideways sweep.
  ///
  /// Pointer progress stays horizontal on both axes and both platforms,
  /// so a vertical rating is still dragged left-to-right.
  CoreAxis get direction;

  /// Star size step — `sm` 16 · `md` 20 · `lg` 24 · `xl` 32.
  /// Defaults to [CoreStarRatingStyle.defaultSize].
  CoreComponentSize get size;

  /// Whether the numeric value ("4.5") is drawn after the stars.
  /// Defaults to [defaultShowValue].
  bool get showValue;

  /// Default for [showValue] — the value is not drawn.
  static const bool defaultShowValue = false;

  /// Whether the [count] ("(128)") is drawn after the stars (and the
  /// value). Drawn only when [count] is non-null. Defaults to
  /// [defaultShowCount].
  bool get showCount;

  /// Default for [showCount] — the count is not drawn.
  static const bool defaultShowCount = false;

  /// Number of ratings the value summarises, drawn as "(count)" when
  /// [showCount] is true.
  int? get count;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreStarRatingTheme.style
  ///   → parent component slot override
  ///   → widget.starRatingStyle
  /// ```
  CoreStarRatingStyle? get starRatingStyle;
}
