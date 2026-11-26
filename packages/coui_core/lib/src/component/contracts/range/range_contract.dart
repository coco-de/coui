/// Platform-independent contract for range slider components.
library;

import 'package:coui_core/src/component/contracts/range/range_style.dart';

/// Contract for a dual-handle range slider component.
///
/// Unlike `Slider` (single value), `Range` selects a `[minValue,
/// maxValue]` interval within the `[min, max]` bounds.
///
/// Per Epic #1302, every chrome / dimensional override flows through
/// the single [rangeStyle] field — see [CoreRangeStyle] for the merge
/// chain. Behaviour fields (values / range / step / divisions /
/// callback / enabled) stay flat because they describe the range
/// slider's **state and interaction**. The default bounds are
/// [CoreRangeContract.defaultMin] / [CoreRangeContract.defaultMax] —
/// used by both Flutter and Web `Range` widgets so the `[min, max]`
/// interval matches across platforms.
///
/// Type parameter:
/// - [W] — widget type (`Widget` for Flutter, `Component` for Web) used
///   by the optional `leading` / `trailing` composition slots.
abstract interface class CoreRangeContract<W> {
  /// Default lower bound — the left edge of the track. Shared by
  /// Flutter / Web `Range` const constructors so the `[min, max]`
  /// interval matches across platforms.
  static const double defaultMin = 0;

  /// Default upper bound — the right edge of the track.
  static const double defaultMax = 100;

  /// Current minimum (lower handle) value of the selected range.
  double get minValue;

  /// Current maximum (upper handle) value of the selected range.
  double get maxValue;

  /// Absolute minimum value (left bound of the track).
  double get min;

  /// Absolute maximum value (right bound of the track).
  double get max;

  /// Step increment, or `null` to derive from [divisions].
  double? get step;

  /// Number of discrete divisions on the track.
  int? get divisions;

  /// Whether the range slider is interactive.
  bool get enabled;

  /// Called when either handle changes — receives `(minValue, maxValue)`.
  void Function(double, double)? get onChanged;

  /// Optional widget displayed before the slider track.
  W? get leading;

  /// Optional widget displayed after the slider track.
  W? get trailing;

  /// Per-instance range style covering track + thumb chrome plus the
  /// leading/trailing gap.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreRangeTheme.style
  ///   → parent component slot override
  ///   → widget.rangeStyle
  /// ```
  CoreRangeStyle? get rangeStyle;
}
