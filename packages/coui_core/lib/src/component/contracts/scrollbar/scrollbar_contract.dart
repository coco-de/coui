/// Platform-independent contract for unified scrollbar components.
///
/// Defines the interface that all `Scrollbar` implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/scrollbar/scrollbar_axis.dart';
import 'package:coui_core/src/component/contracts/scrollbar/scrollbar_style.dart';
import 'package:coui_core/src/component/contracts/scrollbar/scrollbar_visibility.dart';
import 'package:coui_core/src/motion/duration_token.dart';

/// Contract for a unified scrollbar component.
///
/// `Scrollbar` wraps a scrollable [child] and renders a
/// design-system scrollbar around it. On Flutter the thumb is
/// overlay-painted (`RawScrollbar`); on Web the browser's own scrollbar is
/// hidden and the thumb is a `<div>` drawn over the content — both float
/// above the content and take none of its width. Both platforms share the
/// same behavioural surface ([axis], [visibility], [interactive]) and
/// chrome slot ([scrollbarStyle]).
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreScrollbarContract<W> {
  /// Idle time (ms) the thumb stays visible after the last scroll
  /// before the fade-out starts — `auto` / `thin` visibility. Shared
  /// behaviour timing so both platforms fade in sync.
  static const int timeToFadeMs = CoreDuration.normal * 3;

  /// Thumb fade-out animation duration (ms) — `auto` / `thin`
  /// visibility. Shared behaviour timing so both platforms fade in
  /// sync.
  static const int fadeDurationMs = CoreDuration.moderate;

  /// Time (ms) the thumb takes to change between its resting and its
  /// hovered / dragged look. Both platforms animate it.
  static const int hoverTransitionMs = CoreDuration.normal;

  /// How much of the viewport a tap on the track pages the content by,
  /// toward the tap — Flutter's page step. Shared so Web pages the same
  /// distance.
  static const double trackTapPageFraction = 0.8;

  /// Time (ms) the content takes to move that page — Flutter's
  /// `RawScrollbar` eases the move rather than jumping.
  static const int trackTapDurationMs = CoreDuration.instant;

  /// The scrollable content wrapped by the scrollbar.
  W? get child;

  /// Axis along which scrolling (and the thumb) is constrained.
  /// Defaults to [CoreScrollbarAxis.both].
  CoreScrollbarAxis get axis;

  /// Thumb visibility mode. Defaults to
  /// [CoreScrollbarVisibility.auto].
  CoreScrollbarVisibility get visibility;

  /// Whether the scrollbar affordance itself may be operated —
  /// dragging the thumb to scroll. Defaults to `true`.
  ///
  /// Gates the bar, not the content: the wrapped scrollable still
  /// scrolls by wheel, touch and keyboard either way.
  ///
  /// Reaches assistive technology on both platforms, because a bar the
  /// user may not operate must not advertise an operation. Flutter drops
  /// the `increase` / `decrease` actions from its slider-shaped node;
  /// Web states `aria-disabled` on its `role="scrollbar"` node. Neither
  /// drops the *position* it reports — that stays readable regardless.
  ///
  /// Flutter's is an enforcement (the actions are gone), Web's is an
  /// assertion (there were no actions to remove). Flutter also withholds
  /// the actions on a second condition Web has no equivalent for: content
  /// that fits has nowhere to go, so no step is offered.
  ///
  /// The pointer half is the same on both: the thumb draws itself, so a bar
  /// that is not interactive is simply not hit-tested — no hover look, no
  /// dragging, no paging by tapping the track.
  ///
  /// On Web `interactive: false` additionally emits
  /// `overscroll-behavior: contain` on the scroll root, which stops
  /// scroll chaining to ancestors. That predates the accessibility
  /// wiring above, has no Flutter counterpart, and is unrelated to
  /// dragging a thumb — treat it as an artefact rather than as part of
  /// what this flag means.
  bool get interactive;

  /// Per-instance chrome style (thumb colour / thickness / radius).
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// CoreScrollbarStyle.defaultX
  ///   → CoreScrollbarTheme.style
  ///   → widget.scrollbarStyle
  /// ```
  CoreScrollbarStyle? get scrollbarStyle;
}
