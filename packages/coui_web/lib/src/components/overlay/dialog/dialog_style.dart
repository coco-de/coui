import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for Dialog components.
///
/// Defines the visual styling options available for dialog components,
/// following DaisyUI's dialog and modal styling patterns.
abstract class DialogStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of dialog styles.
class DialogStyle implements DialogStyling {
  /// Creates a [DialogStyle].
  const DialogStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}