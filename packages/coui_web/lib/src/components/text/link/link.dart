import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/text/link/link_style.dart';
import 'package:jaspr/jaspr.dart' show Component, Key, Styles;

/// A component that styles an element to look like a hyperlink, typically adding an underline.
///
/// It renders as an `<a>` tag by default but can be changed using the `tag` property.
/// This is useful for styling buttons or other elements to look like links.
///
/// Example Usage:
/// ```dart
/// Link(
///   [text('Read more')],
///   href: '/about',
///   style: [Link.primary, Link.hover],
/// )
/// ```
class Link extends UiComponent {
  /// Creates a Link component.
  ///
  /// - [children]: The content of the link, typically text.
  /// - [href]: The URL that the hyperlink points to. Only applicable if the `tag` is 'a'.
  /// - [target]: Specifies where to open the linked document (e.g., '_blank', '_self').
  /// - [tag]: The HTML tag for the root element, defaults to 'a'.
  /// - [style]: A list of [LinkStyling] instances to control the color and hover behavior.
  /// - Other parameters are inherited from [UiComponent].
  const Link(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    this.href,
    super.id,
    super.key,
    List<LinkStyling>? style,
    super.tag = 'a',
    this.target,
  }) : super(style: style);

  /// The URL that the hyperlink points to.
  final String? href;

  /// Specifies where to open the linked document (e.g., `_blank`, `_self`).
  final String? target;

  // --- Static Style Modifiers ---

  /// Only shows the underline on hover. `link-hover`.
  static const hover = LinkStyle('link-hover', type: StyleType.style);

  // Colors
  /// Neutral color. `link-neutral`.
  static const neutral = LinkStyle('link-neutral', type: StyleType.style);

  /// Primary color. `link-primary`.
  static const primary = LinkStyle('link-primary', type: StyleType.style);

  /// Secondary color. `link-secondary`.
  static const secondary = LinkStyle(
    'link-secondary',
    type: StyleType.style,
  );

  /// Accent color. `link-accent`.
  static const accent = LinkStyle('link-accent', type: StyleType.style);

  /// Success color. `link-success`.
  static const success = LinkStyle('link-success', type: StyleType.style);

  /// Info color. `link-info`.
  static const info = LinkStyle('link-info', type: StyleType.style);

  /// Warning color. `link-warning`.
  static const warning = LinkStyle('link-warning', type: StyleType.style);

  /// Error color. `link-error`.
  static const error = LinkStyle(
    'link-error',
    type: StyleType.style,
  ); // HTML attribute constants
  static const _hrefAttribute = 'href';

  static const _targetAttribute = 'target';

  @override
  String get baseClass => 'link';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    final hrefValue = href;
    if (hrefValue != null) {
      attributes.add(_hrefAttribute, hrefValue);
    }
    final targetValue = target;
    if (targetValue != null) {
      attributes.add(_targetAttribute, targetValue);
    }
  }

  @override
  Link copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? href,
    String? id,
    Key? key,
    List<LinkStyling>? style,
    String? tag,
    String? target,
  }) {
    return Link(
      children,
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      href: href ?? this.href,
      id: id ?? this.id,
      style:
          style ??
          () {
            final currentStyle = this.style;

            return currentStyle is List<LinkStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
      target: target ?? this.target,
      child: child ?? this.child,
    );
  }
}
