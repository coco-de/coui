import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// An aspect ratio container component.
///
/// Example:
/// ```dart
/// AspectRatio(
///   ratio: 16 / 9,
///   child: img(src: 'image.jpg'),
/// )
/// ```
class AspectRatio extends UiComponent {
  /// Creates an AspectRatio component.
  const AspectRatio({
    super.key,
    required this.ratio,
    required this.child,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Aspect ratio (width / height).
  final double ratio;

  /// Child component.
  final Component child;

  static const _ratioBase = 1;

  static const _percentageMultiplier = 100;

  static const _decimalPlaces = 2;

  static const _divValue = 'div';

  @override
  String get baseClass => 'relative w-full';

  @override
  Component build(BuildContext context) {
    final paddingTop = (_ratioBase / ratio * _percentageMultiplier)
        .toStringAsFixed(_decimalPlaces);

    return div(
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: [
        // Padding trick to maintain aspect ratio
        div(
          styles: {
            'padding-top': '$paddingTop%',
          },
        ),
        // Absolute positioned content
        div(
          classes: 'absolute inset-0',
          child: child,
        ),
      ],
    );
  }

  @override
  UiComponent copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    double? ratio,
    Key? key,
  }) {
    return AspectRatio(
      key: key ?? this.key,
      ratio: ratio ?? this.ratio,
      child: child ?? this.child,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
