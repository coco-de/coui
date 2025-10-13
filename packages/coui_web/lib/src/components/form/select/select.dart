import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/form/select/select_style.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for select value change.
typedef SelectCallback = void Function(String value);

/// A select dropdown component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// Select(
///   options: [
///     SelectOption('apple', 'Apple'),
///     SelectOption('banana', 'Banana'),
///     SelectOption('orange', 'Orange'),
///   ],
///   onChanged: (value) => print('Selected: $value'),
/// )
/// ```
class Select extends UiComponent {
  /// Creates a Select component.
  ///
  /// Parameters:
  /// - [options]: List of select options
  /// - [value]: Currently selected value
  /// - [disabled]: Whether the select is disabled
  /// - [onChanged]: Callback when selection changes
  Select({
    super.key,
    required this.options,
    this.value,
    this.disabled = false,
    this.onChanged,
    this.name,
    this.placeholder,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _selectValue,
  }) : super(
         null,
         style: [
           SelectVariantStyle(),
         ],
       );

  /// List of select options.
  final List<SelectOption> options;

  /// Currently selected value.
  final String? value;

  /// Whether the select is disabled.
  final bool disabled;

  /// Callback when selection changes.
  final SelectCallback? onChanged;

  /// The name attribute.
  final String? name;

  /// Placeholder text.
  final String? placeholder;

  static const _selectValue = 'select';
  static const _disabledAttribute = 'disabled';
  static const _nameAttribute = 'name';
  static const _emptyValue = '';

  @override
  Select copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<SelectOption>? options,
    String? value,
    String? placeholder,
    bool? disabled,
    SelectCallback? onChanged,
    String? name,
    Key? key,
  }) {
    return Select(
      key: key ?? this.key,
      options: options ?? this.options,
      value: value ?? this.value,
      placeholder: placeholder ?? this.placeholder,
      disabled: disabled ?? this.disabled,
      onChange: onChange ?? this.onChanged,
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
    final optionComponents = <Component>[];

    // Add placeholder option if provided
    if (placeholder != null) {
      optionComponents.add(
        Component.element(
          tag: 'option',
          attributes: {'value': '', 'disabled': '', 'selected': ''},
          child: text(placeholder!),
        ),
      );
    }

    // Add regular options
    for (final option in options) {
      optionComponents.add(
        Component.element(
          tag: 'option',
          attributes: {
            'value': option.value,
            if (option.value == value) 'selected': '',
          },
          child: text(option.label),
        ),
      );
    }

    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: _buildEvents(),
      children: optionComponents,
    );
  }

  String _buildClasses() {
    final classList = <String>[];

    // Add variant classes from style
    if (style != null) {
      for (final s in style!) {
        classList.add(s.cssClass);
      }
    }

    // Add user classes
    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  Map<String, List<dynamic>> _buildEvents() {
    final eventMap = <String, List<dynamic>>{};

    final currentOnChanged = onChanged;
    if (currentOnChanged != null) {
      eventMap['change'] = [
        (event) {
          // In web, we'd extract the selected value from the event
          // For now, placeholder implementation
          currentOnChanged('');
        },
      ];
    }

    return eventMap;
  }
}

/// Represents a select option.
class SelectOption {
  /// Creates a SelectOption.
  const SelectOption(this.value, this.label);

  /// The value of the option.
  final String value;

  /// The display label of the option.
  final String label;
}
