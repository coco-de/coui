import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/form/slider/slider_style.dart';
import 'package:jaspr/jaspr.dart';

/// Callback signature for slider value change.
typedef SliderCallback = void Function(double value);

/// A slider component following shadcn-ui design patterns.
///
/// Example:
/// ```dart
/// Slider(
///   value: 50,
///   min: 0,
///   max: 100,
///   onChanged: (value) => print('Value: $value'),
/// )
/// ```
class Slider extends UiComponent {
  /// Creates a Slider component.
  ///
  /// Parameters:
  /// - [value]: Current slider value
  /// - [min]: Minimum value
  /// - [max]: Maximum value
  /// - [step]: Step increment
  /// - [disabled]: Whether the slider is disabled
  /// - [onChanged]: Callback when value changes
  Slider({
    super.key,
    this.value = _defaultMinValue,
    this.min = _defaultMinValue,
    this.max = _defaultMaxValue,
    this.step = 1,
    this.disabled = false,
    this.onChanged,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(
         null,
         style: [
           SliderVariantStyle(),
         ],
       );

  /// Current slider value.
  final double value;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Step increment.
  final double step;

  /// Whether the slider is disabled.
  final bool disabled;

  /// Callback when value changes.
  final SliderCallback? onChanged;

  static const _defaultMinValue = 0;

  static const _defaultMaxValue = 100;

  static const _percentageMultiplier = 100;

  static const _divValue = 'div';
  static const _inputValue = 'input';

  @override
  Slider copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    double? value,
    double? min,
    double? max,
    double? step,
    bool? disabled,
    SliderCallback? onChanged,
    Key? key,
  }) {
    return Slider(
      key: key ?? this.key,
      value: value ?? this.value,
      min: min ?? this.min,
      max: max ?? this.max,
      step: step ?? this.step,
      disabled: disabled ?? this.disabled,
      onChange: onChange ?? this.onChanged,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
      onChanged: onChanged ?? this.onChanged,
    );
  }

  @override
  Component build(BuildContext context) {
    // Calculate percentage for visual representation
    final percentage = ((value - min) / (max - min) * _percentageMultiplier)
        .clamp(_defaultMinValue, _defaultMaxValue);

    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: [
        // Track
        div(
          classes:
              'relative h-2 w-full grow overflow-hidden rounded-full bg-secondary',
          children: [
            // Range (filled portion)
            div(
              classes: 'absolute h-full bg-primary',
              styles: {'width': '$percentage%'},
            ),
          ],
        ),
        // Native input for functionality
        Component.element(
          tag: _inputValue,
          attributes: {
            'type': 'range',
            'min': min.toString(),
            'max': max.toString(),
            'step': step.toString(),
            'value': value.toString(),
            if (disabled) 'disabled': '',
          },
          classes: 'absolute inset-0 w-full opacity-0 cursor-pointer',
          events: _buildInputEvents(),
        ),
      ],
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

  Map<String, List<dynamic>> _buildInputEvents() {
    final events = <String, List<dynamic>>{};

    final currentOnChanged = onChanged;
    if (currentOnChanged != null) {
      events['input'] = [
        (event) {
          // In real implementation, extract value from event
          currentOnChanged(value);
        },
      ];
    }

    return events;
  }
}
