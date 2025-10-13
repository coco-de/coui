import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A label component for form elements.
///
/// Example:
/// ```dart
/// Label(
///   text: 'Email',
///   htmlFor: 'email-input',
///   required: true,
/// )
/// ```
class Label extends UiComponent {
  /// Creates a Label component.
  const Label({
    super.key,
    required this.text,
    this.htmlFor,
    this.required = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _labelValue,
  }) : super(null);

  /// Label text.
  final String text;

  /// HTML for attribute (links to input id).
  final String? htmlFor;

  /// Whether field is required.
  final bool required;

  static const _labelValue = 'label';

  @override
  Label copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? text,
    String? htmlFor,
    bool? required,
    Key? key,
  }) {
    return Label(
      key: key ?? this.key,
      text: text ?? this.text,
      htmlFor: htmlFor ?? this.htmlFor,
      required: required ?? this.required,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: 'label',
      id: id,
      attributes: {
        ...this.componentAttributes,
        if (htmlFor != null) 'for': htmlFor!,
      },
      classes: _buildClasses(),
      styles: css,
      events: this.events,
      children: [
        Component.text(this.text),
        if (required)
          span(
            classes: 'text-destructive ml-1',
            child: Component.text('*'),
          ),
      ],
    );
  }

  @override
  String get baseClass =>
      'text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}
