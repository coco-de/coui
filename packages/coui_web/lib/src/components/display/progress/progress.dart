import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/variant_system.dart';
import 'package:coui_web/src/components/display/progress/progress_style.dart';
import 'package:jaspr/jaspr.dart';

/// A progress indicator component following shadcn-ui design patterns.
///
/// Displays the completion progress of a task.
///
/// Example:
/// ```dart
/// Progress(value: 60) // 60% complete
/// ```
class Progress extends UiComponent {
  /// Creates a Progress component.
  ///
  /// Parameters:
  /// - [value]: The current progress value (0-100)
  /// - [max]: The maximum value (default: 100)
  Progress({
    super.key,
    this.value = _defaultMinValue,
    this.max = _defaultMaxValue,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(
         null,
         style: [
           ProgressVariantStyle(variant: ProgressVariant.defaultVariant),
         ],
       );

  /// The current progress value.
  final double value;

  /// The maximum value.
  final double max;

  static const _divValue = 'div';
  static const _defaultMinValue = 0;
  static const _defaultMaxValue = 100;
  static const _percentageMultiplier = 100;

  @override
  Progress copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    double? value,
    double? max,
    Key? key,
  }) {
    return Progress(
      key: key ?? this.key,
      value: value ?? this.value,
      max: max ?? this.max,
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
    final percentage = (value / max * _percentageMultiplier).clamp(
      _defaultMinValue,
      _defaultMaxValue,
    );

    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      child: div(
        classes: ProgressVariant.indicator.classes,
        styles: {'width': '$percentage%'},
      ),
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
}
