import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A gap component for adding spacing between flex/grid children.
///
/// This is a simple utility component that adds space using CSS gap property.
///
/// Example:
/// ```dart
/// div(
///   classes: 'flex flex-col',
///   children: [
///     text('Item 1'),
///     Gap(size: 4),
///     text('Item 2'),
///   ],
/// )
/// ```
class Gap extends UiComponent {
  /// Creates a Gap component.
  ///
  /// Parameters:
  /// - [size]: Gap size in Tailwind spacing scale (0-96, 0.5, 1.5, 2.5, 3.5)
  const Gap({
    super.key,
    this.size = 4,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Gap size in Tailwind spacing scale.
  final double size;

  static const _divValue = 'div';

  @override
  Gap copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    double? size,
    String? tag,
    Key? key,
  }) {
    return Gap(
      key: key ?? this.key,
      size: size ?? this.size,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: tag,
      id: id,
      classes: _buildClasses(),
      styles: css,
      attributes: this.componentAttributes,
      events: this.events,
    );
  }

  @override
  String get baseClass => _buildGapClass();

  String _buildGapClass() {
    // Convert size to Tailwind class
    // This is a simplified implementation
    final sizeStr = size == size.toInt()
        ? size.toInt().toString()
        : size.toString();

    return 'h-$sizeStr';
  }

  String _buildClasses() {
    final classList = [baseClass];

    if (classes != null && classes!.isNotEmpty) {
      classList.add(classes!);
    }

    return classList.join(' ');
  }
}

/// Horizontal gap component.
class HGap extends Gap {
  /// Creates a horizontal Gap component.
  const HGap({
    super.key,
    super.size = 4,
    super.attributes,
    super.classes,
    super.css,
    super.id,
  });

  @override
  String _buildGapClass() {
    final sizeStr = size == size.toInt()
        ? size.toInt().toString()
        : size.toString();

    return 'w-$sizeStr inline-block';
  }
}

/// Vertical gap component.
class VGap extends Gap {
  /// Creates a vertical Gap component.
  const VGap({
    super.key,
    super.size = 4,
    super.attributes,
    super.classes,
    super.css,
    super.id,
  });

  @override
  String _buildGapClass() {
    final sizeStr = size == size.toInt()
        ? size.toInt().toString()
        : size.toString();

    return 'h-$sizeStr';
  }
}
