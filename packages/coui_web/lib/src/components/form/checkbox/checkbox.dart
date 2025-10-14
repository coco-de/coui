import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/form/checkbox/checkbox_style.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for checkbox state change.
typedef CheckboxCallback = void Function(bool checked);

/// A checkbox component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// Checkbox(
///   checked: true,
///   onChanged: (checked) => print('Checked: $checked'),
/// )
/// ```
class Checkbox extends UiComponent {
  /// Creates a Checkbox component.
  ///
  /// Parameters:
  /// - [checked]: Whether the checkbox is checked
  /// - [disabled]: Whether the checkbox is disabled
  /// - [onChanged]: Callback when checkbox state changes
  Checkbox({
    super.key,
    this.checked = false,
    this.disabled = false,
    this.onChanged,
    this.name,
    this.value,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _inputValue,
  }) : super(
         null,
         style: [
           CheckboxVariantStyle(),
         ],
       );

  /// Whether the checkbox is checked.
  final bool checked;

  /// Whether the checkbox is disabled.
  final bool disabled;

  /// Callback when checkbox state changes.
  final CheckboxCallback? onChanged;

  /// The name attribute.
  final String? name;

  /// The value attribute.
  final String? value;

  static const _inputValue = 'input';
  static const _typeAttribute = 'type';
  static const _checkboxType = 'checkbox';
  static const _checkedAttribute = 'checked';
  static const _disabledAttribute = 'disabled';
  static const _nameAttribute = 'name';
  static const _valueAttribute = 'value';
  static const _emptyValue = '';

  @override
  Checkbox copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    bool? checked,
    bool? disabled,
    String? name,
    String? value,
    CheckboxCallback? onChanged,
    Key? key,
  }) {
    return Checkbox(
      key: key ?? this.key,
      checked: checked ?? this.checked,
      disabled: disabled ?? this.disabled,
      name: name ?? this.name,
      value: value ?? this.value,
      onChanged: onChanged ?? this.onChanged,
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

    attributes.add(_typeAttribute, _checkboxType);

    if (checked) {
      attributes.add(_checkedAttribute, _emptyValue);
    }

    if (disabled) {
      attributes.add(_disabledAttribute, _emptyValue);
    }

    final currentName = name;
    if (currentName != null) {
      attributes.add(_nameAttribute, currentName);
    }

    final currentValue = value;
    if (currentValue != null) {
      attributes.add(_valueAttribute, currentValue);
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
      events: _buildEvents(),
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

  Map<String, List<dynamic>> _buildEvents() {
    final eventMap = <String, List<dynamic>>{};

    final currentOnChanged = onChanged;
    if (currentOnChanged != null) {
      eventMap['change'] = [
        (event) {
          // In web, we'd extract the checked state from the event
          currentOnChanged(!checked);
        },
      ];
    }

    return eventMap;
  }
}
