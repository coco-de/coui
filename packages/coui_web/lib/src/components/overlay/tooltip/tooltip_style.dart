import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for Tooltip components.
///
/// Defines the visual styling options available for tooltip components,
/// following DaisyUI's tooltip styling patterns.
abstract class TooltipStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of tooltip styles.
class TooltipStyle implements TooltipStyling {
  /// Creates a [TooltipStyle].
  const TooltipStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}