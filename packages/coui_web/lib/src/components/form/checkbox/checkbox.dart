import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/form/checkbox/checkbox_style.dart';
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

/// A checkbox component that allows users to select or deselect a value.
/// It renders an `<input type="checkbox">`.
///
/// The `Checkbox` is a **controlled component**. Its state is not managed internally.
/// Instead, you must provide its current state via the [isChecked] property and
/// handle state changes with the [onToggle] callback. This ensures that the UI
/// is always a direct reflection of your application's state.
///
/// Example of state management in a `StatefulComponent`:
/// ```dart
/// class MyForm extends StatefulComponent {
///   bool _agreedToTerms = false;
///
///   @override
///   State<MyForm> createState() => _MyFormState();
/// }
///
/// class _MyFormState extends State<MyForm> {
///   @override
///   Iterable<Component> build(BuildContext context) sync* {
///     yield Checkbox(
///       isChecked: _agreedToTerms,
///       onToggle: (newValue) {
///         setState(() => _agreedToTerms = newValue);
///       },
///     );
///   }
/// }
/// ```
class Checkbox extends UiComponent {
  /// Creates a Checkbox component.
  ///
  /// - [isChecked]: The current checked state of the checkbox.
  /// - [onToggle]: A callback that fires when the user clicks the checkbox. It
  ///   receives the new potential boolean state. You should use this callback
  ///   to update your application's state.
  /// - [disabled]: If true, the checkbox will be non-interactive.
  /// - [style]: A list of [CheckboxStyling] instances for styling.
  /// - Other parameters are inherited from [UiComponent].
  const Checkbox({
    super.attributes,
    super.classes,
    super.css,
    this.disabled = false,
    super.eventHandlers,
    super.id,
    this.isChecked = false,
    super.key,
    this.onToggle,
    List<CheckboxStyling>? style,
    super.tag = _inputTag,
  }) : super(null, style: style);

  // Checkbox elements have no children.

  /// The current checked state of the checkbox.
  final bool isChecked;

  /// Callback function invoked when the checkbox's state changes.
  final ValueChanged<bool>? onToggle;

  /// If true, the checkbox is non-interactive.
  final bool disabled;

  // --- Static Style Modifiers ---

  // Colors
  /// Primary color. `checkbox-primary`.
  static const primary = CheckboxStyle(
    'checkbox-primary',
    type: StyleType.style,
  );

  /// Secondary color. `checkbox-secondary`.
  static const secondary = CheckboxStyle(
    'checkbox-secondary',
    type: StyleType.style,
  );

  /// Accent color. `checkbox-accent`.
  static const accent = CheckboxStyle(
    'checkbox-accent',
    type: StyleType.style,
  );

  /// Neutral color. `checkbox-neutral`.
  static const neutral = CheckboxStyle(
    'checkbox-neutral',
    type: StyleType.style,
  );

  /// Success color. `checkbox-success`.
  static const success = CheckboxStyle(
    'checkbox-success',
    type: StyleType.style,
  );

  /// Warning color. `checkbox-warning`.
  static const warning = CheckboxStyle(
    'checkbox-warning',
    type: StyleType.style,
  );

  /// Info color. `checkbox-info`.
  static const info = CheckboxStyle('checkbox-info', type: StyleType.style);

  /// Error color. `checkbox-error`.
  static const error = CheckboxStyle(
    'checkbox-error',
    type: StyleType.style,
  );

  // Sizes
  /// Extra-small size. `checkbox-xs`.
  static const xs = CheckboxStyle('checkbox-xs', type: StyleType.sizing);

  /// Small size. `checkbox-sm`.
  static const sm = CheckboxStyle('checkbox-sm', type: StyleType.sizing);

  /// Medium size (default). `checkbox-md`.
  static const md = CheckboxStyle('checkbox-md', type: StyleType.sizing);

  /// Large size. `checkbox-lg`.
  static const lg = CheckboxStyle('checkbox-lg', type: StyleType.sizing);

  /// Extra-large size. `checkbox-xl`.
  static const xl = CheckboxStyle('checkbox-xl', type: StyleType.sizing);

  // HTML attribute constants
  static const _typeAttribute = 'type';
  static const _checkboxValue = 'checkbox';
  static const _checkedAttribute = 'checked';
  static const _disabledAttribute = 'disabled';
  static const _emptyValue = '';
  static const _inputTag = 'input';

  @override
  String get baseClass => _checkboxValue;

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.add(_typeAttribute, _checkboxValue);
    if (isChecked) {
      attributes.add(_checkedAttribute, _emptyValue);
    }
    if (disabled) {
      attributes.add(_disabledAttribute, _emptyValue);
    }
  }

  @override
  Checkbox copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    bool? disabled,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    bool? isChecked,
    Key? key,
    ValueChanged<bool>? onToggle,
    List<CheckboxStyling>? style,
    String? tag,
  }) {
    final currentStyle = this.style;
    final checkboxStyle = currentStyle is List<CheckboxStyling>?
        ? currentStyle
        : null;

    return Checkbox(
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      disabled: disabled ?? this.disabled,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      isChecked: isChecked ?? this.isChecked,
      onToggle: onToggle ?? this.onToggle,
      style: style ?? checkboxStyle,
      tag: tag ?? this.tag,
    );
  }

  /// Overrides the default build method to provide a type-safe `onToggle` callback.
  ///
  /// The base `UiComponent`'s `onChange` event is designed for string values from text inputs.
  /// This override creates a specific event handler for the checkbox's boolean `checked` property,
  /// ensuring it only runs on the client and uses safe type casting.
  @override
  Component build(BuildContext context) {
    // Start with the standard events from the base class.
    final eventMap = Map<String, EventCallback>.of(events);

    if (onToggle != null) {
      eventMap['change'] = (Object event) {
        // Guard for web-only execution to prevent errors during SSR.
        if (!kIsWeb || event is! Event) return;

        final target = event.target;
        final onToggleCallback = onToggle;
        if (target != null && onToggleCallback != null) {
          onToggleCallback(getChecked(target));
        }
      };
    }

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
