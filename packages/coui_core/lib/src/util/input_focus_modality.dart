/// Decides whether an input's outer focus ring may show for a focus event.
///
/// The ring is a keyboard signal: a pointer press that focuses the field
/// already shows on the active boundary, so the ring joins only when focus
/// arrives by keyboard. That judgment has two halves —
///
/// * "did a pointer press cause this focus" — the same on every platform,
///   kept here so the two platforms cannot disagree about it;
/// * "does the platform consider this focus keyboard-like" — each platform
///   reads its own signal (Web `:focus-visible`, Flutter
///   `FocusManager.highlightMode`) and passes it to [focus].
///
/// The platform half alone is not enough. A browser matches `:focus-visible`
/// on a text input however focus arrived, and Flutter's highlight mode never
/// leaves `traditional` on a desktop when the pointer is a mouse — both
/// report "keyboard" for a mouse click.
///
/// A press on an already focused input has no subsequent focus event, so
/// [blur] must discard that press before a future keyboard focus reaches
/// the input.
final class CoreInputFocusModality {
  bool _pointerFocusing = false;

  /// Marks a pointer press on the input.
  void pointerDown() => _pointerFocusing = true;

  /// Clears a press that did not lead to a new focus event.
  void blur() => _pointerFocusing = false;

  /// Consumes the pending press and reports whether the focus ring is shown.
  ///
  /// [platformShowsRing] is the platform's own keyboard-focus signal; the
  /// ring shows only when it holds and no pointer press caused this focus.
  bool focus({required bool platformShowsRing}) {
    final showRing = !_pointerFocusing && platformShowsRing;
    _pointerFocusing = false;
    return showRing;
  }
}
