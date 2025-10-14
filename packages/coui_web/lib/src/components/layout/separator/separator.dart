import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A separator component (divider) following shadcn-ui patterns.
///
/// Example:
/// ```dart
/// Separator() // Horizontal
/// Separator.vertical() // Vertical
/// ```
class Separator extends UiComponent {
  /// Creates a horizontal Separator component.
  const Separator({
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : orientation = SeparatorOrientation.horizontal,
       super(null);

  /// Creates a vertical Separator component.
  const Separator.vertical({
    super.key,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : orientation = SeparatorOrientation.vertical,
       super(null);

  /// Separator orientation.
  final SeparatorOrientation orientation;

  static const _divValue = 'div';

  @override
  Separator copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Key? key,
  }) {
    return orientation == SeparatorOrientation.horizontal
        ? Separator(
            key: key ?? this.key,
            attributes: attributes ?? this.componentAttributes,
            classes: mergeClasses(classes, this.classes),
            css: css ?? this.css,
            id: id ?? this.id,
            tag: tag ?? this.tag,
          )
        : Separator.vertical(
            key: key ?? this.key,
            attributes: attributes ?? this.componentAttributes,
            classes: mergeClasses(classes, this.classes),
            css: css ?? this.css,
            id: id ?? this.id,
            tag: tag ?? this.tag,
          );
  }

  @override
  Component build(BuildContext context) {
    return div(
      id: id,
      classes: _buildClasses(),
      styles: this.css,
      attributes: {
        ...this.componentAttributes,
        'role': 'separator',
        'aria-orientation': orientation.name,
      },
      events: this.events,
    );
  }

  @override
  String get baseClass {
    const sharedClasses = 'shrink-0 bg-border';

    return orientation == SeparatorOrientation.horizontal
        ? '$sharedClasses h-[1px] w-full'
        : '$sharedClasses h-full w-[1px]';
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

/// Separator orientation options.
enum SeparatorOrientation {
  /// Horizontal separator.
  horizontal,

  /// Vertical separator.
  vertical,
}
