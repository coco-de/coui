import 'package:coui_web/src/components/form/input/input.dart';
import 'package:coui_web/src/components/form/input/input_style.dart';
import 'package:jaspr/jaspr.dart' show Key, Styles;

/// A Flutter-compatible TextField component for web.
///
/// This is a wrapper around [Input] that provides the same API as
/// coui_flutter's TextField, making it easy to use the same code
/// structure for both Flutter and Web platforms.
///
/// Example:
/// ```dart
/// TextField(
///   placeholder: 'Enter your name',
///   onChanged: (value) => print('Changed: $value'),
/// )
/// ```
class TextField extends Input {
  /// Creates a TextField component with Flutter-compatible API.
  ///
  /// - [onChanged]: Callback when the input value changes (Flutter-compatible).
  /// - [placeholder]: Placeholder text to display.
  /// - [value]: The initial value of the input.
  /// - Other parameters are inherited from [Input].
  TextField({
    super.attributes,
    super.classes,
    super.css,
    super.disabled,
    super.id,
    super.key,
    super.max,
    super.maxLength,
    super.min,
    super.minLength,
    super.name,
    void Function(String)? onChanged,
    super.pattern,
    super.placeholder,
    super.required,
    super.style,
    super.tag,
    super.title,
    super.type,
    super.value,
  }) : super(
          // Convert Flutter-style onChanged to web onInput/onChange events
          onInput: onChanged,
          onChange: onChanged,
        );

  /// Creates a primary styled TextField.
  factory TextField.primary({
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
    void Function(String)? onChanged,
    String? pattern,
    String? placeholder,
    bool? required,
    List<InputStyling>? style,
    String? tag,
    String? title,
    String? type,
    String? value,
  }) {
    return TextField(
      attributes: attributes,
      classes: classes,
      css: css,
      disabled: disabled ?? false,
      id: id,
      key: key,
      max: max,
      maxLength: maxLength,
      min: min,
      minLength: minLength,
      name: name,
      onChanged: onChanged,
      pattern: pattern,
      placeholder: placeholder,
      required: required ?? false,
      style: [
        if (style != null) ...style,
        Input.primary,
        Input.bordered,
      ],
      tag: tag,
      title: title,
      type: type,
      value: value,
    );
  }

  /// Creates a secondary styled TextField.
  factory TextField.secondary({
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
    void Function(String)? onChanged,
    String? pattern,
    String? placeholder,
    bool? required,
    List<InputStyling>? style,
    String? tag,
    String? title,
    String? type,
    String? value,
  }) {
    return TextField(
      attributes: attributes,
      classes: classes,
      css: css,
      disabled: disabled ?? false,
      id: id,
      key: key,
      max: max,
      maxLength: maxLength,
      min: min,
      minLength: minLength,
      name: name,
      onChanged: onChanged,
      pattern: pattern,
      placeholder: placeholder,
      required: required ?? false,
      style: [
        if (style != null) ...style,
        Input.secondary,
        Input.bordered,
      ],
      tag: tag,
      title: title,
      type: type,
      value: value,
    );
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
    return super.copyWith(
      attributes: attributes,
      classes: classes,
      css: css,
      disabled: disabled,
      id: id,
      key: key,
      max: max,
      maxLength: maxLength,
      min: min,
      minLength: minLength,
      name: name,
      onChange: onChange,
      onInput: onInput,
      pattern: pattern,
      placeholder: placeholder,
      required: required,
      style: style,
      tag: tag,
      title: title,
      type: type,
      value: value,
    );
  }
}