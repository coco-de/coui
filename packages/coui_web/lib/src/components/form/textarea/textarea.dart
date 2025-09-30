import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/form/textarea/textarea_style.dart';
import 'package:jaspr/jaspr.dart' show Key, Styles, text;

/// A component for multi-line text input, rendering an HTML `<textarea>` element.
///
/// It supports various styles, sizes, and colors through its `style` property,
/// and common textarea attributes can be passed directly to the constructor.
/// Compatible with coui_flutter API.
class Textarea extends UiComponent {
  /// Creates a Textarea component.
  ///
  /// - [value]: The text content to display within the textarea.
  /// - [placeholder]: The placeholder text to display when the textarea is empty.
  /// - [name]: The name of the textarea, used for form submission.
  /// - [disabled]: If true, the textarea will be disabled.
  /// - [rows]: The visible number of lines in a text area.
  /// - [onChanged]: Callback when textarea value changes (Flutter-compatible API).
  /// - [style]: A list of [TextareaStyling] instances for styling.
  /// - Other parameters are inherited from [UiComponent].
  Textarea({
    super.attributes,
    super.classes,
    super.css,
    this.disabled = false,
    super.id,
    super.key,
    this.name,
    void Function(String)? onChanged,
    this.placeholder,
    this.rows,
    List<TextareaStyling>? style,
    super.tag = 'textarea',
    String? value,
  }) : _value = value,
       super(
         value == null ? null : [text(value)],
         // Convert Flutter-style onChanged to web event handlers
         onChange: onChanged,
         onInput: onChanged,
         style: style,
       );

  /// The placeholder text displayed when the textarea is empty.
  final String? placeholder;

  /// The name of the textarea, used in form submissions.
  final String? name;

  /// If true, the textarea is not interactive.
  final bool disabled;

  /// The number of visible text lines for the control.
  final int? rows;

  // --- Static Style Modifiers ---

  /// Adds a border to the textarea. `textarea-bordered`.
  static const bordered = TextareaStyle(
    'textarea-bordered',
    type: StyleType.border,
  );

  /// Ghost style (transparent background). `textarea-ghost`.
  static const ghost = TextareaStyle(
    'textarea-ghost',
    type: StyleType.style,
  );

  // Colors
  /// Neutral color. `textarea-neutral`.
  static const neutral = TextareaStyle(
    'textarea-neutral',
    type: StyleType.style,
  );

  /// Primary color. `textarea-primary`.
  static const primary = TextareaStyle(
    'textarea-primary',
    type: StyleType.style,
  );

  /// Secondary color. `textarea-secondary`.
  static const secondary = TextareaStyle(
    'textarea-secondary',
    type: StyleType.style,
  );

  /// Accent color. `textarea-accent`.
  static const accent = TextareaStyle(
    'textarea-accent',
    type: StyleType.style,
  );

  /// Info color. `textarea-info`.
  static const info = TextareaStyle('textarea-info', type: StyleType.style);

  /// Success color. `textarea-success`.
  static const success = TextareaStyle(
    'textarea-success',
    type: StyleType.style,
  );

  /// Warning color. `textarea-warning`.
  static const warning = TextareaStyle(
    'textarea-warning',
    type: StyleType.style,
  );

  /// Error color. `textarea-error`.
  static const error = TextareaStyle(
    'textarea-error',
    type: StyleType.style,
  );

  // Sizes
  /// Extra-small size. `textarea-xs`.
  static const xs = TextareaStyle('textarea-xs', type: StyleType.sizing);

  /// Small size. `textarea-sm`.
  static const sm = TextareaStyle('textarea-sm', type: StyleType.sizing);

  /// Medium size (default). `textarea-md`.
  static const md = TextareaStyle('textarea-md', type: StyleType.sizing);

  /// Large size. `textarea-lg`.
  static const lg = TextareaStyle('textarea-lg', type: StyleType.sizing);

  /// Extra-large size. `textarea-xl`.
  static const xl = TextareaStyle(
    'textarea-xl',
    type: StyleType.sizing,
  ); // HTML attribute constants
  static const _placeholderAttribute = 'placeholder';
  static const _nameAttribute = 'name';
  static const _disabledAttribute = 'disabled';
  static const _rowsAttribute = 'rows';

  static const _emptyValue = '';

  /// The text content of the textarea.
  final String? _value;

  @override
  String get baseClass => 'textarea';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    final placeholderValue = placeholder;
    if (placeholderValue != null) {
      attributes.add(_placeholderAttribute, placeholderValue);
    }

    final nameValue = name;
    if (nameValue != null) {
      attributes.add(_nameAttribute, nameValue);
    }

    if (disabled) {
      attributes.add(_disabledAttribute, _emptyValue);
    }

    final rowsValue = rows;
    if (rowsValue != null) {
      attributes.add(_rowsAttribute, rowsValue.toString());
    }
  }

  @override
  Textarea copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    bool? disabled,
    String? id,
    Key? key,
    String? name,
    void Function(String)? onChanged,
    String? placeholder,
    int? rows,
    List<TextareaStyling>? style,
    String? tag,
    String? value,
  }) {
    return Textarea(
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      disabled: disabled ?? this.disabled,
      id: id ?? this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      onChanged: onChanged,
      placeholder: placeholder ?? this.placeholder,
      rows: rows ?? this.rows,
      style:
          style ??
          () {
            final currentStyle = this.style;

            return currentStyle is List<TextareaStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
      value: value ?? _value,
    );
  }
}
