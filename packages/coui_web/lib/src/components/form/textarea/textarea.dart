import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/form/textarea/textarea_style.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for textarea value change.
typedef TextareaCallback = void Function(String value);

/// A textarea component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// Textarea(
///   placeholder: 'Type your message here.',
///   rows: 4,
/// )
/// ```
class Textarea extends UiComponent {
  /// Creates a Textarea component.
  ///
  /// Parameters:
  /// - [placeholder]: Placeholder text
  /// - [value]: Initial value
  /// - [disabled]: Whether the textarea is disabled
  /// - [rows]: Number of visible text lines
  /// - [cols]: Number of visible text columns
  /// - [onInput]: Callback when textarea value changes
  Textarea({
    super.key,
    this.placeholder,
    this.value,
    this.disabled = false,
    this.rows,
    this.cols,
    this.onInput,
    this.onChange,
    this.name,
    this.maxLength,
    this.required = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _textareaValue,
  }) : super(
         null,
         onInput: onInput,
         onChange: onChange,
         style: [
           TextareaVariantStyle(),
         ],
       );

  /// Placeholder text.
  final String? placeholder;

  /// Initial value.
  final String? value;

  /// Whether the textarea is disabled.
  final bool disabled;

  /// Number of visible text lines.
  final int? rows;

  /// Number of visible text columns.
  final int? cols;

  /// Callback when textarea value changes.
  final TextareaCallback? onInput;

  /// Callback when textarea value changes on blur.
  final TextareaCallback? onChange;

  /// The name attribute.
  final String? name;

  /// Maximum length of input.
  final int? maxLength;

  /// Whether the textarea is required.
  final bool required;

  static const _textareaValue = 'textarea';
  static const _placeholderAttribute = 'placeholder';
  static const _disabledAttribute = 'disabled';
  static const _rowsAttribute = 'rows';
  static const _colsAttribute = 'cols';
  static const _nameAttribute = 'name';
  static const _maxlengthAttribute = 'maxlength';
  static const _requiredAttribute = 'required';
  static const _emptyValue = '';

  @override
  Textarea copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? value,
    String? placeholder,
    bool? disabled,
    bool? required,
    int? rows,
    int? cols,
    TextareaCallback? onInput,
    TextareaCallback? onChange,
    String? name,
    int? maxLength,
    Key? key,
  }) {
    return Textarea(
      key: key ?? this.key,
      placeholder: placeholder ?? this.placeholder,
      value: value ?? this.value,
      disabled: disabled ?? this.disabled,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      onInput: onInput ?? this.onInput,
      onChange: onChange ?? this.onChange,
      name: name ?? this.name,
      maxLength: maxLength ?? this.maxLength,
      required: required ?? this.required,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  String get baseClass => '';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    final currentPlaceholder = placeholder;
    if (currentPlaceholder != null) {
      attributes.add(_placeholderAttribute, currentPlaceholder);
    }

    if (disabled) {
      attributes.add(_disabledAttribute, _emptyValue);
    }

    if (required) {
      attributes.add(_requiredAttribute, _emptyValue);
    }

    final currentRows = rows;
    if (currentRows != null) {
      attributes.add(_rowsAttribute, currentRows.toString());
    }

    final currentCols = cols;
    if (currentCols != null) {
      attributes.add(_colsAttribute, currentCols.toString());
    }

    final currentName = name;
    if (currentName != null) {
      attributes.add(_nameAttribute, currentName);
    }

    final currentMaxLength = maxLength;
    if (currentMaxLength != null) {
      attributes.add(_maxlengthAttribute, currentMaxLength.toString());
    }
  }

  @override
  Component build(BuildContext context) {
    final currentValue = value;

    return Component.element(
      child: currentValue == null ? null : text(currentValue),
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  String _buildClasses() {
    final classList = <String>[];

    // Add variant classes from style
    final currentStyle = style;
    if (currentStyle != null) {
      for (final s in currentStyle) {
        classList.add(s.cssClass);
      }
    }

    // Add user classes
    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
