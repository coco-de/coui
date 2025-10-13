import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A form field wrapper with label and error message.
///
/// Example:
/// ```dart
/// FormField(
///   label: 'Email',
///   error: 'Invalid email',
///   required: true,
///   child: Input(placeholder: 'Enter email'),
/// )
/// ```
class FormField extends UiComponent {
  /// Creates a FormField component.
  ///
  /// Parameters:
  /// - [label]: Field label
  /// - [child]: Form input component
  /// - [error]: Error message
  /// - [description]: Helper text
  /// - [required]: Whether field is required
  FormField({
    super.key,
    this.label,
    Component? child,
    this.error,
    this.description,
    this.required = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null, child: child);

  /// Field label.
  final String? label;

  /// Error message.
  final String? error;

  /// Helper text.
  final String? description;

  /// Whether field is required.
  final bool required;

  static const _divValue = 'div';

  @override
  FormField copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    String? label,
    String? error,
    String? description,
    bool? required,
    Key? key,
  }) {
    return FormField(
      key: key ?? this.key,
      label: label ?? this.label,
      child: child ?? this.child,
      error: error ?? this.error,
      description: description ?? this.description,
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
    return div(
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: [
        // Label
        if (label != null)
          Component.element(
            tag: 'label',
            classes:
                'text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70',
            child: Component.fragment(
              children: [
                text(label!),
                if (required)
                  span(
                    classes: 'text-destructive ml-1',
                    child: text('*'),
                  ),
              ],
            ),
          ),
        // Input
        if (child != null) child!,
        // Description
        if (description != null && error == null)
          p(
            classes: 'text-sm text-muted-foreground',
            child: text(description!),
          ),
        // Error
        if (error != null)
          p(
            classes: 'text-sm text-destructive',
            child: text(error!),
          ),
      ],
    );
  }

  @override
  String get baseClass => 'space-y-2';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// A form container component.
class Form extends UiComponent {
  /// Creates a Form component.
  Form({
    super.key,
    required List<Component> children,
    this.onSubmit,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _formValue,
  }) : super(children);

  /// Submit callback.
  final VoidCallback? onSubmit;

  static const _formValue = 'form';

  @override
  Form copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    VoidCallback? onSubmit,
    Key? key,
  }) {
    return Form(
      key: key ?? this.key,
      children: children ?? this.children,
      onSubmit: onSubmit ?? this.onSubmit,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return form(
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: componentAttributes,
      events: _buildEvents(),
      children: children,
    );
  }

  @override
  String get baseClass => 'space-y-6';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  Map<String, List<dynamic>> _buildEvents() {
    final eventMap = <String, List<dynamic>>{};

    final currentOnSubmit = onSubmit;
    if (currentOnSubmit != null) {
      eventMap['submit'] = [
        (event) {
          // Prevent default form submission
          currentOnSubmit();
        },
      ];
    }

    return eventMap;
  }
}
