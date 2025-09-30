import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/overlay/tooltip/tooltip_style.dart';
import 'package:jaspr/jaspr.dart';

/// A tooltip component for displaying helpful hints on hover.
///
/// The Tooltip component shows a text hint when the user hovers over
/// the wrapped element. It follows DaisyUI's tooltip patterns and provides
/// Flutter-compatible API.
///
/// Features:
/// - Multiple positioning options (top, bottom, left, right)
/// - Color variants (primary, secondary, accent, info, success, warning, error)
/// - Always-open mode for static display
/// - Accessibility with ARIA attributes
/// - Pure CSS implementation (no JavaScript)
///
/// Example:
/// ```dart
/// Tooltip(
///   message: 'Click to save',
///   position: TooltipPosition.top,
///   child: Button.primary([text('Save')]),
///   style: [Tooltip.primary],
/// )
/// ```
class Tooltip extends UiComponent {
  /// Creates a Tooltip component.
  ///
  /// - [message]: Tooltip text to display.
  /// - [child]: The element that triggers the tooltip on hover.
  /// - [position]: Position of tooltip relative to child (top, bottom, left, right).
  /// - [open]: Whether tooltip is always visible (for testing/demos).
  /// - [style]: List of [TooltipStyling] instances for styling.
  const Tooltip({
    super.attributes,
    required this.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    required this.message,
    this.open = false,
    this.position = TooltipPosition.top,
    List<TooltipStyling>? style,
    super.tag = 'div',
  }) : super(null, style: style);

  /// Tooltip text message.
  final String message;

  /// Element that triggers the tooltip.
  @override
  final Component child;

  /// Position of the tooltip relative to the child.
  final TooltipPosition position;

  /// Whether the tooltip is always visible.
  final bool open;

  // --- Static Style Modifiers ---

  /// Primary color. `tooltip-primary`.
  static const primary = TooltipStyle('tooltip-primary', type: StyleType.style);

  /// Secondary color. `tooltip-secondary`.
  static const secondary =
      TooltipStyle('tooltip-secondary', type: StyleType.style);

  /// Accent color. `tooltip-accent`.
  static const accent = TooltipStyle('tooltip-accent', type: StyleType.style);

  /// Info color. `tooltip-info`.
  static const info = TooltipStyle('tooltip-info', type: StyleType.style);

  /// Success color. `tooltip-success`.
  static const success = TooltipStyle('tooltip-success', type: StyleType.style);

  /// Warning color. `tooltip-warning`.
  static const warning = TooltipStyle('tooltip-warning', type: StyleType.style);

  /// Error color. `tooltip-error`.
  static const error = TooltipStyle('tooltip-error', type: StyleType.style);

  /// Always open state. `tooltip-open`.
  static const openState = TooltipStyle('tooltip-open', type: StyleType.state);

  // HTML/ARIA attribute constants
  static const _dataTipAttribute = 'data-tip';

  @override
  String get baseClass => 'tooltip';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    // Set data-tip attribute with tooltip message
    attributes.add(_dataTipAttribute, message);
  }

  @override
  Component build(BuildContext context) {
    final styles = _buildStyleClasses();

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
      css: css,
      id: id,
      tag: tag,
      children: [child],
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    // Add position class
    stylesList.add(_getPositionClass());

    // Add custom styles
    if (style != null) {
      for (final s in style!) {
        if (s is TooltipStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }

    // Add open state if always visible
    if (open) {
      stylesList.add(openState.cssClass);
    }

    return stylesList;
  }

  String _getPositionClass() {
    switch (position) {
      case TooltipPosition.top:
        return 'tooltip-top';
      case TooltipPosition.bottom:
        return 'tooltip-bottom';
      case TooltipPosition.left:
        return 'tooltip-left';
      case TooltipPosition.right:
        return 'tooltip-right';
    }
  }

  @override
  Tooltip copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? message,
    bool? open,
    TooltipPosition? position,
    List<TooltipStyling>? style,
    String? tag,
  }) {
    return Tooltip(
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      message: message ?? this.message,
      open: open ?? this.open,
      position: position ?? this.position,
      style: style ??
          () {
            final currentStyle = this.style;
            return currentStyle is List<TooltipStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
    );
  }
}

/// Position of the tooltip relative to its child element.
enum TooltipPosition {
  /// Tooltip appears above the element.
  top,

  /// Tooltip appears below the element.
  bottom,

  /// Tooltip appears to the left of the element.
  left,

  /// Tooltip appears to the right of the element.
  right,
}