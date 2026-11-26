import 'package:coui_flutter/coui_flutter.dart';

/// Tells the [Popup]s below it whether to scroll their content when the
/// height they are given is less than the content needs.
///
/// A [Popup] has no opinion of its own: its content is whatever its caller
/// stacked in it, and a content that is not built to scroll (a calendar, a
/// form) must be handed its natural height rather than a scroll view.
/// A list that *is* built for it — [Menu], whose entries are rows of the
/// same kind — states so here. Without it, a menu in a panel the viewport
/// cannot fit overflows its constraint and the rows past the edge are
/// unreachable.
///
/// The answer is for the nearest [Popup] only in practice: a [Menu] that
/// nests another inside its own panel (an inline submenu) states `false` for
/// it, so the rows scroll once, in the outer panel.
class PopupScrollScope extends InheritedWidget {
  /// Creates a [PopupScrollScope].
  const PopupScrollScope({
    required this.scrolls,
    required super.child,
    super.key,
  });

  /// Whether a [Popup] below scrolls its content when it has to.
  final bool scrolls;

  /// Whether the [Popup] built under [context] scrolls its content — `false`
  /// when no scope says otherwise.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PopupScrollScope>()?.scrolls ??
      false;

  @override
  bool updateShouldNotify(PopupScrollScope oldWidget) =>
      scrolls != oldWidget.scrolls;
}
