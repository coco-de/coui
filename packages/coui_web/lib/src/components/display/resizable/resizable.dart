import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A resizable panel component.
///
/// Example:
/// ```dart
/// Resizable(
///   direction: ResizableDirection.horizontal,
///   children: [
///     div(child: text('Panel 1')),
///     div(child: text('Panel 2')),
///   ],
/// )
/// ```
class Resizable extends UiComponent {
  /// Creates a Resizable component.
  const Resizable({
    super.key,
    required this.children,
    this.direction = ResizableDirection.horizontal,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Child panels.
  final List<Component> children;

  /// Resize direction.
  final ResizableDirection direction;

  static const _divValue = 'div';

  @override
  Resizable copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    List<Component>? children,
    ResizableDirection? direction,
    Key? key,
  }) {
    return Resizable(
      key: key ?? this.key,
      children: children ?? this.children,
      direction: direction ?? this.direction,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    final isHorizontal = direction == ResizableDirection.horizontal;
    final panels = <Component>[];

    for (int i = 0; i < children.length; i += 1) {
      // Add panel
      panels.add(
        div(
          classes:
              'flex-1 ${isHorizontal ? 'resize-x' : 'resize-y'} overflow-auto border rounded p-2',
          child: children[i],
        ),
      );

      // Add separator between panels (except after last)
      if (i < children.length - 1) {
        panels.add(
          div(
            classes:
                '${isHorizontal ? 'w-1 cursor-col-resize' : 'h-1 cursor-row-resize'} bg-border hover:bg-accent transition-colors',
          ),
        );
      }
    }

    return div(
      id: id,
      classes: _buildClasses(isHorizontal),
      styles: this.css,
      attributes: this.componentAttributes,
      events: this.events,
      children: panels,
    );
  }

  @override
  String get baseClass => 'flex gap-2';

  String _buildClasses(bool isHorizontal) {
    final classList = [
      baseClass,
      if (isHorizontal) 'flex-row' else 'flex-col',
    ];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}

/// Resizable direction options.
enum ResizableDirection {
  /// Horizontal resizing.
  horizontal,

  /// Vertical resizing.
  vertical,
}
