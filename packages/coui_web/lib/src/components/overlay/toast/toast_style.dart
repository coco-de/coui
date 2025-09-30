import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for Toast components.
///
/// Defines the visual styling options available for toast components,
/// following DaisyUI's toast styling patterns.
abstract class ToastStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of toast styles.
class ToastStyle implements ToastStyling {
  /// Creates a [ToastStyle].
  const ToastStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}