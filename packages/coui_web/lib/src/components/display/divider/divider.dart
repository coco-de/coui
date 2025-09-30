import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/display/divider/divider_style.dart';
import 'package:jaspr/jaspr.dart' show Component, Key, Styles;

/// A component used to separate content vertically or horizontally.
///
/// It renders as an HTML `<div>` with `role="separator"`. The divider can
/// either be a simple line (by passing an empty list of children) or contain
/// text in the middle.
///
/// Example Usage:
/// ```dart
/// div(classes: 'flex flex-col w-full', [
///   div(classes: 'card', [text('Content A')]),
///   Divider([text('OR')], style: [Divider.primary]),
///   div(classes: 'card', [text('Content B')]),
/// ])
/// ```
class Divider extends UiComponent {
  /// Creates a Divider component.
  ///
  /// - [children]: The content to display within the divider (e.g., `[text('OR')]`).
  ///   If an empty list or null is provided, a simple line without text is rendered.
  /// - [tag]: The HTML tag for the root element, defaults to 'div'.
  /// - [style]: A list of [DividerStyling] instances to control the color,
  ///   direction, and text placement.
  /// - Other parameters are inherited from [UiComponent].
  const Divider(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    List<DividerStyling>? super.style,
    super.tag = 'div',
  });

  // --- Static Style Modifiers ---

  // Colors
  /// Neutral color. `divider-neutral`.
  static const neutral = DividerStyle('divider-neutral', type: StyleType.style);

  /// Primary color. `divider-primary`.
  static const primary = DividerStyle('divider-primary', type: StyleType.style);

  /// Secondary color. `divider-secondary`.
  static const secondary = DividerStyle(
    'divider-secondary',
    type: StyleType.style,
  );

  /// Accent color. `divider-accent`.
  static const accent = DividerStyle('divider-accent', type: StyleType.style);

  /// Success color. `divider-success`.
  static const success = DividerStyle('divider-success', type: StyleType.style);

  /// Warning color. `divider-warning`.
  static const warning = DividerStyle('divider-warning', type: StyleType.style);

  /// Info color. `divider-info`.
  static const info = DividerStyle('divider-info', type: StyleType.style);

  /// Error color. `divider-error`.
  static const error = DividerStyle('divider-error', type: StyleType.style);

  // Direction
  /// Renders the divider horizontally, to separate side-by-side content.
  /// The default is vertical. `divider-horizontal`.
  static const horizontal = DividerStyle(
    'divider-horizontal',
    type: StyleType.layout,
  );

  // Placement
  /// Pushes the divider text to the start (left for horizontal, top for vertical). `divider-start`.
  static const start = DividerStyle('divider-start', type: StyleType.layout);

  /// Pushes the divider text to the end (right for horizontal, bottom for vertical). `divider-end`.
  static const end = DividerStyle(
    'divider-end',
    type: StyleType.layout,
  ); // HTML attribute constants
  static const _roleAttribute = 'role';

  static const _separatorRole = 'separator';

  @override
  String get baseClass => 'divider';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    // A divider is a separator, which is an important semantic role for accessibility.
    if (!userProvidedAttributes.containsKey(_roleAttribute)) {
      attributes.addRole(_separatorRole);
    }
  }

  @override
  Divider copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<DividerStyling>? style,
    String? tag,
  }) {
    return Divider(
      children,
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      style:
          style ??
          () {
            final currentStyle = this.style;

            return currentStyle is List<DividerStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
      child: child ?? this.child,
    );
  }
}
