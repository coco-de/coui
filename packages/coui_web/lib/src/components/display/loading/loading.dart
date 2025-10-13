import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A loading spinner component.
///
/// Example:
/// ```dart
/// Loading() // Default spinner
/// Loading(size: 24) // Custom size
/// ```
class Loading extends UiComponent {
  static const _defaultSpinnerSize = 16;

  /// Creates a Loading component.
  ///
  /// Parameters:
  /// - [size]: Size of the spinner in pixels
  const Loading({
    super.key,
    this.size = _defaultSpinnerSize,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Size of the spinner in pixels.
  final int size;

  static const _divValue = 'div';

  @override
  Loading copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    int? size,
    Key? key,
  }) {
    return Loading(
      key: key ?? this.key,
      size: size ?? this.size,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  String get baseClass =>
      'animate-spin rounded-full border-2 border-current border-t-transparent';

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: {
        'width': '${size}px',
        'height': '${size}px',
      },
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}
