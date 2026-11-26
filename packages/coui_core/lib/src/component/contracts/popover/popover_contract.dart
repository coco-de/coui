/// Cross-platform contract for unified popover components.
library;

import 'package:coui_core/coui_core.dart';

/// Contract for a unified popover component.
///
/// Per Epic #1302, every chrome / dimensional / animation override
/// flows through the single [popoverStyle] field — see
/// [CorePopoverStyle] for the merge chain. Behaviour fields
/// (placement / openTrigger / modal / dismiss / collision /
/// constraint / controller / onClose) stay flat on the contract
/// because they describe interaction policy.
///
/// Type parameters:
/// - [W] — Widget type (Flutter `Widget`, Web `Component`).
/// - [Cb] — Callback type
///   (Flutter `VoidCallback`, Web `CoreVoidCallback`).
/// - [Ctrl] — Controller type — must implement
///   [CorePopoverControllerContract] (Flutter:
///   `PopoverController`, Web: `PopoverController`).
abstract interface class CorePopoverContract<W, Cb, Ctrl> {
  /// The trigger element that anchors the popover.
  ///
  /// Per Epic #1302 원칙 8 (asChild pattern), to change the trigger's
  /// **variant** (e.g. outline vs primary), inject the trigger widget
  /// directly here rather than packing variant into [popoverStyle].
  W get trigger;

  /// The content displayed inside the popover panel.
  W get content;

  /// The preferred placement relative to the trigger.
  CorePopoverPlacement get placement;

  /// Optional controller for imperative open/close.
  Ctrl? get controller;

  /// How the trigger element opens the popover.
  CorePopoverTrigger get openTrigger;

  /// Whether the popover blocks interaction with the rest of the
  /// page while open (renders a backdrop).
  bool get modal;

  /// Whether clicking outside the popover panel closes it.
  bool get dismissOnOutsideTap;

  /// Whether pressing Escape while the popover is open closes it.
  bool get dismissOnEscape;

  /// Viewport-collision policy.
  Set<CorePopoverCollision>? get collision;

  /// Width sizing rule relative to the trigger anchor.
  CorePopoverConstraint? get widthConstraint;

  /// Height sizing rule relative to the trigger anchor.
  CorePopoverConstraint? get heightConstraint;

  /// Per-instance popover style covering panel chrome + dimensional
  /// + animation overrides plus nested trigger-button style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CorePopoverTheme.style
  ///   → parent component slot override
  ///       (e.g. CoreSelectStyle.popoverStyle)
  ///   → widget.popoverStyle
  /// ```
  ///
  /// Named [popoverStyle] (not `style`) so the Web base class
  /// `UiComponent.style: List<Styling>?` still works without
  /// colliding.
  CorePopoverStyle? get popoverStyle;

  /// Callback invoked when the popover is closed.
  Cb? get onClose;
}
