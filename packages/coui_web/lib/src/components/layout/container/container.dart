import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A responsive container component.
///
/// Example:
/// ```dart
/// Container(
///   maxWidth: ContainerMaxWidth.lg,
///   child: text('Content'),
/// )
/// ```
class Container extends UiComponent {
  /// Creates a Container component.
  Container({
    super.key,
    Component? child,
    this.maxWidth = ContainerMaxWidth.xl,
    this.centered = true,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null, child: child);

  /// Maximum width.
  final ContainerMaxWidth maxWidth;

  /// Whether to center horizontally.
  final bool centered;

  static const _divValue = 'div';

  @override
  Container copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    ContainerMaxWidth? maxWidth,
    bool? centered,
    Key? key,
  }) {
    return Container(
      key: key ?? this.key,
      child: child ?? this.child,
      maxWidth: maxWidth ?? this.maxWidth,
      centered: centered ?? this.centered,
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
      attributes: this.componentAttributes,
      events: this.events,
      child: child,
    );
  }

  @override
  String get baseClass {
    final maxWidthClass = _getMaxWidthClass();
    final centerClass = centered ? 'mx-auto' : '';

    return 'w-full $maxWidthClass $centerClass px-4';
  }

  String _buildClasses() {
    final classList = [baseClass];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }

  String _getMaxWidthClass() {
    return switch (maxWidth) {
      ContainerMaxWidth.sm => 'max-w-screen-sm',
      ContainerMaxWidth.md => 'max-w-screen-md',
      ContainerMaxWidth.lg => 'max-w-screen-lg',
      ContainerMaxWidth.xl => 'max-w-screen-xl',
      ContainerMaxWidth.xxl => 'max-w-screen-2xl',
      ContainerMaxWidth.full => 'max-w-full',
    };
  }
}

/// Container maximum width options.
enum ContainerMaxWidth {
  /// Small (640px)
  sm,

  /// Medium (768px)
  md,

  /// Large (1024px)
  lg,

  /// Extra large (1280px)
  xl,

  /// 2X large (1536px)
  xxl,

  /// Full width
  full,
}
