import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/variant_system.dart';
import 'package:coui_web/src/components/form/input/input_style.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for input value change events.
typedef InputValueCallback = void Function(String value);

/// A text input component following shadcn-ui design patterns.
///
/// Renders an HTML `<input>` element with Tailwind CSS styling.
/// Compatible with coui_flutter API.
///
/// Example:
/// ```dart
/// Input(
///   placeholder: 'Enter your email',
///   type: 'email',
///   onInput: (value) => print(value),
/// )
/// ```
class Input extends UiComponent {
  /// Creates an Input component.
  ///
  /// Parameters:
  /// - [type]: The HTML input type (e.g., 'text', 'password', 'email')
  /// - [placeholder]: Placeholder text to display
  /// - [value]: Initial value of the input field
  /// - [name]: The name of the input for form submission
  /// - [disabled]: If true, the input will be disabled
  /// - [required]: If true, the input is required
  /// - [onInput]: Callback when input value changes
  /// - [onChange]: Callback when input value changes on blur
  /// - [variant]: Input variant (default or error)
  Input({
    super.attributes,
    super.classes,
    super.css,
    this.disabled = false,
    super.id,
    super.key,
    this.max,
    this.maxLength,
    this.min,
    this.minLength,
    this.name,
    InputValueCallback? onChange,
    InputValueCallback? onInput,
    this.pattern,
    this.placeholder,
    this.required = false,
    InputVariant? variant,
    super.tag = _inputValue,
    this.title,
    this.type = _defaultInputType,
    this.value,
  }) : _variant = variant ?? InputVariant.defaultVariant,
       super(
         null,
         onChange: onChange,
         onInput: onInput,
         style: [
           InputVariantStyle(variant: variant),
         ],
       );

  /// Creates a primary input (default variant).
  Input.primary({
    super.attributes,
    super.classes,
    super.css,
    this.disabled = false,
    super.id,
    super.key,
    this.max,
    this.maxLength,
    this.min,
    this.minLength,
    this.name,
    InputValueCallback? onChange,
    InputValueCallback? onInput,
    this.pattern,
    this.placeholder,
    this.required = false,
    super.tag = _inputValue,
    this.title,
    this.type = _defaultInputType,
    this.value,
  }) : _variant = InputVariant.defaultVariant,
       super(
         null,
         onChange: onChange,
         onInput: onInput,
         style: [
           InputVariantStyle(variant: InputVariant.defaultVariant),
         ],
       );

  /// Creates an input with error styling.
  Input.error({
    super.attributes,
    super.classes,
    super.css,
    this.disabled = false,
    super.id,
    super.key,
    this.max,
    this.maxLength,
    this.min,
    this.minLength,
    this.name,
    InputValueCallback? onChange,
    InputValueCallback? onInput,
    this.pattern,
    this.placeholder,
    this.required = false,
    super.tag = _inputValue,
    this.title,
    this.type = _defaultInputType,
    this.value,
  }) : _variant = InputVariant.error,
       super(
         null,
         onChange: onChange,
         onInput: onInput,
         style: [
           InputVariantStyle(variant: InputVariant.error),
         ],
       );

  final String type;
  final String? placeholder;
  final String? value;
  final String? name;
  final bool disabled;
  final bool required;
  final String? pattern;
  final int? minLength;
  final int? maxLength;
  final num? min;
  final num? max;
  final String? title;
  final InputVariant _variant;

  static const _typeAttribute = 'type';
  static const _placeholderAttribute = 'placeholder';
  static const _valueAttribute = 'value';
  static const _nameAttribute = 'name';
  static const _disabledAttribute = 'disabled';
  static const _requiredAttribute = 'required';
  static const _patternAttribute = 'pattern';
  static const _minlengthAttribute = 'minlength';
  static const _maxlengthAttribute = 'maxlength';
  static const _minAttribute = 'min';
  static const _maxAttribute = 'max';
  static const _titleAttribute = 'title';
  static const _emptyValue = '';
  static const _inputValue = 'input';
  static const _defaultInputType = 'text';

  @override
  Input copyWith({
    bool? disabled,
    bool? required,
    InputValueCallback? onChange,
    InputValueCallback? onInput,
    InputVariant? variant,
    int? maxLength,
    int? minLength,
    Key? key,
    List<Component>? children,
    Map<String, String>? attributes,
    num? max,
    num? min,
    String? classes,
    String? id,
    String? name,
    String? pattern,
    String? placeholder,
    String? tag,
    String? title,
    String? type,
    String? value,
    Styles? css,
  }) {
    return Input(
      children: children ?? this.children,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      disabled: disabled ?? this.disabled,
      id: id ?? this.id,
      key: key ?? this.key,
      max: max ?? this.max,
      maxLength: maxLength ?? this.maxLength,
      min: min ?? this.min,
      minLength: minLength ?? this.minLength,
      name: name ?? this.name,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      pattern: pattern ?? this.pattern,
      placeholder: placeholder ?? this.placeholder,
      required: required ?? this.required,
      variant: variant ?? _variant,
      tag: tag ?? this.tag,
      title: title ?? this.title,
      type: type ?? this.type,
      value: value ?? this.value,
    );
  }

  @override
  String get baseClass => '';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    attributes.add(_typeAttribute, type);

    final currentPlaceholder = placeholder;
    if (currentPlaceholder != null) {
      attributes.add(_placeholderAttribute, currentPlaceholder);
    }

    final currentValue = value;
    if (currentValue != null) {
      attributes.add(_valueAttribute, currentValue);
    }

    final currentName = name;
    if (currentName != null) {
      attributes.add(_nameAttribute, currentName);
    }

    if (disabled) {
      attributes.add(_disabledAttribute, _emptyValue);
    }

    if (required) {
      attributes.add(_requiredAttribute, _emptyValue);
    }

    final currentPattern = pattern;
    if (currentPattern != null) {
      attributes.add(_patternAttribute, currentPattern);
    }

    final currentMinLength = minLength;
    if (currentMinLength != null) {
      attributes.add(_minlengthAttribute, currentMinLength.toString());
    }

    if (maxLength != null) {
      attributes.add(_maxlengthAttribute, maxLength.toString());
    }

    final currentMin = min;
    if (currentMin != null) {
      attributes.add(_minAttribute, currentMin.toString());
    }

    final currentMax = max;
    if (currentMax != null) {
      attributes.add(_maxAttribute, currentMax.toString());
    }

    final currentTitle = title;
    if (currentTitle != null) {
      attributes.add(_titleAttribute, currentTitle);
    }
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
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
