import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for switch field change.
typedef SwitchFieldCallback = void Function(bool value);

/// A switch field component with label (similar to Toggle but with label).
///
/// Example:
/// ```dart
/// SwitchField(
///   label: 'Enable notifications',
///   checked: true,
///   onChanged: (value) => print('Changed: $value'),
/// )
/// ```
class SwitchField extends UiComponent {
  /// Creates a SwitchField component.
  const SwitchField({
    super.key,
    required this.label,
    this.checked = false,
    this.onChanged,
    this.description,
    this.disabled = false,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Field label.
  final String label;

  /// Whether the switch is checked.
  final bool checked;

  /// Change callback.
  final SwitchFieldCallback? onChanged;

  /// Optional description.
  final String? description;

  /// Whether the switch is disabled.
  final bool disabled;

  static const _divValue = 'div';

  @override
  SwitchField copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? label,
    bool? checked,
    SwitchFieldCallback? onChanged,
    String? description,
    bool? disabled,
    Key? key,
  }) {
    return SwitchField(
      key: key ?? this.key,
      label: label ?? this.label,
      checked: checked ?? this.checked,
      onChanged: onChanged ?? this.onChanged,
      description: description ?? this.description,
      disabled: disabled ?? this.disabled,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return div(
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
      children: [
        // Label and description
        div(
          classes: 'space-y-0.5',
          children: [
            Component.element(
              tag: 'label',
              classes: 'text-sm font-medium leading-none cursor-pointer',
              child: text(label),
            ),
            if (description != null)
              p(
                classes: 'text-sm text-muted-foreground',
                child: text(description!),
              ),
          ],
        ),
        // Switch
        button(
          classes: _buildSwitchClasses(),
          attributes: {
            'type': 'button',
            'role': 'switch',
            'aria-checked': checked.toString(),
            'data-state': checked ? 'checked' : 'unchecked',
            if (disabled) 'disabled': '',
          },
          events: _buildEvents(),
          child: span(
            classes:
                'pointer-events-none block h-5 w-5 rounded-full bg-background shadow-lg ring-0 transition-transform data-[state=checked]:translate-x-5 data-[state=unchecked]:translate-x-0',
            attributes: {
              'data-state': checked ? 'checked' : 'unchecked',
            },
          ),
        ),
      ],
    );
  }

  @override
  String get baseClass => 'flex items-center justify-between space-x-2';

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }

  static String _buildSwitchClasses() {
    return 'peer inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-primary data-[state=unchecked]:bg-input';
  }

  Map<String, List<dynamic>> _buildEvents() {
    final currentOnChanged = onChanged;
    return currentOnChanged == null || disabled
        ? {}
        : {
            'click': [
              (event) => currentOnChanged(!checked),
            ],
          };
  }
}
