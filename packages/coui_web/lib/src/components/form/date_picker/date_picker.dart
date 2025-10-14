import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for date change.
typedef DateCallback = void Function(String date);

/// A date picker component (web native input type="date").
///
/// Example:
/// ```dart
/// DatePicker(
///   value: '2025-01-15',
///   onChanged: (date) => print('Selected: $date'),
/// )
/// ```
class DatePicker extends UiComponent {
  /// Creates a DatePicker component.
  const DatePicker({
    super.key,
    this.value,
    this.placeholder = 'Select date',
    this.disabled = false,
    this.min,
    this.max,
    this.onChanged,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _inputValue,
  }) : super(null);

  /// Current value (ISO date string: YYYY-MM-DD).
  final String? value;

  /// Placeholder text.
  final String placeholder;

  /// Whether input is disabled.
  final bool disabled;

  /// Minimum date (ISO date string).
  final String? min;

  /// Maximum date (ISO date string).
  final String? max;

  /// Change callback.
  final DateCallback? onChanged;

  static const _inputValue = 'input';

  @override
  DatePicker copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? value,
    String? placeholder,
    bool? disabled,
    String? min,
    String? max,
    DateCallback? onChanged,
    Key? key,
  }) {
    return DatePicker(
      key: key ?? this.key,
      value: value ?? this.value,
      placeholder: placeholder ?? this.placeholder,
      disabled: disabled ?? this.disabled,
      min: min ?? this.min,
      max: max ?? this.max,
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
    return input(
      id: id,
      type: InputType.date,
      value: value,
      placeholder: placeholder,
      disabled: disabled,
      classes: _buildClasses(),
      styles: this.css,
      attributes: _buildAttributes(),
      events: _buildEvents(),
    );
  }

  @override
  String get baseClass =>
      'flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50';

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  Map<String, String> _buildAttributes() {
    final attrs = <String, String>{
      ...componentAttributes,
    };

    final currentMin = min;
    if (currentMin != null) {
      attrs['min'] = currentMin;
    }
    final currentMax = max;
    if (currentMax != null) {
      attrs['max'] = currentMax;
    }

    return attrs;
  }

  Map<String, List<dynamic>> _buildEvents() {
    final eventMap = <String, List<dynamic>>{};

    if (onChanged != null) {
      eventMap['change'] = [
        (dynamic event) {
          final target = event.target;
          if (target != null) {
            final value = (target as dynamic).value as String?;
            if (value != null) {
              onChanged(value);
            }
          }
        },
      ];
    }

    return eventMap;
  }
}
