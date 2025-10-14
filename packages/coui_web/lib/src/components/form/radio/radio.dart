import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/form/radio/radio_style.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for radio state change.
typedef RadioCallback = void Function(String value);

/// A radio button component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// Radio(
///   value: 'option1',
///   groupValue: selectedValue,
///   onChanged: (value) => print('Selected: $value'),
/// )
/// ```
class Radio extends UiComponent {
  /// Creates a Radio component.
  ///
  /// Parameters:
  /// - [value]: The value of this radio button
  /// - [groupValue]: The currently selected value in the radio group
  /// - [disabled]: Whether the radio is disabled
  /// - [onChanged]: Callback when radio state changes
  Radio({
    super.key,
    required this.value,
    this.groupValue,
    this.disabled = false,
    this.onChanged,
    this.name,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _inputValue,
  }) : super(
         null,
         style: [
           RadioVariantStyle(),
         ],
       );

  /// The value of this radio button.
  final String value;

  /// The currently selected value in the radio group.
  final String? groupValue;

  /// Whether the radio is disabled.
  final bool disabled;

  /// Callback when radio state changes.
  final RadioCallback? onChanged;

  /// The name attribute (group identifier).
  final String? name;

  static const _inputValue = 'input';

  static const _typeAttribute = 'type';
  static const _radioType = 'radio';
  static const _checkedAttribute = 'checked';
  static const _disabledAttribute = 'disabled';
  static const _nameAttribute = 'name';
  static const _valueAttribute = 'value';
  static const _emptyValue = '';

  @override
  Radio copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? value,
    String? groupValue,
    bool? disabled,
    String? name,
    RadioCallback? onChanged,
    Key? key,
  }) {
    return Radio(
      key: key ?? this.key,
      value: value ?? this.value,
      groupValue: groupValue ?? this.groupValue,
      disabled: disabled ?? this.disabled,
      onChanged: onChanged ?? this.onChanged,
      name: name ?? this.name,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);

    attributes.add(_typeAttribute, _radioType);
    attributes.add(_valueAttribute, value);

    if (value == groupValue) {
      attributes.add(_checkedAttribute, _emptyValue);
    }

    if (disabled) {
      attributes.add(_disabledAttribute, _emptyValue);
    }

    final currentName = name;
    if (currentName != null) {
      attributes.add(_nameAttribute, currentName);
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

  @override
  String get baseClass => '';

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
          currentOnChanged(value);
        },
      ];
    }

    return eventMap;
  }
}

/// A radio group component for managing multiple radio buttons.
class RadioGroup extends UiComponent {
  /// Creates a RadioGroup component.
  RadioGroup({
    super.key,
    required this.children,
    this.groupValue,
    this.onChanged,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(children);

  /// List of radio buttons in this group.
  final List<Component> children;

  /// Currently selected value.
  final String? groupValue;

  /// Callback when selection changes.
  final RadioCallback? onChanged;

  static const _divValue = 'div';

  @override
  RadioGroup copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    String? groupValue,
    RadioCallback? onChanged,
    Key? key,
  }) {
    return RadioGroup(
      key: key ?? this.key,
      children: children ?? this.children,
      groupValue: groupValue ?? this.groupValue,
      onChanged: onChanged ?? this.onChanged,
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
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: children,
    );
  }

  @override
  String get baseClass => 'flex flex-col gap-2';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
