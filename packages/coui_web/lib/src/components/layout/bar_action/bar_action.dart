import 'package:coui_core/coui_core.dart';
import 'package:jaspr/jaspr.dart';

/// One action of a bar, with the axes it may be laid out along.
///
/// Wrap the action that has to stay in the bar when the bar's actions
/// move to a column beside the content — a text button, which a column one
/// glyph wide cannot hold:
///
/// ```dart
/// BarAction(
///   axisBehavior: CoreBarActionAxisBehavior.horizontalOnly,
///   child: Button(variant: .ghost, onPressed: edit, child: Text('Edit')),
/// )
/// ```
///
/// `AppBar` and a `ToolbarGroup` standing its controls in a column read
/// the marker off their own lists. Anywhere else it draws [child] and
/// nothing more — it adds no element of its own.
class BarAction extends StatelessComponent
    implements CoreBarActionContract<Component> {
  /// Marks [child] with the axes it may be laid out along.
  const BarAction({required this.axisBehavior, required this.child, super.key});

  /// The axes [action] may be laid out along: its marker's, or
  /// [CoreBarActionContract.unmarkedAxisBehavior] for an action no marker
  /// wraps.
  static CoreBarActionAxisBehavior axisBehaviorOf(Component action) =>
      action is BarAction
      ? action.axisBehavior
      : CoreBarActionContract.unmarkedAxisBehavior;

  /// The action [action] marks, or [action] itself when it is not a
  /// marker — what a container looks at to tell a group from a control.
  static Component actionOf(Component action) =>
      action is BarAction ? action.child : action;

  @override
  final CoreBarActionAxisBehavior axisBehavior;

  @override
  final Component child;

  @override
  Component build(BuildContext context) => child;
}
