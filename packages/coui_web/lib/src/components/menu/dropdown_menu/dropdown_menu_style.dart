import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for DropdownMenu components.
///
/// Defines the visual styling options available for dropdown menu components,
/// following DaisyUI's dropdown styling patterns.
abstract class DropdownMenuStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of dropdown menu styles.
class DropdownMenuStyle implements DropdownMenuStyling {
  /// Creates a [DropdownMenuStyle].
  const DropdownMenuStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}