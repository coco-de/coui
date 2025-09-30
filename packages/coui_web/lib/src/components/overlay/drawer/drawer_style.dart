import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for Drawer components.
///
/// Defines the visual styling options available for drawer components,
/// following DaisyUI's drawer styling patterns.
abstract class DrawerStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of drawer styles.
class DrawerStyle implements DrawerStyling {
  /// Creates a [DrawerStyle].
  const DrawerStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}