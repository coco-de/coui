import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for Popover components.
///
/// Defines the visual styling options available for popover components,
/// following DaisyUI's dropdown styling patterns (used for popovers).
abstract class PopoverStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of popover styles.
class PopoverStyle implements PopoverStyling {
  /// Creates a [PopoverStyle].
  const PopoverStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}