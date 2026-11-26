import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/toolbar_group/toolbar_group_internal.dart';

/// Related toolbar controls sharing one capsule-shaped material surface.
///
/// Use ghost buttons with accessible labels. Separate unrelated actions into
/// sibling groups, and omit hidden controls from [children] so no empty seats
/// remain. AppBar preserves explicit groups and supplies a clear glass
/// layout host.
///
/// [direction] stands the controls in a column instead — for a side strip
/// or a tool palette beside the content, not for a bar's row. A column
/// leaves out a [BarAction] marked `horizontalOnly` and takes the controls
/// of a group among its children as its own, so a bar's `leading` and
/// `trailing` lists can be handed to it as they are.
///
/// surface:functional — a toolbar group floats above the content it controls.
class ToolbarGroup extends StatelessWidget
    implements CoreToolbarGroupContract<Widget> {
  /// Creates a labelled group. An empty [children] list hides the whole group.
  const ToolbarGroup({
    required this.ariaLabel,
    required this.children,
    this.direction = CoreToolbarGroupContract.defaultDirection,
    this.popupStyle,
    super.key,
  }) : assert(ariaLabel != '', 'A toolbar group needs a name.');

  @override
  final List<Widget> children;

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
  List<Widget> get _controls => switch (direction) {
    .horizontal => children,
    .vertical => _columnControls(children).toList(),
  };

  static Iterable<Widget> _columnControls(List<Widget> children) sync* {
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
  Widget build(BuildContext context) {
    final controls = _controls;
    if (controls.isEmpty) return const SizedBox.shrink();
    return CoUISemantics(
      role: .group,
      label: ariaLabel,
      container: true,
      child: ToolbarGroupSurface(
        direction: direction,
        popupStyle: popupStyle,
        children: controls,
      ),
    );
  }
}
