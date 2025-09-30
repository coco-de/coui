import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for NavigationBar components.
///
/// Defines the visual styling options available for navigation bar components,
/// following DaisyUI's navbar component styling patterns.
abstract class NavigationBarStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of navigation bar styles.
class NavigationBarStyle implements NavigationBarStyling {
  /// Creates a [NavigationBarStyle].
  const NavigationBarStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}