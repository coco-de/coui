import 'package:coui_web/src/base/style_type.dart';

/// Style configuration for ContextMenu components.
///
/// Defines the visual styling options available for context menu components,
/// following DaisyUI's menu styling patterns with absolute positioning.
abstract class ContextMenuStyling {
  /// The CSS class name for this style.
  String get cssClass;

  /// The type of style this represents.
  StyleType get type;
}

/// Concrete implementation of context menu styles.
class ContextMenuStyle implements ContextMenuStyling {
  /// Creates a [ContextMenuStyle].
  const ContextMenuStyle(this.cssClass, {required this.type});

  @override
  final String cssClass;

  @override
  final StyleType type;
}