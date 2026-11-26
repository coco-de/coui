import 'package:coui_flutter/coui_flutter.dart';

/// Shared surface for explicit toolbar groups and AppBar action clusters.
/// Intentionally internal: public labelled groups use [ToolbarGroup].
class ToolbarGroupSurface extends StatelessWidget {
  /// Creates the capsule around [children].
  const ToolbarGroupSurface({
    required this.children,
    this.direction = CoreToolbarGroupContract.defaultDirection,
    this.popupStyle,
    super.key,
  });

  /// The controls sharing the capsule; an empty list draws nothing.
  final List<Widget> children;

  /// The axis the controls run along — the group's, or a row for the
  /// clusters a bar builds on its own.
  final CoreAxis direction;

  /// Capsule overrides, including a material stated for this group alone.
  final CorePopupStyle? popupStyle;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final theme = resolveSurfaceTheme(context, popupStyle?.surfaceStyle);
    final glass = popupStyle?.surfaceStyle != null
        ? popupStyle!.surfaceStyle == CoreSurfaceStyleId.liquidGlass
        : theme.functionalSurface?.type == SurfaceType.glass;
    final defaults = glass
        ? CoreToolbarGroupContract.glassPopupStyle
        : CoreToolbarGroupContract.defaultPopupStyle;
    final seat =
        CoreToolbarGroupContract.glassActionMinSizeFor(direction) *
        theme.scaling;
    Widget group = Popup(
      direction: direction,
      popupStyle: defaults.merge(popupStyle),
      children: glass
          ? children
                .map(
                  (child) => ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: seat,
                      minHeight: seat,
                    ),
                    child: Center(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: child,
                    ),
                  ),
                )
                .toList()
          : children,
    );
    if (glass) {
      final components = theme.coreComponentTheme ?? const CoreComponentTheme();
      group = Theme(
        data: theme.copyWith(
          coreComponentTheme: () => components.copyWith(
            button: CoreToolbarGroupContract.glassButtonTheme(
              components.button,
              direction: direction,
            ),
          ),
        ),
        child: group,
      );
    }
    return group;
  }
}
