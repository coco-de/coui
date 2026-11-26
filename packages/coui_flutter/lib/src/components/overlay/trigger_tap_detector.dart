import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Detects a primary tap on [child] WITHOUT competing in the gesture arena,
/// so the tap still fires when [child] is itself an interactive widget (e.g. a
/// `Button` trigger, which is `Clickable` and would otherwise win the
/// arena and swallow the tap).
///
/// ## Why this exists
///
/// Anchored overlays (dropdown / popover / …) accept a generic `trigger:
/// Widget` and must make *whatever* the caller passes open the overlay on tap.
/// They therefore wrap the trigger to detect taps. A wrapping
/// [GestureDetector] participates in Flutter's *exclusive* gesture arena, so
/// when the trigger is itself interactive the inner recognizer wins and the
/// wrapper's `onTap` never fires — the overlay does not open.
///
/// The Web overlays do not hit this: a wrapper `<div onClick>` fires via DOM
/// event bubbling even when an inner button is clicked (both fire). To keep
/// Web↔Flutter trigger parity, this widget observes pointer events with a
/// low-level [Listener] — which does NOT join the gesture arena — so the inner
/// widget keeps working normally AND the wrapper still sees the tap. That
/// mirrors DOM bubbling exactly (both handlers run).
class TriggerTapDetector extends StatefulWidget {
  /// Creates a [TriggerTapDetector].
  const TriggerTapDetector({
    required this.onTap,
    required this.child,
    super.key,
  });

  /// Invoked when [child] receives a primary tap (pointer down then up within
  /// [kTouchSlop]). Fires even if [child] also handles the same tap.
  final VoidCallback onTap;

  /// The trigger content — may be interactive (e.g. a `Button`) or inert
  /// (e.g. `Text` / `Icon`).
  final Widget child;

  @override
  State<TriggerTapDetector> createState() => _TriggerTapDetectorState();
}

class _TriggerTapDetectorState extends State<TriggerTapDetector> {
  Offset? _downPosition;

  void handlePointerDown(PointerDownEvent event) {
    // Only a press that includes the primary (left / touch) button opens
    // the overlay. Secondary (right-click) and middle presses on their own
    // pass through untouched — right-click is the context-menu's gesture,
    // not a trigger tap. `buttons` is a bitmask, so the test is a bit
    // test: comparing for equality dropped a primary press that arrived
    // with another button already held (a chord, or a stylus barrel
    // button), which reports `buttons == 3`.
    _downPosition = (event.buttons & kPrimaryButton) != 0
        ? event.localPosition
        : null;
  }

  void handlePointerUp(PointerUpEvent event) {
    final down = _downPosition;
    _downPosition = null;
    if (down == null) return;
    // Treat as a tap only if the pointer barely moved (a drag/scroll moves
    // past the slop and must not open the overlay). Firing on *up* — not down
    // — keeps the dismiss barrier from catching the same pointer and closing
    // immediately.
    if ((event.localPosition - down).distance <= kTouchSlop) {
      widget.onTap();
    }
  }

  void handlePointerCancel(PointerCancelEvent event) {
    _downPosition = null;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: handlePointerDown,
      onPointerUp: handlePointerUp,
      onPointerCancel: handlePointerCancel,
      child: widget.child,
    );
  }
}
