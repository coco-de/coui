import 'package:coui_core/coui_core.dart';
import 'package:flutter/widgets.dart';

/// Decides whether an input's outer focus ring may show — the Flutter half of
/// [CoreInputFocusModality], held by every field that draws that ring.
///
/// The ring is a keyboard signal: a pointer press that focuses the field
/// already shows on the active boundary, so the ring joins only when focus
/// arrives by keyboard. Flutter's own signal for that, the focus highlight
/// mode, is not enough: a mouse never moves it off `traditional` on a
/// desktop, so read alone it rings on every click. The press is noted here
/// instead, on the region that grants focus ([pointerDown]), and the field
/// asks [shows].
///
/// A field wires it in four places:
///
/// * [adopt] when it takes a [FocusNode] — at init and whenever the node is
///   replaced;
/// * [focusChanged] from the node's listener;
/// * [pointerDown] from a translucent `Listener` over the region a press
///   grants focus through;
/// * [shows] for `FocusOutline.focused`, rebuilt on highlight-mode changes.
final class InputFocusRing {
  final CoreInputFocusModality _modality = CoreInputFocusModality();

  /// Whether the node held focus at the last [focusChanged], so a
  /// notification that changed nothing about focus is not read as a gain.
  bool _hadFocus = false;

  /// Whether the focus the field holds now may show the ring. Latched when
  /// focus arrives; false while the field holds none.
  bool _allowed = false;

  /// The platform's own keyboard-focus signal — `traditional` highlighting.
  static bool get highlightIsKeyboard =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  /// Marks a pointer press on the field.
  void pointerDown() => _modality.pointerDown();

  /// Starts tracking [node]. A node that already holds focus when it is
  /// adopted took it from nobody's press: it is keyboard-like.
  void adopt(FocusNode node) {
    _modality.blur();
    _hadFocus = node.hasFocus;
    _allowed = _hadFocus;
  }

  /// Decides the ring once, when [node] gains focus; forgets it when focus
  /// leaves. Call from the node's listener.
  void focusChanged(FocusNode node) {
    final hasFocus = node.hasFocus;
    if (hasFocus == _hadFocus) return;
    _hadFocus = hasFocus;
    if (hasFocus) {
      _allowed = _modality.focus(platformShowsRing: highlightIsKeyboard);
    } else {
      _modality.blur();
      _allowed = false;
    }
  }

  /// Whether the ring shows now for [node].
  bool shows(FocusNode node) =>
      node.hasFocus && _allowed && highlightIsKeyboard;
}
