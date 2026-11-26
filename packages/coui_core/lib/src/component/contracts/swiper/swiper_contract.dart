/// Cross-platform contract for unified swiper components.
library;

import 'package:coui_core/src/component/contracts/swiper/swiper_position.dart';
import 'package:coui_core/src/component/contracts/swiper/swiper_style.dart';
import 'package:coui_core/src/component/contracts/swiper/swiper_variant.dart';

/// Contract for a unified swiper — a child wrapper that reveals an
/// overlay panel from one edge in response to a swipe gesture.
///
/// Per Epic #1415 Phase 6f, every chrome / dimensional / barrier /
/// animation override flows through the single [swiperStyle] field —
/// see `CoreSwiperStyle` for the merge chain. Behaviour fields
/// (`enabled`, `open`, `showDragHandle`, `barrierDismissible`),
/// callbacks (`onOpenChanged`) and the semantic [position] /
/// [variant] enums stay flat on the contract.
///
/// Type parameters:
/// - [W] — Widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreSwiperContract<W> {
  /// The child widget that responds to swipe gestures.
  W get child;

  /// The content displayed inside the revealed overlay panel.
  W get overlayContent;

  /// The edge from which the overlay slides into the viewport.
  CoreSwiperPosition get position;

  /// The presentation style of the overlay (drawer / sheet).
  CoreSwiperVariant get variant;

  /// Whether the overlay is currently open. Acts as a controlled
  /// value — pair with [onOpenChanged] to drive open / close state.
  /// Defaults to `false`.
  bool get open;

  /// Called whenever the open state should change — fired when a
  /// swipe gesture crosses the threshold, the barrier is tapped, or
  /// the overlay is dismissed. `null` → uncontrolled (internal state).
  void Function(bool)? get onOpenChanged;

  /// Whether swipe gestures are enabled. Defaults to `true`.
  bool get enabled;

  /// Whether to show the drag-handle indicator on the overlay panel.
  /// Defaults to `true`.
  bool get showDragHandle;

  /// Whether tapping the dimmed barrier behind the overlay dismisses
  /// it. Defaults to `true`.
  bool get barrierDismissible;

  /// Per-instance swiper style covering overlay-panel chrome +
  /// dimensional + barrier + animation + drag-handle overrides.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreSwiperStyle.defaultX)
  ///   → CoreSwiperTheme.style
  ///   → CoreSwiperTheme.variantStyles[variant]
  ///   → widget.swiperStyle
  /// ```
  ///
  /// Named [swiperStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CoreSwiperStyle? get swiperStyle;
}
