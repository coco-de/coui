import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for DatePicker components.
///
/// Defines the visual styling options available for date picker components,
/// following DaisyUI's modal and button styling patterns.
abstract class DatePickerStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of date picker styles.
class DatePickerStyle implements DatePickerStyling {
  /// Creates a [DatePickerStyle].
  const DatePickerStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}