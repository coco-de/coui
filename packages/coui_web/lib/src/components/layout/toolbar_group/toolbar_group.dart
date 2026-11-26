import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/layout/bar_action/bar_action.dart';
import 'package:coui_web/src/components/layout/toolbar_group/toolbar_group_internal.dart';
import 'package:jaspr/jaspr.dart';

/// Related toolbar controls sharing one functional capsule surface.
/// Use labelled ghost buttons, and omit hidden controls from [children].
/// Empty groups leave no placeholder background or gap of their own.
///
/// [direction] stands the controls in a column instead — for a side strip
/// or a tool palette beside the content, not for a bar's row. A column
/// leaves out a [BarAction] marked `horizontalOnly` and takes the controls
/// of a group among its children as its own, so a bar's `leading` and
/// `trailing` lists can be handed to it as they are.
///
/// surface:functional — toolbar controls float above their content.
class ToolbarGroup extends StatelessComponent
    implements CoreToolbarGroupContract<Component> {
  /// Creates a labelled group of related controls.
  const ToolbarGroup({
    required this.ariaLabel,
    required this.children,
    this.direction = CoreToolbarGroupContract.defaultDirection,
    this.popupStyle,
    super.key,
  }) : assert(ariaLabel != '', 'A toolbar group needs a name.');

  @override
  final List<Component> children;

  @override
  final String ariaLabel;

  @override
  final CoreAxis direction;

  @override
  final CorePopupStyle? popupStyle;

  /// The controls this group draws out of [children].
  ///
  /// A row draws them as given. A column is one capsule of the controls
  /// that may stand in one: it leaves out an action marked
  /// `horizontalOnly`, and a group among its children gives it that
  /// group's controls rather than drawing a capsule inside the column.
  List<Component> get _controls => switch (direction) {
    .horizontal => children,
    .vertical => _columnControls(children).toList(),
  };

  static Iterable<Component> _columnControls(List<Component> children) sync* {
    for (final child in children) {
      if (!BarAction.axisBehaviorOf(child).allows(.vertical)) continue;
      final action = BarAction.actionOf(child);
      if (action is ToolbarGroup) {
        yield* _columnControls(action.children);
      } else {
        yield child;
      }
    }
  }

  @override
  Component build(BuildContext context) {
    final controls = _controls;
    if (controls.isEmpty) return const Component.fragment([]);
    return ToolbarGroupSurface(
      direction: direction,
      popupStyle: popupStyle,
      attributes: {'aria-label': ariaLabel},
      children: controls,
    );
  }
}
