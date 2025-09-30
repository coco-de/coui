import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/form/slider/slider_style.dart';
import 'package:jaspr/jaspr.dart';

/// A slider component for selecting a value from a range.
///
/// The Slider component provides a draggable control for selecting
/// a numeric value within a specified range. It follows DaisyUI's range
/// slider patterns and provides Flutter-compatible API.
///
/// Features:
/// - Configurable min, max, and step values
/// - Optional value display
/// - Optional step markers
/// - Color variants (primary, secondary, accent)
/// - Size variants
/// - Real-time value updates
///
/// Example:
/// ```dart
/// Slider(
///   value: 50.0,
///   min: 0.0,
///   max: 100.0,
///   step: 1.0,
///   onChanged: (value) => setState(() => sliderValue = value),
///   showValue: true,
///   style: [Slider.primary, Slider.md],
/// )
/// ```
class Slider extends UiComponent {
  /// Creates a Slider component.
  ///
  /// - [value]: Current value of the slider.
  /// - [onChanged]: Callback when slider value changes (Flutter-compatible).
  /// - [min]: Minimum value (default: 0.0).
  /// - [max]: Maximum value (default: 100.0).
  /// - [step]: Step increment (default: 1.0).
  /// - [showValue]: Whether to display current value.
  /// - [showSteps]: Whether to show step markers.
  /// - [style]: List of [SliderStyling] instances for styling.
  const Slider({
    super.attributes,
    super.child,
    super.classes,
    super.css,
    super.id,
    super.key,
    this.max = 100.0,
    this.min = 0.0,
    this.onChanged,
    this.showSteps = false,
    this.showValue = false,
    this.step = 1.0,
    List<SliderStyling>? style,
    super.tag = 'div',
    this.value = 50.0,
  }) : super(null, style: style);

  /// Current value of the slider.
  final double value;

  /// Callback when slider value changes.
  ///
  /// Flutter-compatible void Function(double) callback.
  /// Receives the new value when the slider is moved.
  final void Function(double)? onChanged;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Step increment.
  final double step;

  /// Whether to show the current value.
  final bool showValue;

  /// Whether to show step markers.
  final bool showSteps;

  // --- Static Style Modifiers ---

  /// Primary color. `range-primary`.
  static const primary = SliderStyle('range-primary', type: StyleType.style);

  /// Secondary color. `range-secondary`.
  static const secondary =
      SliderStyle('range-secondary', type: StyleType.style);

  /// Accent color. `range-accent`.
  static const accent = SliderStyle('range-accent', type: StyleType.style);

  /// Info color. `range-info`.
  static const info = SliderStyle('range-info', type: StyleType.style);

  /// Success color. `range-success`.
  static const success = SliderStyle('range-success', type: StyleType.style);

  /// Warning color. `range-warning`.
  static const warning = SliderStyle('range-warning', type: StyleType.style);

  /// Error color. `range-error`.
  static const error = SliderStyle('range-error', type: StyleType.style);

  /// Large size. `range-lg`.
  static const lg = SliderStyle('range-lg', type: StyleType.sizing);

  /// Medium size. `range-md`.
  static const md = SliderStyle('range-md', type: StyleType.sizing);

  /// Small size. `range-sm`.
  static const sm = SliderStyle('range-sm', type: StyleType.sizing);

  /// Extra small size. `range-xs`.
  static const xs = SliderStyle('range-xs', type: StyleType.sizing);

  @override
  String get baseClass => 'form-control';

  @override
  Component build(BuildContext context) {
    final styles = _buildStyleClasses();

    // Build range input
    final rangeInput = Component.element(
      attributes: {
        'type': 'range',
        'min': min.toString(),
        'max': max.toString(),
        'step': step.toString(),
        'value': value.toString(),
      },
      classes: 'range${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}',
      events: onChanged != null
          ? {
              'input': (event) {
                final target = (event as dynamic).target;
                final newValue = double.tryParse(target.value as String);
                if (newValue != null) {
                  onChanged!(newValue);
                }
              },
            }
          : null,
      tag: 'input',
    );

    // Build optional value display
    final valueDisplay = showValue
        ? Component.element(
            classes: 'label',
            tag: 'div',
            children: [
              Component.element(
                classes: 'label-text-alt',
                tag: 'span',
                children: [Component.text(value.toString())],
              ),
            ],
          )
        : null;

    // Build optional step markers
    final stepMarkers = showSteps ? _buildStepMarkers() : null;

    return Component.element(
      attributes: componentAttributes,
      classes: combinedClasses,
      css: css,
      id: id,
      tag: tag,
      children: [
        if (valueDisplay != null) valueDisplay,
        rangeInput,
        if (stepMarkers != null) stepMarkers,
      ],
    );
  }

  List<String> _buildStyleClasses() {
    final stylesList = <String>[];

    if (style != null) {
      for (final s in style!) {
        if (s is SliderStyling) {
          stylesList.add(s.cssClass);
        }
      }
    }

    return stylesList;
  }

  Component _buildStepMarkers() {
    // Calculate number of steps
    final stepCount = ((max - min) / step).round();

    // Build markers (simplified version - DaisyUI doesn't have built-in step markers)
    final markers = <Component>[];
    for (var i = 0; i <= stepCount; i++) {
      markers.add(
        Component.element(
          classes: 'w-1 h-1 bg-base-content rounded-full',
          tag: 'span',
        ),
      );
    }

    return Component.element(
      classes: 'flex justify-between w-full px-2 text-xs',
      tag: 'div',
      children: markers,
    );
  }

  @override
  Slider copyWith({
    Map<String, String>? attributes,
    Component? child,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    double? max,
    double? min,
    void Function(double)? onChanged,
    bool? showSteps,
    bool? showValue,
    double? step,
    List<SliderStyling>? style,
    String? tag,
    double? value,
  }) {
    return Slider(
      attributes: attributes ?? userProvidedAttributes,
      child: child ?? this.child,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      key: key ?? this.key,
      max: max ?? this.max,
      min: min ?? this.min,
      onChanged: onChanged ?? this.onChanged,
      showSteps: showSteps ?? this.showSteps,
      showValue: showValue ?? this.showValue,
      step: step ?? this.step,
      style: style ??
          () {
            final currentStyle = this.style;
            return currentStyle is List<SliderStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
      value: value ?? this.value,
    );
  }
}