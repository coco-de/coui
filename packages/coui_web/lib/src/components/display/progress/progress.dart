import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_component_attributes.dart';
import 'package:coui_web/src/components/display/progress/progress_style.dart';
import 'package:jaspr/jaspr.dart' show Key, Styles;

/// A component to show the progress of a task or the passing of time.
///
/// It renders a semantic `<progress>` HTML element. The component can be either
/// determinate or indeterminate.
///
/// - **Determinate:** Provide a `value` and `max`.
/// - **Indeterminate:** Omit the `value` (or pass `null`). The browser will
///   render a waiting/indeterminate animation.
///
/// Example Usage:
/// ```dart
/// // Determinate progress bar at 40%
/// Progress(
///   value: 40,
///   max: 100,
///   style: [Progress.primary, Sizing.w(56)],
/// )
///
/// // Indeterminate progress bar
/// Progress(
///   style: [Sizing.w(56)],
/// )
/// ```
class Progress extends UiComponent {
  /// Creates a Progress component.
  ///
  /// - [value]: The current progress value. If `null`, the progress bar is
  ///   indeterminate.
  /// - [max]: The maximum value of the progress bar. Defaults to `100`.
  /// - [style]: A list of [ProgressStyling] instances to control the color.
  ///   Size should be applied using a general utility like `Sizing.w(56)`.
  /// - [tag]: The HTML tag for the root element, defaults to 'progress'.
  /// - Other parameters are inherited from [UiComponent].
  const Progress({
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.key,
    this.max = _defaultMaxValue,
    List<ProgressStyling>? style,
    super.tag = 'progress',
    this.value,
  }) : super(null, style: style);

  // Progress elements have no children.

  /// The current value of the progress bar. If null, the bar is indeterminate.
  final double? value;

  /// The maximum value, representing completion.
  final double max;

  // --- Static Style Modifiers ---

  // Colors
  /// Neutral color. `progress-neutral`.
  static const neutral = ProgressStyle(
    'progress-neutral',
    type: StyleType.style,
  );

  /// Primary color. `progress-primary`.
  static const primary = ProgressStyle(
    'progress-primary',
    type: StyleType.style,
  );

  /// Secondary color. `progress-secondary`.
  static const secondary = ProgressStyle(
    'progress-secondary',
    type: StyleType.style,
  );

  /// Accent color. `progress-accent`.
  static const accent = ProgressStyle(
    'progress-accent',
    type: StyleType.style,
  );

  /// Info color. `progress-info`.
  static const info = ProgressStyle('progress-info', type: StyleType.style);

  /// Success color. `progress-success`.
  static const success = ProgressStyle(
    'progress-success',
    type: StyleType.style,
  );

  /// Warning color. `progress-warning`.
  static const warning = ProgressStyle(
    'progress-warning',
    type: StyleType.style,
  );

  /// Error color. `progress-error`.
  static const error = ProgressStyle(
    'progress-error',
    type: StyleType.style,
  ); // HTML attribute constants
  static const _valueAttribute = 'value';
  static const _maxAttribute = 'max';

  static const _defaultMaxValue = 100.0;

  @override
  String get baseClass => 'progress';

  @override
  void configureAttributes(UiComponentAttributes attributes) {
    super.configureAttributes(attributes);
    // The native <progress> element has implicit accessibility roles.
    // We only need to provide the value and max attributes.
    final valueData = value;
    if (valueData != null) {
      attributes.add(_valueAttribute, valueData.toString());
    }
    attributes.add(_maxAttribute, max.toString());
  }

  @override
  Progress copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    double? max,
    List<ProgressStyling>? style,
    String? tag,
    double? value,
  }) {
    return Progress(
      key: key ?? this.key,
      attributes: attributes ?? userProvidedAttributes,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      id: id ?? this.id,
      max: max ?? this.max,
      style:
          style ??
          () {
            final currentStyle = this.style;

            return currentStyle is List<ProgressStyling>? ? currentStyle : null;
          }(),
      tag: tag ?? this.tag,
      value: value ?? this.value,
    );
  }
}
