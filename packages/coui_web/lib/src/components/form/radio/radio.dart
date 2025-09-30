import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/form/radio/radio_style.dart';
import 'package:jaspr/jaspr.dart'
    show
        BuildContext,
        Component,
        EventCallback,
        Key,
        Styles,
        ValueChanged,
        kIsWeb;
import 'package:universal_web/web.dart' show Event;

/// A radio button component that allows users to select one option from a group.
/// It renders an `<input type="radio">`.
///
/// The `Radio` component is a **controlled component** and is generic over the type `T`
/// of its value for type safety.
///
/// Its state is managed by a parent component, which holds the currently selected
/// value for the entire group (`groupValue`). The `Radio` determines if it is
/// checked by comparing its own `value` to the `groupValue`. When clicked, it
/// notifies the parent of the selection via the `onSelect` callback.
///
/// Example of state management in a `StatefulComponent`:
/// ```dart
/// enum Flavor { vanilla, chocolate, strawberry }
///
/// class MyFormState extends State<MyForm> {
///   Flavor _selectedFlavor = Flavor.vanilla;
///
///   @override
///   Iterable<Component> build(BuildContext context) sync* {
///     for (final flavor in Flavor.values) {
///       yield Radio<Flavor>(
///         value: flavor,
///         groupValue: _selectedFlavor,
///         name: 'flavor-group',
///         onSelect: (newValue) {
///           setState(() => _selectedFlavor = newValue);
///         },
///       );
///     }
///   }
/// }
/// ```
class Radio<T> extends UiComponent {
  /// Creates a Radio button component.
  ///
  /// - [value]: The unique value of type `T` that this radio button represents.
  /// - [groupValue]: The currently selected value of type `T` for the entire
  ///   radio group.
  ///   The radio button is considered 'checked' if `value == groupValue`.
  /// - [name]: The HTML `name` attribute, which must be the same for all radio
  ///   buttons in a group to ensure they are mutually exclusive.
  /// - [onSelect]: A callback that fires when the user selects this radio
  ///   button.
  ///   It receives the `value` of this component.
  /// - [disabled]: If true, the radio button will be non-interactive.
  /// - [style]: A list of [RadioStyling] instances for styling.
  /// - Other parameters are inherited from [UiComponent].
  // ignore: always_put_required_named_parameters_first, reason: Parameters stay alphabetical to satisfy DCM ordering rules.
  const Radio({
    super.attributes,
    super.classes,
    super.css,
    this.disabled = false,
    super.eventHandlers,
    required this.groupValue,
    super.id,
    super.key,
    required this.name,
    this.onSelect,
    List<RadioStyling>? style,
    super.tag = 'input',
    required this.value,
  }) : super(null, style: style);

  // Radio elements have no children.

  // --- Static Style Modifiers ---

  // Colors
  /// Applies the primary theme color. `radio-primary`.
  static const primary = RadioStyle('radio-primary', type: StyleType.style);

  /// Applies the secondary theme color. `radio-secondary`.
  static const secondary = RadioStyle(
    'radio-secondary',
    type: StyleType.style,
  );

  /// Applies the accent theme color. `radio-accent`.
  static const accent = RadioStyle('radio-accent', type: StyleType.style);

  /// Applies the neutral theme color. `radio-neutral`.
  static const neutral = RadioStyle('radio-neutral', type: StyleType.style);

  /// Applies the success theme color, typically green. `radio-success`.
  static const success = RadioStyle('radio-success', type: StyleType.style);

  /// Applies the warning theme color, typically yellow or orange.
  /// `radio-warning`.
  static const warning = RadioStyle('radio-warning', type: StyleType.style);

  /// Applies the info theme color, typically light blue. `radio-info`.
  static const info = RadioStyle('radio-info', type: StyleType.style);

  /// Applies the error theme color, typically red. `radio-error`.
  static const error = RadioStyle('radio-error', type: StyleType.style);

  // Sizes
  /// Renders an extra-small radio button. `radio-xs`.
  static const xs = RadioStyle('radio-xs', type: StyleType.sizing);

  /// Renders a small radio button. `radio-sm`.
  static const sm = RadioStyle('radio-sm', type: StyleType.sizing);

  /// Renders a medium-sized radio button (default size). `radio-md`.
  static const md = RadioStyle('radio-md', type: StyleType.sizing);

  /// Renders a large radio button. `radio-lg`.
  static const lg = RadioStyle('radio-lg', type: StyleType.sizing);

  /// Renders an extra-large radio button. `radio-xl`.
  static const xl = RadioStyle('radio-xl', type: StyleType.sizing);

  /// The unique value this radio button represents within its group.
  final T value;

  /// The currently selected value for the entire radio group.
  final T groupValue;

  /// The name for the radio button group.
  final String name;

  /// Callback function invoked when this radio button is selected.
  final ValueChanged<T>? onSelect;

  /// If true, the radio button is non-interactive.
  final bool disabled;

  // HTML attribute constants
  static const _typeAttribute = 'type';
  static const _radioValue = 'radio';
  static const _nameAttribute = 'name';
  static const _valueAttribute = 'value';
  static const _checkedAttribute = 'checked';
  static const _disabledAttribute = 'disabled';
  static const _emptyValue = '';

  /// Internally computed checked state.
  bool get isChecked => value == groupValue;

  @override
  String get baseClass => _radioValue;

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes
      ..add(_typeAttribute, _radioValue)
      ..add(_nameAttribute, name)
      // The HTML value attribute is always a string.
      ..add(_valueAttribute, value.toString());
    if (isChecked) {
      attributes.add(_checkedAttribute, _emptyValue);
    }
    if (disabled) {
      attributes.add(_disabledAttribute, _emptyValue);
    }
  }

  @override
  Radio<T> copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    bool? disabled,
    Map<String, List<UiEventHandler>>? eventHandlers,
    T? groupValue,
    String? id,
    Key? key,
    String? name,
    ValueChanged<T>? onSelect,
    List<RadioStyling>? style,
    String? tag,
    T? value,
  }) {
    // This copyWith implementation is complex due to generics and
    // required fields.
    // It is provided for completeness of the UiComponent contract but may need
    // adjustments based on specific use cases for copying Radio components.
    final currentStyle = this.style;
    final radioStyle = currentStyle is List<RadioStyling>?
        ? currentStyle
        : null;

    return Radio(
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      disabled: disabled ?? this.disabled,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      groupValue: groupValue ?? this.groupValue,
      id: id ?? this.id,
      name: name ?? this.name,
      onSelect: onSelect ?? this.onSelect,
      style: style ?? radioStyle,
      tag: tag ?? this.tag,
      value: value ?? this.value,
    );
  }

  @override
  Component build(BuildContext context) {
    final eventMap = Map<String, EventCallback>.of(events);

    // The 'change' event fires when a radio button is selected.
    eventMap['change'] = (Object event) {
      // Guard for web-only execution.
      if (!kIsWeb || event is! Event) return;

      final target = event.target;
      if (target != null && getChecked(target)) {
        onSelect?.call(value);
      }
    };

    return Component.element(
      attributes: componentAttributes,
      classes: combinedClasses,
      events: eventMap,
      id: id,
      styles: css,
      tag: tag,
    );
  }
}
