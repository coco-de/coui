import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for Breadcrumb components.
///
/// Defines the visual styling options available for breadcrumb components,
/// following DaisyUI's breadcrumb styling patterns.
abstract class BreadcrumbStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}
