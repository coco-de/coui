import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/surface_style_builder.dart';
import 'package:coui_web/src/base/surface_style_scope.dart';
import 'package:coui_web/src/components/infra/popup/popup.dart';
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/util/web_constants.dart' show kRemDivisor;
import 'package:jaspr/dom.dart' show Styles, div;
import 'package:jaspr/jaspr.dart';

/// Shared surface for labelled groups and automatic AppBar action clusters.
/// Keeps the production material and control defaults in one composition.
class ToolbarGroupSurface extends StatelessComponent {
  /// Creates the capsule around [children].
  const ToolbarGroupSurface({
    required this.children,
    this.direction = CoreToolbarGroupContract.defaultDirection,
    this.popupStyle,
    this.attributes = const {},
    super.key,
  });

  /// The controls sharing the capsule; an empty list draws nothing.
  final List<Component> children;

  /// The axis the controls run along — the group's, or a row for the
  /// clusters a bar builds on its own.
  final CoreAxis direction;

  /// Capsule overrides, including a material stated for this group alone.
  final CorePopupStyle? popupStyle;

  /// Attributes for the capsule root — the group's accessible name.
  final Map<String, String> attributes;

  @override
  Component build(BuildContext context) =>
      SurfaceStyleBuilder(builder: _buildGroup);

  Component _buildGroup(BuildContext context) {
    if (children.isEmpty) return const Component.fragment([]);
    final glass =
        (popupStyle?.surfaceStyle ?? SurfaceStyleScope.of(context)) ==
        CoreSurfaceStyleId.liquidGlass;
    final defaults = glass
        ? CoreToolbarGroupContract.glassPopupStyle.copyWith(
            surfaceStyle: .liquidGlass,
          )
        : CoreToolbarGroupContract.defaultPopupStyle;
    final seatSize = CoreToolbarGroupContract.glassActionMinSizeFor(direction);
    final seat = '${seatSize / kRemDivisor}rem';
    Component group = Popup(
      direction: direction,
      popupStyle: defaults.merge(popupStyle),
      attributes: {'role': 'group', ...attributes},
      children: glass
          ? children
                .map(
                  (child) => div(
                    [child],
                    styles: Styles(
                      raw: {
                        'display': 'flex',
                        'align-items': 'center',
                        'justify-content': 'center',
                        'min-width': seat,
                        'min-height': seat,
                      },
                    ),
                  ),
                )
                .toList()
          : children,
    );
    if (glass) {
      final theme = Theme.of(context);
      final components = theme.coreComponentTheme ?? const CoreComponentTheme();
      group = Theme(
        data: theme.copyWith(
          coreComponentTheme: components.copyWith(
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
