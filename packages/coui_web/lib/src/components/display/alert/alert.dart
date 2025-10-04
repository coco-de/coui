import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/display/alert/alert_style.dart';
import 'package:jaspr/jaspr.dart' show Component, Key, Styles;

/// A component to inform users about important events, rendering a `<div>` with `role="alert"`.
///
/// The `Alert` component is a flexible container. Its children can be any combination
/// of `Icon`, `span`, `div`, or `Button` components to create the desired layout.
///
/// Example Usage:
/// ```dart
/// Alert(
///   style: [Alert.success, Alert.soft],
///   [
///     Icon('check_circle'), // Assumes coui_web Icon component
///     span([text('Your purchase has been confirmed!')]),
///     div([
///       Button([text('View Receipt')], style: [Button.sm]),
///     ])
///   ],
/// )
/// ```
class Alert extends UiComponent {
  /// Creates an Alert component.
  ///
  /// - [children]: The content of the alert, typically including an icon,
  ///   text, and optional action buttons.
  /// - [tag]: The HTML tag for the root element, defaults to 'div'.
  /// - [style]: A list of [AlertStyling] instances to control the color,
  ///   style, and layout.
  /// - Other parameters are inherited from [UiComponent].
  const Alert(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    List<AlertStyling>? style,
    super.tag = 'div',
  }) : super(style: style);

  // Colors.
  /// Info color, for neutral informative messages. `alert-info`.
  static const info = AlertStyle('alert-info', type: StyleType.style);

  /// Success color, for positive confirmation messages. `alert-success`.
  static const success = AlertStyle('alert-success', type: StyleType.style);

  /// Warning color, for potentially harmful actions. `alert-warning`.
  static const warning = AlertStyle('alert-warning', type: StyleType.style);

  /// Error color, for failed actions or errors. `alert-error`.
  static const error = AlertStyle('alert-error', type: StyleType.style);

  // HTML attribute constants
  static const _roleAttribute = 'role';
  static const _alertValue = 'alert';

  @override
  String get baseClass => _alertValue;

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    // The 'alert' role is crucial for accessibility, making screen readers
    // announce the message dynamically.
    if (!userProvidedAttributes.containsKey(_roleAttribute)) {
      attributes.addRole(_alertValue);
    }
  }

  @override
  Alert copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<AlertStyling>? style,
    String? tag,
  }) {
    final styleValue = style ?? this.style;

    return Alert(
      children,
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      style: styleValue,
      tag: tag ?? this.tag,
      child: child ?? this.child,
    );
  }
}
