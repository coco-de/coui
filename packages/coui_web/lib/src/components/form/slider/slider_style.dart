import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for Slider components.
///
/// Defines the visual styling options available for slider components,
/// following DaisyUI's range slider styling patterns.
abstract class SliderStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of slider styles.
class SliderStyle implements SliderStyling {
  /// Creates a [SliderStyle].
  const SliderStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}