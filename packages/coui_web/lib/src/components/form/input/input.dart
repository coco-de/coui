import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/form/input/input_style.dart';
import 'package:jaspr/jaspr.dart' show Key, Styles;

/// A component for user text input, rendering an HTML `<input>` element.
///
/// It supports various styles, sizes, and colors through its `style` property,
/// and common input attributes can be passed directly to the constructor.
/// Compatible with coui_flutter API.
class Input extends UiComponent {
  /// Creates an Input component.
  ///
  /// - [type]: The HTML input type (e.g., 'text', 'password', 'email'). Defaults to 'text'.
  /// - [placeholder]: The placeholder text to display in the input.
  /// - [value]: The initial value of the input field.
  /// - [name]: The name of the input, used for form submission.
  /// - [disabled]: If true, the input will be disabled.
  /// - [onInput]: Callback when input value changes (Flutter-compatible API).
  /// - [onChange]: Callback when input value changes on blur (Flutter-compatible API).
  /// - [style]: A list of [InputStyling] instances for styling.
  /// - Other parameters are inherited from [UiComponent].
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
    void Function(String)? onChange,
    void Function(String)? onInput,
    this.pattern,
    this.placeholder,
    this.required = false,
    List<InputStyling>? style,
    super.tag = _inputValue,
    this.title,
    this.type = _defaultInputType,
    this.value,
  }) : super(
          null,
          // Convert Flutter-style callbacks to web event handlers
          onChange: onChange,
          onInput: onInput,
          style: style,
        );

  // Input elements have no children.

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

  final String? title; // --- Static Style Modifiers ---

  /// Adds a border to the input. `input-bordered`.
  static const bordered = InputStyle(
    'input-bordered',
    type: StyleType.border,
  );

  /// Ghost style (transparent background). `input-ghost`.
  static const ghost = InputStyle('input-ghost', type: StyleType.style);

  // Colors
  /// Neutral color. `input-neutral`.
  static const neutral = InputStyle('input-neutral', type: StyleType.style);

  /// Primary color. `input-primary`.
  static const primary = InputStyle('input-primary', type: StyleType.style);

  /// Secondary color. `input-secondary`.
  static const secondary = InputStyle(
    'input-secondary',
    type: StyleType.style,
  );

  /// Accent color. `input-accent`.
  static const accent = InputStyle('input-accent', type: StyleType.style);

  /// Info color. `input-info`.
  static const info = InputStyle('input-info', type: StyleType.style);

  /// Success color. `input-success`.
  static const success = InputStyle('input-success', type: StyleType.style);

  /// Warning color. `input-warning`.
  static const warning = InputStyle('input-warning', type: StyleType.style);

  /// Error color. `input-error`.
  static const error = InputStyle('input-error', type: StyleType.style);

  // Sizes
  /// Extra-small size. `input-xs`.
  static const xs = InputStyle('input-xs', type: StyleType.sizing);

  /// Small size. `input-sm`.
  static const sm = InputStyle('input-sm', type: StyleType.sizing);

  /// Medium size (default). `input-md`.
  static const md = InputStyle('input-md', type: StyleType.sizing);

  /// Large size. `input-lg`.
  static const lg = InputStyle('input-lg', type: StyleType.sizing);

  /// Extra-large size. `input-xl`.
  static const xl = InputStyle(
    'input-xl',
    type: StyleType.sizing,
  ); // HTML attribute constants
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
  static const _validatorClass = 'validator';
  static const _space = ' ';

  static const _defaultInputType = 'text';

  @override
  String get baseClass => _inputValue;

  @override
  String get combinedClasses {
    final classes = super.combinedClasses;
    final needsValidator =
        required ||
        pattern != null ||
        minLength != null ||
        maxLength != null ||
        min != null ||
        max != null;

    return needsValidator ? classes + _space + _validatorClass : classes;
  }

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.add(_typeAttribute, type);

    _configureStringAttributes(attributes);
    _configureBooleanAttributes(attributes);
    _configureNumericAttributes(attributes);
  }

  @override
  Input copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    bool? disabled,
    String? id,
    Key? key,
    num? max,
    int? maxLength,
    num? min,
    int? minLength,
    String? name,
    void Function(String)? onChange,
    void Function(String)? onInput,
    String? pattern,
    String? placeholder,
    bool? required,
    List<InputStyling>? style,
    String? tag,
    String? title,
    String? type,
    String? value,
  }) {
    return _createInputCopy(
      key: key,
      attributes: attributes,
      classes: classes,
      css: css,
      id: id,
      newDisabled: disabled,
      newMax: max,
      newMaxLength: maxLength,
      newMin: min,
      newMinLength: minLength,
      newName: name,
      newPattern: pattern,
      newPlaceholder: placeholder,
      newRequired: required,
      newTitle: title,
      newType: type,
      newValue: value,
      onChange: onChange,
      onInput: onInput,
      style: style,
      tag: tag,
    );
  }

  Input _createInputCopy({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    bool? newDisabled,
    num? newMax,
    int? newMaxLength,
    num? newMin,
    int? newMinLength,
    String? newName,
    String? newPattern,
    String? newPlaceholder,
    bool? newRequired,
    String? newTitle,
    String? newType,
    String? newValue,
    void Function(String)? onChange,
    void Function(String)? onInput,
    List<InputStyling>? style,
    String? tag,
  }) {
    final resolvedStyle = _resolveStyle(style);

    return Input(
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      disabled: newDisabled ?? this.disabled,
      id: id ?? this.id,
      max: newMax ?? this.max,
      maxLength: newMaxLength ?? this.maxLength,
      min: newMin ?? this.min,
      minLength: newMinLength ?? this.minLength,
      name: newName ?? this.name,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      pattern: newPattern ?? this.pattern,
      placeholder: newPlaceholder ?? this.placeholder,
      required: newRequired ?? this.required,
      style: resolvedStyle,
      tag: tag ?? this.tag,
      title: newTitle ?? this.title,
      type: newType ?? this.type,
      value: newValue ?? this.value,
    );
  }

  List<InputStyling>? _resolveStyle(List<InputStyling>? style) {
    if (style != null) return style;

    final currentStyle = this.style;

    return currentStyle is List<InputStyling>? ? currentStyle : null;
  }

  void _configureStringAttributes(UiComponentAttributes attributes) {
    _addOptionalAttribute(attributes, _placeholderAttribute, placeholder);
    _addOptionalAttribute(attributes, _valueAttribute, value);
    _addOptionalAttribute(attributes, _nameAttribute, name);
    _addOptionalAttribute(attributes, _patternAttribute, pattern);
    _addOptionalAttribute(attributes, _titleAttribute, title);
  }

  void _configureBooleanAttributes(UiComponentAttributes attributes) {
    if (disabled) {
      attributes.add(_disabledAttribute, _emptyValue);
    }
    if (required) {
      attributes.add(_requiredAttribute, _emptyValue);
    }
  }

  void _configureNumericAttributes(UiComponentAttributes attributes) {
    _addOptionalNumericAttribute(attributes, _minlengthAttribute, minLength);
    _addOptionalNumericAttribute(attributes, _maxlengthAttribute, maxLength);
    _addOptionalNumericAttribute(attributes, _minAttribute, min);
    _addOptionalNumericAttribute(attributes, _maxAttribute, max);
  }

  static void _addOptionalAttribute(
    UiComponentAttributes attributes,
    String key,
    String? value,
  ) {
    if (value != null) {
      attributes.add(key, value);
    }
  }

  static void _addOptionalNumericAttribute(
    UiComponentAttributes attributes,
    String key,
    num? value,
  ) {
    if (value != null) {
      attributes.add(key, value.toString());
    }
  }
}
