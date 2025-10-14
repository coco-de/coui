import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/form/toggle/toggle_style.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for toggle state change.
typedef ToggleCallback = void Function(bool checked);

/// A toggle (switch) component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// Toggle(
///   checked: true,
///   onChanged: (checked) => print('Toggled: $checked'),
/// )
/// ```
class Toggle extends UiComponent {
  /// Creates a Toggle component.
  ///
  /// Parameters:
  /// - [checked]: Whether the toggle is checked
  /// - [disabled]: Whether the toggle is disabled
  /// - [onChanged]: Callback when toggle state changes
  Toggle({
    super.key,
    this.checked = false,
    this.disabled = false,
    this.onChanged,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _buttonValue,
  }) : super(
         null,
         style: [
           ToggleVariantStyle(),
         ],
       );

  /// Whether the toggle is checked.
  final bool checked;

  /// Whether the toggle is disabled.
  final bool disabled;

  /// Callback when toggle state changes.
  final ToggleCallback? onChanged;

  static const _buttonValue = 'button';

  @override
  Toggle copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    bool? checked,
    bool? disabled,
    ToggleCallback? onChanged,
    Component? child,
    Key? key,
  }) {
    return Toggle(
      child: child ?? this.child,
      key: key ?? this.key,
      checked: checked ?? this.checked,
      disabled: disabled ?? this.disabled,
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
  Component build(BuildContext context) {
    return Component.element(
      child: span(
        classes:
            'pointer-events-none block h-5 w-5 rounded-full bg-background shadow-lg ring-0 transition-transform data-[state=checked]:translate-x-5 data-[state=unchecked]:translate-x-0',
        attributes: {
          'data-state': checked ? 'checked' : 'unchecked',
        },
      ),
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: {
        ...this.componentAttributes,
        'type': 'button',
        'role': 'switch',
        'aria-checked': checked.toString(),
        'data-state': checked ? 'checked' : 'unchecked',
        if (disabled) 'disabled': '',
      },
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
      eventMap['click'] = [
        (event) {
          if (!disabled) {
            currentOnChanged(!checked);
          }
        },
      ];
    }

    return eventMap;
  }
}
