import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for Accordion components.
///
/// Defines the visual styling options available for accordion components,
/// following DaisyUI's collapse component styling patterns.
abstract class AccordionStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of accordion styles.
class AccordionStyle implements AccordionStyling {
  /// Creates an [AccordionStyle].
  const AccordionStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}