import 'package:jaspr/jaspr.dart';

/// Ambient state a `ContextMenu` installs around its `Menu` while it lets the
/// finger that opened the menu glide to a row.
///
/// The host measures the rows at every pointer event and learns which one is
/// under the finger; the highlight has to reach that row as markup, because a
/// class or attribute written onto the element from outside is overwritten by
/// the next render. So the host keeps the row's id here and the `Menu` — every
/// one of them, an inline submenu included — marks the row whose roving id it
/// is (`data-coui-glide`), and its `MenuItem` paints the same wash the pointer
/// pressing it would.
///
/// A `Menu` outside any scope marks nothing and its rows carry no rule for the
/// mark, so a menu that is not gliding is laid out exactly as it always was.
class MenuGlideScope extends InheritedComponent {
  /// Creates a [MenuGlideScope] lighting the row [highlightedRow] for [child].
  const MenuGlideScope({
    required this.highlightedRow,
    required super.child,
    super.key,
  });

  /// The roving id (`data-roving-item`) of the row under the finger, or `null`
  /// when none is lit.
  final String? highlightedRow;

  /// The attribute a lit row carries. The wash rule keys on it.
  static const String attribute = 'data-coui-glide';

  /// The nearest scope above [context], or `null` when the menu is not
  /// gliding. Registers the dependency, so the row repaints when the lit row
  /// changes.
  static MenuGlideScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedComponentOfExactType<MenuGlideScope>();
  }

  @override
  bool updateShouldNotify(MenuGlideScope oldComponent) {
    return highlightedRow != oldComponent.highlightedRow;
  }
}
