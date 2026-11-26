/// SSR stub for [OverlayPositioner].
///
/// On non-web Dart targets (e.g. server-side Jaspr rendering) there is no
/// DOM to manipulate, so all methods are no-ops and the controller never
/// registers with [OverlayPositionRegistry]. This lets consumer components
/// instantiate a controller unconditionally without `kIsWeb` branches.
library;

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/overlay/positioning/rect.dart';

/// Stub implementation of [OverlayPositioner] used during SSR.
class OverlayPositioner {
  /// Creates a [OverlayPositioner].
  ///
  /// Takes the DOM ids of the trigger / popover so the signature matches
  /// the web implementation; the stub ignores them (no DOM during SSR).
  const OverlayPositioner({
    required String triggerId,
    required String popoverId,
    this.placement = CorePopoverStyle.defaultDropdownPlacement,
    this.gap = CorePopoverStyle.defaultFormPopoverPlacementOffset,
    this.viewportPadding = CorePopoverStyle.defaultViewportPadding,
    this.collision = CorePopoverStyle.defaultCollision,
    this.closeOnOutsideClick = true,
    this.closeOnEsc = true,
    this.closeOnScroll = CorePopoverStyle.defaultCloseOnScroll,
    this.triggerAncestorScrollOnly = false,
    this.onScrollClose,
    this.fitViewportHeight = false,
    this.measureAnchor,
    this.measureTopInset,
    this.onPosition,
    this.onFit,
    this.onAnchorMeasured,
    this.onPanelMeasured,
    this.onClose,
  });

  /// Preferred placement of the popover relative to its trigger.
  final CorePopoverPlacement placement;

  /// Gap between the trigger and the popover along the primary axis.
  final double gap;

  /// Minimum distance between the popover and each viewport edge when
  /// [CorePopoverCollision.shift] is applied. Per-side values so the
  /// host can reserve space for fixed headers / banners / safe-area
  /// insets.
  final CoreEdgeInsets viewportPadding;

  /// Collision policy applied when the popover overflows the viewport.
  final Set<CorePopoverCollision> collision;

  /// Whether clicking outside the popover dismisses it.
  final bool closeOnOutsideClick;

  /// Whether the `Escape` key dismisses the popover.
  final bool closeOnEsc;

  /// Whether scrolling the trigger's ancestors dismisses the popover.
  final bool closeOnScroll;

  /// Restrict scroll events to the trigger's ancestors and viewport.
  final bool triggerAncestorScrollOnly;

  /// Handles a scroll dismissal instead of the positioner's default close.
  final void Function()? onScrollClose;

  /// Whether the panel is held to the room the viewport leaves it. Never
  /// acted on in the stub (no DOM to measure during SSR).
  final bool fitViewportHeight;

  /// Measures the anchor box in place of the trigger element's own. Never
  /// invoked in the stub (no DOM to measure during SSR).
  final OverlayRect? Function()? measureAnchor;

  /// Measures where the room for the panel begins at the top of the
  /// viewport. Never invoked in the stub (no DOM to measure during SSR).
  final double Function()? measureTopInset;

  /// Called with the flip/shift-resolved `(left, top)` origin + resolved
  /// placement. Never invoked in the stub (no DOM to measure during SSR).
  final void Function(double left, double top, CorePopoverPlacement placement)?
  onPosition;

  /// Called with the height the panel is capped to, or `null` when it is
  /// not. Never invoked in the stub (no DOM to measure during SSR).
  final void Function(double? maxHeight)? onFit;

  /// Optional callback fired with the trigger's measured rect. Never
  /// invoked in the stub (no DOM to measure during SSR).
  final void Function(OverlayRect anchor)? onAnchorMeasured;

  /// Optional callback fired with the panel's own measured viewport rect.
  ///
  /// The symmetric half of [onAnchorMeasured]. `update` already measures
  /// this to resolve collisions and threw it away; a consumer that needs
  /// the panel's box — to carve a shape in the panel's own coordinates,
  /// say — would otherwise measure the same element a second time and get
  /// a second answer.
  final void Function(OverlayRect panel)? onPanelMeasured;

  /// Optional callback fired when the popover closes.
  final void Function()? onClose;

  /// Whether the popover is currently open. Always `false` in the stub.
  bool get isOpen => false;

  /// No-op on non-web platforms.
  void open() {}

  /// No-op on non-web platforms.
  void close() {}

  /// No-op on non-web platforms.
  void update() {}

  /// No-op on non-web platforms.
  void dispose() {}
}
