import 'package:coui_web/src/base/ui_component.dart';
import 'package:jaspr/jaspr.dart';

/// A scroll area component with custom scrollbar styling.
///
/// Example:
/// ```dart
/// ScrollArea(
///   height: '400px',
///   child: div(child: text('Long content...')),
/// )
/// ```
class ScrollArea extends UiComponent {
  /// Creates a ScrollArea component.
  const ScrollArea({
    super.key,
    required this.child,
    this.height,
    this.maxHeight,
    super.attributes,
    super.classes,
    super.css,
    super.id,
    super.tag = _divValue,
  }) : super(null);

  /// Content to scroll.
  final Component child;

  /// Fixed height.
  final String? height;

  /// Maximum height.
  final String? maxHeight;

  static const _divValue = 'div';

  @override
  ScrollArea copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    String? tag,
    Component? child,
    String? height,
    String? maxHeight,
    Key? key,
  }) {
    return ScrollArea(
      key: key ?? this.key,
      child: child ?? this.child,
      height: height ?? this.height,
      maxHeight: maxHeight ?? this.maxHeight,
      attributes: attributes ?? this.componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
      tag: tag ?? this.tag,
    );
  }

  @override
  Component build(BuildContext context) {
    final styles = <String, String>{};

    final currentHeight = height;
    if (currentHeight != null) {
      styles['height'] = currentHeight;
    }
    final currentMaxHeight = maxHeight;
    if (currentMaxHeight != null) {
      styles['max-height'] = currentMaxHeight;
    }

    // Add custom scrollbar styles
    styles.addAll({
      'scrollbar-width': 'thin',
      'scrollbar-color': 'rgb(203 213 225) transparent',
    });

    final finalStyles = <String, String>{};
    final currentCss = this.css;
    if (currentCss != null) {
      finalStyles.addAll(currentCss);
    }
    finalStyles.addAll(styles);

    return div(
      id: id,
      classes: _buildClasses(),
      styles: finalStyles,
      attributes: this.componentAttributes,
      events: this.events,
      child: child,
    );
  }

  @override
  String get baseClass => 'relative overflow-auto';

  String _buildClasses() {
    final classList = [
      baseClass,
      'scrollbar-thin scrollbar-thumb-slate-300 scrollbar-track-transparent',
    ];

    final currentClasses = classes;
    if (currentClasses != null && currentClasses.isNotEmpty) {
      classList.add(currentClasses);
    }

    return classList.join(' ');
  }
}
