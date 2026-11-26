/// Platform-independent contract for a Hidden / collapse toggle container.
library;

import 'package:coui_core/src/component/contracts/hidden/core_hidden_direction.dart';
import 'package:coui_core/src/motion/easing_scale.dart';

/// Contract for a toggleable "hidden" wrapper that fades and collapses its
/// [child] on [hidden] = true.
///
/// Type parameters:
/// - [W] — platform widget type (`Widget` on Flutter, `Component` on Web).
abstract interface class CoreHiddenContract<W> {
  /// The content rendered inside the wrapper. Fades out and collapses on the
  /// chosen axis when [hidden] is `true`.
  W get child;

  /// Whether the content is currently hidden. When `true`, opacity animates
  /// to 0 and the element collapses along [direction] (unless [keepSpace]).
  bool get hidden;

  /// Axis along which the element collapses. When null, falls back to
  /// `CoreHiddenTheme.direction` or [CoreHiddenDirection.vertical].
  CoreHiddenDirection? get direction;

  /// Transition duration. When null, falls back to `CoreHiddenTheme.duration`
  /// or the design-system default (200 ms).
  Duration? get duration;

  /// Whether to reserve space for the hidden content. When `true`, only
  /// opacity animates and the original dimensions are preserved.
  bool? get keepSpace;

  /// When `true`, the element collapses from the trailing edge (right/bottom)
  /// instead of the leading edge (left/top).
  bool? get reverse;

  /// Easing curve of the fade / collapse transition, as cubic-bezier
  /// control points. When null, falls back to `CoreHiddenTheme.curve`
  /// then `CoreHiddenStyle.defaultTransitionCurve`.
  ///
  /// Platform-neutral on purpose: Flutter converts the four control
  /// points to a `Curve`, Web emits them as the `cubic-bezier(...)`
  /// timing function of its `transition` shorthand — one token, one
  /// curve on both platforms.
  CoreCubicBezier? get curve;

  /// Accessible label announced by screen readers (falls back to the
  /// container semantics).
  String? get semanticLabel;
}
