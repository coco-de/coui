import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_dom_utils.dart';
import 'package:coui_web/src/components/form/toggle/toggle_style.dart';
import 'package:jaspr/jaspr.dart'
    show
        BuildContext,
        Component,
        EventCallback,
        Key,
        Styles,
        ValueChanged,
        kIsWeb;

/// A checkbox styled to look like a switch button.
///
/// The `Toggle` is a **controlled component**. Its state is not managed internally.
/// Instead, you must provide its current state via the [isChecked] property and
/// handle state changes with the [onToggle] callback. This ensures that the UI
/// is always a direct reflection of your application's state.
///
/// Example of state management in a `StatefulComponent`:
/// ```dart
/// class MySettings extends StatefulComponent {
///   bool _notificationsEnabled = true;
///
///   @override
///   State<MySettings> createState() => _MySettingsState();
/// }
///
/// class _MySettingsState extends State<MySettings> {
///   @override
///   Iterable<Component> build(BuildContext context) sync* {
///     yield Toggle(
///       isChecked: _notificationsEnabled,
///       onToggle: (newValue) {
///         setState(() => _notificationsEnabled = newValue);
///       },
///       style: [Toggle.primary],
///     );
///   }
/// }
/// ```
class Toggle extends UiComponent {
  /// Creates a Toggle component.
  ///
  /// - [isChecked]: The current checked state of the toggle.
  /// - [onToggle]: A callback that fires when the user clicks the toggle. It
  ///   receives the new potential boolean state. You should use this callback
  ///   to update your application's state.
  /// - [disabled]: If true, the toggle will be non-interactive.
  /// - [indeterminate]: If true, the toggle will be in an indeterminate state.
  ///   **Note:** This property must be managed via JavaScript after the component has
  ///   rendered. See the documentation for an example.
  /// - [style]: A list of [ToggleStyling] instances for styling.
  /// - Other parameters are inherited from [UiComponent].
  const Toggle({
    super.attributes,
    super.classes,
    super.css,
    this.disabled = false,
    super.eventHandlers,
    super.id,
    this.indeterminate = false,
    this.isChecked = false,
    super.key,
    this.onToggle,
    List<ToggleStyling>? style,
    super.tag = _inputTag,
  }) : super(null, style: style);

  // Toggle elements have no children.

  /// The current checked state of the toggle.
  final bool isChecked;

  /// Callback function invoked when the toggle's state changes.
  final ValueChanged<bool>? onToggle;

  /// If true, the toggle is non-interactive.
  final bool disabled;

  /// If true, the toggle will be in an indeterminate state.
  /// This is a visual state that is not submitted with the form value and must
  /// be set via JavaScript after the element has rendered.
  final bool indeterminate;

  // --- Static Style Modifiers ---

  // Colors
  /// Primary color. `toggle-primary`.
  static const primary = ToggleStyle(
    'toggle-primary',
    type: StyleType.style,
  );

  /// Secondary color. `toggle-secondary`.
  static const secondary = ToggleStyle(
    'toggle-secondary',
    type: StyleType.style,
  );

  /// Accent color. `toggle-accent`.
  static const accent = ToggleStyle('toggle-accent', type: StyleType.style);

  /// Neutral color. `toggle-neutral`.
  static const neutral = ToggleStyle(
    'toggle-neutral',
    type: StyleType.style,
  );

  /// Success color. `toggle-success`.
  static const success = ToggleStyle(
    'toggle-success',
    type: StyleType.style,
  );

  /// Warning color. `toggle-warning`.
  static const warning = ToggleStyle(
    'toggle-warning',
    type: StyleType.style,
  );

  /// Info color. `toggle-info`.
  static const info = ToggleStyle('toggle-info', type: StyleType.style);

  /// Error color. `toggle-error`.
  static const error = ToggleStyle('toggle-error', type: StyleType.style);

  // Sizes
  /// Extra-small size. `toggle-xs`.
  static const xs = ToggleStyle('toggle-xs', type: StyleType.sizing);

  /// Small size. `toggle-sm`.
  static const sm = ToggleStyle('toggle-sm', type: StyleType.sizing);

  /// Medium size (default). `toggle-md`.
  static const md = ToggleStyle('toggle-md', type: StyleType.sizing);

  /// Large size. `toggle-lg`.
  static const lg = ToggleStyle('toggle-lg', type: StyleType.sizing);

  /// Extra large size. `toggle-xl`.
  static const xl = ToggleStyle('toggle-xl', type: StyleType.sizing);

  // HTML attribute constants
  static const _typeAttribute = 'type';
  static const _checkboxType = 'checkbox';
  static const _checkedAttribute = 'checked';
  static const _disabledAttribute = 'disabled';
  static const _emptyValue = '';
  static const _toggleBaseClass = 'toggle';
  static const _inputTag = 'input';

  @override
  String get baseClass => _toggleBaseClass;

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    attributes.add(_typeAttribute, _checkboxType);
    if (isChecked) {
      attributes.add(_checkedAttribute, _emptyValue);
    }
    if (disabled) {
      attributes.add(_disabledAttribute, _emptyValue);
    }
  }

  @override
  Toggle copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    bool? disabled,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    bool? indeterminate,
    bool? isChecked,
    Key? key,
    ValueChanged<bool>? onToggle,
    List<ToggleStyling>? style,
    String? tag,
  }) {
    return Toggle(
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      disabled: disabled ?? this.disabled,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      indeterminate: indeterminate ?? this.indeterminate,
      isChecked: isChecked ?? this.isChecked,
      onToggle: onToggle ?? this.onToggle,
      style:
          style ??
          () {
            final currentStyle = this.style;

            return currentStyle is List<ToggleStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    // Start with the standard events from the base class.
    final eventMap = Map<String, EventCallback>.of(events);

    if (onToggle != null) {
      eventMap['change'] = (Object event) {
        // Guard for web-only execution to prevent errors during SSR.
        if (!kIsWeb) return;

        // Safe cast to Event for accessing properties
        final htmlEvent = event as dynamic;
        final target = htmlEvent.target;
        final onToggleCallback = onToggle;
        if (target != null && onToggleCallback != null) {
          onToggleCallback(getChecked(target as Object));
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
