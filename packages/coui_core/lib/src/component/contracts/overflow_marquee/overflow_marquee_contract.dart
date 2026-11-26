/// Platform-independent contract for the unified OverflowMarquee component.
library;

import 'package:coui_core/src/component/contracts/overflow_marquee/overflow_marquee_curve.dart';
import 'package:coui_core/src/component/contracts/overflow_marquee/overflow_marquee_style.dart';
import 'package:coui_core/src/component/contracts/scrollable_client/core_axis.dart';

/// Contract for a marquee-style scrolling wrapper.
///
/// Content that fits its bounding box renders statically; content that
/// overflows scrolls continuously along [direction], with optional edge
/// fades and hover-to-pause behaviour.
///
/// Per Epic #1302 dimensional / timing chrome overrides (cycle duration,
/// inter-cycle delay, speed step, edge fade portion) flow through the
/// single [overflowMarqueeStyle] field — see [CoreOverflowMarqueeStyle]
/// for the merge chain. Semantic enums ([direction], [curve]) and
/// behavioural boolean ([pauseOnHover]) stay flat on the widget.
///
/// Type parameters:
/// - [W] - platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreOverflowMarqueeContract<W> {
  /// Scrollable content.
  W get child;

  /// Axis along which overflow scrolls. Defaults to horizontal.
  CoreAxis get direction;

  /// Easing curve of each scroll cycle.
  CoreMarqueeCurve? get curve;

  /// Whether pointer hover pauses the animation.
  bool get pauseOnHover;

  /// Per-instance chrome / dimensional / timing style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreOverflowMarqueeTheme.style
  ///   → parent component slot override
  ///   → widget.overflowMarqueeStyle
  /// ```
  CoreOverflowMarqueeStyle? get overflowMarqueeStyle;
}
