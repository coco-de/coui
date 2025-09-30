import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/skeleton/skeleton_style.dart';
import 'package:jaspr/jaspr.dart';

/// Skeleton shape variants.
enum SkeletonShape {
  /// Circle skeleton shape.
  circle,

  /// Rectangle skeleton shape.
  rectangle,
}

/// A component for displaying loading placeholders with skeleton screens.
///
/// Skeletons provide visual feedback during content loading by showing
/// placeholder shapes that mimic the structure of the final content.
/// Compatible with coui_flutter API patterns.
///
/// Example:
/// ```dart
/// Skeleton(
///   width: '200px',
///   height: '20px',
/// )
/// ```
class Skeleton extends UiComponent {
  /// Creates a Skeleton component.
  ///
  /// - [width]: Width of the skeleton element.
  /// - [height]: Height of the skeleton element.
  /// - [shape]: Shape of the skeleton (circle or rectangle).
  /// - [style]: List of [SkeletonStyling] instances for styling.
  Skeleton({
    super.attributes,
    super.classes,
    super.css,
    this.height,
    super.id,
    super.key,
    this.shape,
    List<SkeletonStyling>? style,
    super.tag = _defaultTag,
    this.width,
  }) : _style = style,
       super(
         null,
         child: null,
         style: style,
       );

  /// Creates a circle skeleton.
  factory Skeleton.circle({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? height,
    String? id,
    Key? key,
    List<SkeletonStyling>? style,
    String? tag,
    String? width,
  }) {
    return Skeleton(
      attributes: attributes,
      classes: classes,
      css: css,
      height: height,
      id: id,
      key: key,
      shape: SkeletonShape.circle,
      style: style,
      tag: tag,
      width: width,
    );
  }

  /// Creates a rectangle skeleton.
  factory Skeleton.rectangle({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? height,
    String? id,
    Key? key,
    List<SkeletonStyling>? style,
    String? tag,
    String? width,
  }) {
    return Skeleton(
      attributes: attributes,
      classes: classes,
      css: css,
      height: height,
      id: id,
      key: key,
      shape: SkeletonShape.rectangle,
      style: style,
      tag: tag,
      width: width,
    );
  }

  /// Width of the skeleton element.
  final String? width;

  /// Height of the skeleton element.
  final String? height;

  /// Shape of the skeleton.
  final SkeletonShape? shape;

  /// Internal style list.
  final List<SkeletonStyling>? _style;

  static const _defaultTag = 'div';
  static const _skeletonBaseClass = 'skeleton';

  @override
  String get baseClass => _skeletonBaseClass;

  @override
  Component build(BuildContext context) {
    final styles = _buildStyles();
    final shapeClass = _getShapeClass();
    final inlineStyles = _buildInlineStyles();

    return Component.element(
      attributes: componentAttributes,
      classes:
          '$combinedClasses${styles.isNotEmpty ? ' ${styles.join(' ')}' : ''}${shapeClass.isNotEmpty ? ' $shapeClass' : ''}',
      id: id,
      styles: inlineStyles,
      tag: tag,
    );
  }

  List<String> _buildStyles() {
    final stylesList = <String>[];

    if (_style != null) {
      for (final style in _style!) {
        stylesList.add(style.cssClass);
      }
    }

    return stylesList;
  }

  String _getShapeClass() {
    if (shape == null) return '';

    switch (shape!) {
      case SkeletonShape.circle:
        return 'rounded-full';

      case SkeletonShape.rectangle:
        return '';
    }
  }

  Styles _buildInlineStyles() {
    final inlineStyles = <String, String>{};

    if (css != null) {
      inlineStyles.addAll(css!);
    }

    if (width != null) {
      inlineStyles['width'] = width!;
    }

    if (height != null) {
      inlineStyles['height'] = height!;
    }

    return inlineStyles;
  }

  @override
  Skeleton copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? height,
    String? id,
    Key? key,
    SkeletonShape? shape,
    List<SkeletonStyling>? style,
    String? tag,
    String? width,
  }) {
    return Skeleton(
      attributes: attributes ?? userProvidedAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      height: height ?? this.height,
      id: id ?? this.id,
      key: key ?? this.key,
      shape: shape ?? this.shape,
      style: style ?? _style,
      tag: tag ?? this.tag,
      width: width ?? this.width,
    );
  }
}
