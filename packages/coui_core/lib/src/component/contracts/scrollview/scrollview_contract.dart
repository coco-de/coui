/// Platform-independent contract for unified scroll-view interceptor
/// components.
///
/// Defines the interface that all `ScrollViewInterceptor`
/// implementations (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/scrollview/scrollview_style.dart';

/// Contract for a unified middle-mouse-button hold-scroll interceptor.
///
/// `ScrollViewInterceptor` wraps a [child] subtree and, while the
/// user holds the middle mouse button, synthesises continuous scroll
/// events whose velocity tracks the pointer's distance from the
/// press origin — the familiar desktop "autoscroll" gesture.
///
/// Flutter dispatches synthetic `PointerScrollEvent`s through the hit
/// path; Web translates the same tuning into per-frame
/// `scrollBy` calls on the nearest scrollable ancestor. Both share the
/// behavioural surface ([enabled]) and tuning slot
/// ([scrollViewInterceptorStyle]).
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreScrollViewInterceptorContract<W> {
  /// The subtree wrapped by the interceptor.
  W? get child;

  /// Whether middle-mouse hold-scroll interception is active.
  /// Defaults to `true`. When `false`, the [child] is rendered
  /// unchanged.
  bool get enabled;

  /// Per-instance auto-scroll tuning (drag speed / velocity cap).
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// CoreScrollViewInterceptorStyle.defaultX
  ///   → CoreScrollViewInterceptorTheme.style
  ///   → widget.scrollViewInterceptorStyle
  /// ```
  CoreScrollViewInterceptorStyle? get scrollViewInterceptorStyle;
}
