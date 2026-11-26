/// Trigger interaction enum for popovers.
library;

/// How a popover is opened.
enum CorePopoverTrigger {
  /// Open on click or tap of the trigger.
  click,

  /// Open when the trigger receives focus.
  focus,

  /// Open while the trigger is hovered.
  hover,

  /// Open/close is controlled imperatively;
  /// the trigger does nothing on its own.
  manual,
}
