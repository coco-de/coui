import 'package:coui_flutter/coui_flutter.dart';

/// A row a glide can land on — a `MenuItem` sitting under a [MenuGlideScope].
///
/// The menu's rows are ordinary widgets that know nothing of a finger that
/// opened the menu and is still down. A host that wants that finger to choose
/// a row (the context menu) mounts a [MenuGlideScope]; each row below it
/// registers here and answers four questions: where it is, whether it can be
/// activated, how it looks when the finger is on it, and what activating it
/// does. Nothing about a row changes without a scope above it.
abstract interface class MenuGlideRow {
  /// The row's box in global coordinates, or `null` before it has been laid
  /// out. Not clipped: a row scrolled out of its list keeps the place the list
  /// gives it.
  Rect? get glideBox;

  /// Whether activating the row does anything.
  bool get glideEnabled;

  /// Draws the row as the one the finger is on (or stops).
  void glideHighlight({required bool highlighted});

  /// Activates the row exactly as a tap on it would.
  void glideActivate();
}

/// The rows of one open menu that a glide can land on, and the box they are
/// seen through.
///
/// Rows are measured when the pointer moves or lifts, never cached, so a list
/// that scrolled or an animation that has not finished is read as it is. A
/// row's target is its box clipped to the panel — the panel's rounded clip is
/// what bounds what the person sees, so a finger above the panel is never over
/// a row it cannot see.
final class MenuGlideRegistry {
  /// Marks the panel whose box clips the rows.
  final GlobalKey panelKey = GlobalKey(debugLabel: 'menu glide panel');

  final List<MenuGlideRow> _rows = [];

  /// The rows the last [measure] returned targets for, in the same order: the
  /// glide speaks in indices into that list.
  List<MenuGlideRow> _measured = const [];
  MenuGlideRow? _highlighted;

  /// Adds [row]; a row registers when it is built under the scope.
  void add(MenuGlideRow row) => _rows.add(row);

  /// Removes [row]; a row that is lit does not leave the registry lit.
  void remove(MenuGlideRow row) {
    _rows.remove(row);
    if (identical(_highlighted, row)) _highlighted = null;
  }

  /// Measures every registered row now, as the glide's targets.
  List<CoreGlideTarget> measure() {
    _measured = List.of(_rows);
    final panel = _globalRect(panelKey.currentContext?.findRenderObject());

    return [
      for (final row in _measured)
        CoreGlideTarget(
          box: _clipped(row.glideBox, panel),
          enabled: row.glideEnabled,
        ),
    ];
  }

  /// Lights the row at [index] of the last [measure] and dims the one that was
  /// lit; `null` dims it.
  void highlight(int? index) {
    final next = index == null ? null : _measured[index];
    if (identical(next, _highlighted)) return;

    _highlighted?.glideHighlight(highlighted: false);
    _highlighted = next;
    next?.glideHighlight(highlighted: true);
  }

  /// Activates the row at [index] of the last [measure].
  void activate(int index) => _measured[index].glideActivate();

  /// Dims whatever is lit and forgets the last measurement.
  void clear() {
    highlight(null);
    _measured = const [];
  }

  static CoreMenuBox _clipped(Rect? row, Rect? panel) {
    const none = CoreMenuBox(left: 0, top: 0, right: 0, bottom: 0);
    if (row == null) return none;

    final box = CoreMenuBox(
      left: row.left,
      top: row.top,
      right: row.right,
      bottom: row.bottom,
    );
    if (panel == null) return box;

    return box.intersect(
          CoreMenuBox(
            left: panel.left,
            top: panel.top,
            right: panel.right,
            bottom: panel.bottom,
          ),
        ) ??
        none;
  }
}

/// A render object's box in global coordinates, or `null` when it has none
/// yet.
Rect? _globalRect(RenderObject? object) {
  if (object is! RenderBox || !object.attached || !object.hasSize) return null;

  return MatrixUtils.transformRect(
    object.getTransformTo(null),
    Offset.zero & object.size,
  );
}

/// The global box of the render object [context] builds, or `null`.
///
/// Exposed for the `MenuItem` that implements [MenuGlideRow].
Rect? menuGlideBoxOf(BuildContext context) =>
    _globalRect(context.findRenderObject());

/// Tells the [MenuItem]s below it that a host is listening for a finger.
///
/// Absent, every row is exactly what it was: nothing registers and nothing
/// can be lit from outside.
class MenuGlideScope extends InheritedWidget {
  /// Creates a [MenuGlideScope].
  const MenuGlideScope({
    required this.registry,
    required super.child,
    super.key,
  });

  /// The registry the rows below register with.
  final MenuGlideRegistry registry;

  /// The registry of the scope enclosing [context], if any.
  ///
  /// Reads without subscribing: the registry is one object for the life of the
  /// host, and a row has nothing to rebuild when it is handed the same one.
  static MenuGlideRegistry? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<MenuGlideScope>()?.registry;

  @override
  bool updateShouldNotify(MenuGlideScope oldWidget) =>
      registry != oldWidget.registry;
}
