import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/skeleton/skeleton_style.dart';
import 'package:jaspr/jaspr.dart';

/// A skeleton placeholder component for loading states.
///
/// Follows shadcn-ui design patterns with Tailwind CSS styling.
///
/// Example:
/// ```dart
/// Skeleton(width: '100px', height: '20px')
/// ```
class Skeleton extends UiComponent {
  /// Creates a Skeleton component.
  ///
  /// Parameters:
  /// - [width]: Width of the skeleton (CSS value)
  /// - [height]: Height of the skeleton (CSS value)
  Skeleton({
    super.key,
    this.width,
    this.height,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(
         null,
         style: [
           SkeletonVariantStyle(),
         ],
       );

  /// Width of the skeleton.
  final String? width;

  /// Height of the skeleton.
  final String? height;

  static const _divValue = 'div';

  @override
  Skeleton copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    String? width,
    String? height,
    Key? key,
  }) {
    return Skeleton(
      key: key ?? this.key,
      width: width ?? this.width,
      height: height ?? this.height,
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
    final inlineStyles = <String, String>{};

    final currentWidth = width;
    if (currentWidth != null) {
      inlineStyles['width'] = currentWidth;
    }
    final currentHeight = height;
    if (currentHeight != null) {
      inlineStyles['height'] = currentHeight;
    }

    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: inlineStyles.isNotEmpty ? inlineStyles : this.css,
      attributes: this.componentAttributes,
      events: this.events,
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
}
