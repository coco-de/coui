/// How a `Popover` trigger wrapper sizes itself within the parent
/// layout. Mirrors the design of `CoreCardSizing` (intrinsic / expand
/// / fixed) — a render-shape decision the caller makes per-instance,
/// not a runtime-derived behaviour.
enum CorePopoverTriggerSizing {
  /// The wrapper sizes to the trigger's intrinsic content
  /// (`inline-flex` on Web, natural Flutter sizing). Right for
  /// inline triggers (color swatch, icon button) where the popover
  /// anchors a small element.
  intrinsic,

  /// The wrapper expands to fill the parent's inline-axis (width).
  /// Right for form-style triggers (DatePicker, Select) that act as
  /// full-width input fields. The trigger child is expected to use
  /// `w-full` (Web) or `Column(crossAxisAlignment: stretch)` /
  /// `SizedBox.expand` (Flutter) to match.
  expand,
}
