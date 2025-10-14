import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:jaspr/jaspr.dart' show Component, Key, Styles;

/// Represents an HTML `<figure>` element, typically used to encapsulate media
/// like images, diagrams, or code snippets, optionally with a caption.
///
/// Styling is achieved by passing general utility classes (instances of styling classes)
/// via the `modifiers` property.
class Figure extends UiComponent {
  /// Creates a Figure component.
  ///
  /// - [children] or [child]: The content of the figure, usually an `img` tag and
  ///   optionally a `Figcaption` (not yet defined in this snippet).
  /// - [tag]: The HTML tag to use, defaults to 'figure'.
  /// - [style]: A list of general styling instances for styling.
  /// - Other parameters are inherited from [UiComponent].
  const Figure(
    super.children, {
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    super.style,
    super.tag = 'figure',
  });

  static const _emptyBaseClass = '';

  @override
  String get baseClass => _emptyBaseClass;

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
  }

  @override
  Figure copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    List<Styling>? style,
    String? tag,
  }) {
    return Figure(
      children,
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      style: style ?? this.style,
      tag: tag ?? this.tag,
    );
  }

  // Previously, Figure had static padding modifiers like `Figure.px`.
  // These have been removed in favor of using general Spacing utilities, e.g.:
  // Figure([img(src:"")], modifiers: [Spacing.px(10), Spacing.pt(10)])
}
