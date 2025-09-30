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
