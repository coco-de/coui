import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

/// Gives every catalog story the same material control.
///
/// The theme addon consumes this scope at CoUILayer, so previews use the
/// production preset resolver, including overlay hosts and accessibility.
class SurfaceMaterialAddon extends Addon<CoreSurfaceStyleId>
    with SingleFieldOnly {
  /// Creates the material selector with the ordinary CoUI surface selected.
  SurfaceMaterialAddon({super.initialValue = CoreSurfaceStyleId.defaultStyle})
    : super(name: 'Surface material');

  /// Human-readable names shared by the control and its URL values.
  static String label(CoreSurfaceStyleId style) => switch (style) {
    .defaultStyle => 'Default',
    .liquidGlass => 'Liquid Glass',
    .neoBrutalism => 'Neo Brutalism',
    .claymorphism => 'Claymorphism',
    .neumorphism => 'Neumorphism',
  };

  @override
  Field<CoreSurfaceStyleId> get field => ObjectDropdownField(
    name: 'value',
    values: CoreSurfaceStyleId.values,
    initialValue: initialValue,
    labelBuilder: label,
  );

  @override
  Widget apply(
    BuildContext context,
    Widget child,
    CoreSurfaceStyleId setting,
  ) => SurfaceStyleScope(surfaceStyle: setting, child: child);
}
