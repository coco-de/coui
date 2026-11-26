/// Tracks where the active pointer press started so a barrier (scrim)
/// `click` only dismisses the overlay when the press began on the
/// barrier itself.
///
/// A bare `'click'` handler on the barrier can fire for gestures that
/// merely *end* there — e.g. a text-selection / slider drag that starts
/// on the panel and releases over the scrim (browsers differ in which
/// element receives the click when the down / up targets differ). That
/// dismissed the overlay while the user only meant to select or drag
/// content. Keying dismissal on the pointerdown start target keeps
/// "press started AND ended on the barrier" as the only dismiss path —
/// the same rule standard overlay implementations (Radix et al.) use,
/// and the rule Flutter's `ModalBarrier` already applies natively
/// (only pointers that went *down* on the barrier can dismiss).
///
/// Wiring (one tracker instance per overlay `State`):
///
/// ```dart
/// // barrier element
/// events: {
///   'pointerdown': (_) => _barrierPressTracker.handleBarrierPointerDown(),
///   'click': (_) => _barrierPressTracker.handleBarrierClick(onClose),
/// }
/// // panel element (bubbles from all panel content)
/// events: {
///   'pointerdown': (_) => _barrierPressTracker.handlePanelPointerDown(),
/// }
/// ```
///
/// The panel hook is required: without it a press that starts on the
/// barrier but releases on the panel leaves the flag stale, and the
/// *next* panel-started drag released on the barrier would dismiss.
/// Re-arming the flag at every press start keeps the state fresh per
/// gesture without any DOM interop (no `event.target` inspection, so
/// no dart2js dynamic-dispatch hazard).
class BarrierPressTracker {
  /// Creates a [BarrierPressTracker].
  BarrierPressTracker();

  bool _pressStartedOnBarrier = false;

  /// Marks the active press as barrier-started (barrier `pointerdown`).
  void handleBarrierPointerDown() => _pressStartedOnBarrier = true;

  /// Marks the active press as panel-started (panel `pointerdown`,
  /// bubbling from any panel content).
  void handlePanelPointerDown() => _pressStartedOnBarrier = false;

  /// Runs [onDismiss] for a barrier `click` only when the press that
  /// produced it started on the barrier, then re-arms for the next
  /// gesture.
  void handleBarrierClick(void Function() onDismiss) {
    if (_pressStartedOnBarrier) {
      onDismiss();
    }
    _pressStartedOnBarrier = false;
  }
}
