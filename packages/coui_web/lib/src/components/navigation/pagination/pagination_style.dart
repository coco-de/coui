import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for Pagination components.
///
/// Defines the visual styling options available for pagination components,
/// following DaisyUI's pagination styling patterns using the join component.
abstract class PaginationStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of pagination styles.
class PaginationStyle implements PaginationStyling {
  /// Creates a [PaginationStyle].
  const PaginationStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}